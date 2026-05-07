import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/data/services/notification_service.dart';
import 'package:flutter_pecha/features/plans/plans.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/data/models/session_selection.dart';
import 'package:flutter_pecha/features/practice/data/utils/routine_api_mapper.dart';
import 'package:flutter_pecha/features/practice/data/utils/routine_time_utils.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_api_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_provider.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/select_session_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/routine_time_block.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
final _logger = AppLogger('EditRoutineScreen');

class _EditableBlock {
  String id;
  String? apiTimeBlockId;
  TimeOfDay time;
  bool notificationEnabled;
  List<RoutineItem> items;

  _EditableBlock({
    String? id,
    this.apiTimeBlockId,
    required this.time,
    required this.notificationEnabled,
    List<RoutineItem>? items,
  }) : id = id ?? _uuid.v4(),
       items = items ?? [];
}

class EditRoutineScreen extends ConsumerStatefulWidget {
  final Plan? initialPlan;

  const EditRoutineScreen({super.key, this.initialPlan});

  @override
  ConsumerState<EditRoutineScreen> createState() => _EditRoutineScreenState();
}

class _EditRoutineScreenState extends ConsumerState<EditRoutineScreen> {
  late List<_EditableBlock> _blocks;

  /// Server routine id once loaded or after first create.
  String? _apiRoutineId;

  bool _hydratedFromApi = false;

  /// Sequential queue so API calls never overlap or race.
  Future<void> _opQueue = Future.value();

  bool get _isLastBlockEmpty =>
      _blocks.isNotEmpty && _blocks.last.items.isEmpty;

  bool get _hasEmptyBlocks => _blocks.any((b) => b.items.isEmpty);

  @override
  void initState() {
    super.initState();
    _blocks = [
      _EditableBlock(
        time: const TimeOfDay(hour: 12, minute: 0),
        notificationEnabled: true,
      ),
    ];
  }

  // ─── Hydration ───

  void _applyInitialData(RoutineData? routineData) {
    _apiRoutineId = routineData?.apiRoutineId;

    if (routineData != null && routineData.blocks.isNotEmpty) {
      _blocks =
          routineData.blocks
              .map(
                (b) => _EditableBlock(
                  id: b.id,
                  apiTimeBlockId: b.apiTimeBlockId,
                  time: b.time,
                  notificationEnabled: b.notificationEnabled,
                  items: List.from(b.items),
                ),
              )
              .toList();
    } else {
      _blocks = [
        _EditableBlock(
          time: const TimeOfDay(hour: 12, minute: 0),
          notificationEnabled: true,
        ),
      ];
    }
  }

  void _injectInitialPlan(Plan plan) {
    final alreadyExists = _blocks.any(
      (b) => b.items.any(
        (item) => item.id == plan.id && item.type == RoutineItemType.plan,
      ),
    );
    if (alreadyExists) return;

    final newItem = RoutineItem(
      id: plan.id,
      title: plan.title,
      imageUrl: plan.coverImageUrl,
      type: RoutineItemType.plan,
      enrolledAt: DateTime.now(),
    );

    // If we have exactly one empty default block, add the plan there
    if (_blocks.length == 1 && _blocks.first.items.isEmpty) {
      _blocks.first.items.add(newItem);
      return;
    }

    // Otherwise create a new time block at the user's current local time
    final otherTimes = _blocks.map((b) => b.time).toList();
    final adjusted = adjustTimeForMinimumGap(TimeOfDay.now(), otherTimes);
    if (adjusted == null) {
      // Fallback: add to the first block if no time slot available
      _blocks.first.items.add(newItem);
      return;
    }

    _blocks.add(
      _EditableBlock(
        time: adjusted,
        notificationEnabled: true,
        items: [newItem],
      ),
    );
    _sortBlocks();
  }

  /// Syncs the block that contains [plan] after deep-link injection.
  void _syncInjectedPlan(Plan plan) {
    for (final block in _blocks) {
      if (block.items.any(
        (i) => i.id == plan.id && i.type == RoutineItemType.plan,
      )) {
        _syncBlock(block).catchError((e) {
          if (mounted) _showErrorSnackBar(_mapError(e));
        });
        break;
      }
    }
  }

  RoutineBlock _toRoutineBlock(_EditableBlock b) {
    return RoutineBlock(
      id: b.id,
      time: b.time,
      notificationEnabled: b.notificationEnabled,
      apiTimeBlockId: b.apiTimeBlockId,
      items: b.items,
    );
  }

  /// Saves blocks to local Hive storage AND syncs notifications.
  /// Routing through RoutineNotifier keeps Hive in sync so startup
  /// reschedule works, and ensures [ROUTINE-SAVE] logs are visible.
  Future<void> _saveLocalAndSyncNotifications() async {
    final blocks = _blocks.map(_toRoutineBlock).toList();
    _logger.info('[EDIT-SAVE] persisting ${blocks.length} blocks to Hive + scheduling notifications');
    await ref.read(routineProvider.notifier).saveRoutine(blocks);
    _logger.info('[EDIT-SAVE] done');
  }

  // ─── Operation queue ───

  /// Enqueues [fn] so API calls run sequentially.
  /// Errors propagate to callers but never break the chain for subsequent ops.
  Future<void> _enqueue(Future<void> Function() fn) async {
    final prev = _opQueue;
    final completer = Completer<void>();
    _opQueue = completer.future;

    try {
      await prev;
    } catch (_) {}

    try {
      await fn();
    } finally {
      // Always release the queue slot, whether fn() succeeded or threw.
      completer.complete();
    }
  }

  // ─── Server sync ───

  /// Syncs a single block's current local state to the server.
  ///
  /// Empty block with a server ID → DELETE (block becomes local-only).
  /// Block with items but no server ID → CREATE (routine or time block).
  /// Block with items and a server ID → UPDATE (full replacement).
  Future<void> _syncBlock(_EditableBlock block) => _enqueue(() async {
    if (block.items.isEmpty) {
      if (block.apiTimeBlockId != null && _apiRoutineId != null) {
        final result = await ref.read(deleteTimeBlockUseCaseProvider)(
          _apiRoutineId!,
          block.apiTimeBlockId!,
        );
        result.fold((f) => throw f, (_) {
          if (mounted) setState(() => block.apiTimeBlockId = null);
        });
      }
      return;
    }

    final request = routineBlockToRequest(_toRoutineBlock(block));

    if (_apiRoutineId == null) {
      // First block ever: creates the routine + block together.
      final result = await ref.read(createRoutineWithTimeBlockUseCaseProvider)(
        request,
      );
      result.fold((f) => throw f, (created) {
        if (mounted) {
          setState(() {
            _apiRoutineId = created.routineId;
            block.apiTimeBlockId = created.timeBlockId;
            block.id = created.timeBlockId;
          });
        }
      });
    } else if (block.apiTimeBlockId == null) {
      // Routine exists but this block is new.
      final result = await ref.read(createTimeBlockUseCaseProvider)(
        _apiRoutineId!,
        request,
      );
      result.fold((f) => throw f, (timeBlockId) {
        if (mounted) {
          setState(() {
            block.apiTimeBlockId = timeBlockId;
            block.id = timeBlockId;
          });
        }
      });
    } else {
      // Both exist — full replacement update.
      final result = await ref.read(updateTimeBlockUseCaseProvider)(
        _apiRoutineId!,
        block.apiTimeBlockId!,
        request,
      );
      result.fold((f) => throw f, (_) {});
    }
  });

  /// Deletes a persisted time block from the server.
  Future<void> _deletePersistedBlock(String apiTimeBlockId) =>
      _enqueue(() async {
        if (_apiRoutineId == null) return;
        final result = await ref.read(deleteTimeBlockUseCaseProvider)(
          _apiRoutineId!,
          apiTimeBlockId,
        );
        result.fold((f) => throw f, (_) {});
      });

  // ─── Error handling ───

  String _mapError(Object e) {
    if (e is Failure) return e.message;
    if (e is Exception) return e.toString().replaceFirst('Exception: ', '');
    return 'Something went wrong. Please try again.';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ─── Save flow ───

  Future<void> _saveAndPop() async {
    // Wait for any in-flight API operations to finish.
    try {
      await _opQueue;
    } catch (_) {}

    if (_hasEmptyBlocks) {
      final shouldDelete = await _showEmptyBlockDialog();
      if (!mounted) return;

      if (shouldDelete == true) {
        setState(() => _blocks.removeWhere((b) => b.items.isEmpty));
      } else {
        return;
      }
    }

    try {
      await _saveLocalAndSyncNotifications();
    } catch (e, st) {
      _logger.error('[EDIT-SAVE] Failed to save/sync notifications', e, st);
      if (mounted) _showErrorSnackBar(_mapError(e));
    }

    ref.invalidate(userRoutineProvider);
    await ref.read(myPlansPaginatedProvider.notifier).refresh();
    if (mounted) context.pop();
  }

  // ─── Dialogs ───

  Future<bool?> _showEmptyBlockDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emptyCount = _blocks.where((b) => b.items.isEmpty).length;
    final hasMultipleEmpty = emptyCount > 1;
    final l10n = context.l10n;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            hasMultipleEmpty
                ? l10n.routine_empty_block_title_plural(emptyCount)
                : l10n.routine_empty_block_title_singular,
          ),
          content: Text(
            hasMultipleEmpty
                ? l10n.routine_empty_block_message_plural(emptyCount)
                : l10n.routine_empty_block_message_singular,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                l10n.routine_empty_block_add_items,
                style: TextStyle(
                  color:
                      isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              child: Text(
                hasMultipleEmpty
                    ? l10n.routine_empty_block_delete_plural
                    : l10n.routine_empty_block_delete_singular,
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Block operations ───

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _blocks[index].time,
    );
    if (picked != null) {
      final otherTimes =
          _blocks
              .asMap()
              .entries
              .where((e) => e.key != index)
              .map((e) => e.value.time)
              .toList();
      final adjusted = adjustTimeForMinimumGap(picked, otherTimes);

      if (adjusted == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.noTimeSlot),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final block = _blocks[index];
      final previousTime = block.time;

      setState(() {
        block.time = adjusted;
        _sortBlocks();
      });

      if (adjusted != picked && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.routine_time_adjusted(
                formatRoutineTime(adjusted),
                kMinBlockGapMinutes,
              ),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      if (block.apiTimeBlockId != null) {
        try {
          await _syncBlock(block);
        } catch (e) {
          if (mounted) {
            setState(() {
              block.time = previousTime;
              _sortBlocks();
            });
            _showErrorSnackBar(_mapError(e));
          }
        }
      }
    }
  }

  void _sortBlocks() {
    _blocks.sort(
      (a, b) => timeToMinutes(a.time).compareTo(timeToMinutes(b.time)),
    );
  }

  Future<void> _toggleNotification(int index) async {
    final block = _blocks[index];

    if (block.notificationEnabled) {
      final previousValue = block.notificationEnabled;
      setState(() => block.notificationEnabled = false);

      if (block.apiTimeBlockId != null) {
        try {
          await _syncBlock(block);
        } catch (e) {
          if (mounted) {
            setState(() => block.notificationEnabled = previousValue);
            _showErrorSnackBar(_mapError(e));
          }
        }
      }
      return;
    }

    final enabled = await NotificationService().areNotificationsEnabled();
    if (!enabled && mounted) {
      final granted = await _showNotificationPermissionModal();
      if (granted != true) return;
    }

    if (mounted) {
      setState(() => block.notificationEnabled = true);

      if (block.apiTimeBlockId != null) {
        try {
          await _syncBlock(block);
        } catch (e) {
          if (mounted) {
            setState(() => block.notificationEnabled = false);
            _showErrorSnackBar(_mapError(e));
          }
        }
      }
    }
  }

  Future<bool?> _showNotificationPermissionModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    return showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: 48,
                  color:
                      isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.routine_notification_title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.routine_notification_description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final nav = Navigator.of(context);
                      final granted =
                          await NotificationService().requestPermission();
                      if (!granted) await openAppSettings();
                      final nowEnabled =
                          await NotificationService().areNotificationsEnabled();
                      nav.pop(nowEnabled);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                      foregroundColor:
                          isDark
                              ? AppColors.textPrimary
                              : AppColors.textPrimaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.routine_notification_enable,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      l10n.routine_notification_skip,
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteBlock(int index) async {
    final block = _blocks[index];
    final apiId = block.apiTimeBlockId;

    final routineBlock = _toRoutineBlock(block);
    await ref
        .read(routineNotificationServiceProvider)
        .cancelBlockNotification(routineBlock);

    setState(() => _blocks.removeAt(index));

    if (apiId != null) {
      try {
        await _deletePersistedBlock(apiId);
      } catch (e) {
        if (mounted) {
          setState(() {
            _blocks.add(block);
            _sortBlocks();
          });
          _showErrorSnackBar(_mapError(e));
        }
      }
    }
  }

  bool get _isAtMaxBlocks => !canAddBlock(_blocks.length);
  bool get _shouldShowAddButton => !_isLastBlockEmpty && !_isAtMaxBlocks;

  int _calculateListItemCount() {
    return _shouldShowAddButton ? _blocks.length + 1 : _blocks.length;
  }

  void _addBlock() {
    if (_isAtMaxBlocks) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.maxBlocks(kMaxBlocks)),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final otherTimes = _blocks.map((b) => b.time).toList();
    final adjusted = adjustTimeForMinimumGap(
      const TimeOfDay(hour: 12, minute: 0),
      otherTimes,
    );

    if (adjusted == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.noTimeSlot),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _blocks.add(_EditableBlock(time: adjusted, notificationEnabled: false));
      _sortBlocks();
    });
    // No API call — block is local-only until the first session is added.
  }

  void _onReorderItems(int blockIndex, int oldIndex, int newIndex) {
    final block = _blocks[blockIndex];
    final previousOrder = List<RoutineItem>.from(block.items);

    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = block.items.removeAt(oldIndex);
      block.items.insert(newIndex, item);
    });

    if (block.apiTimeBlockId != null) {
      _syncBlock(block).catchError((e) {
        if (mounted) {
          setState(() {
            block.items
              ..clear()
              ..addAll(previousOrder);
          });
          _showErrorSnackBar(_mapError(e));
        }
      });
    }
  }

  void _onDeleteItem(int blockIndex, int itemIndex) {
    final block = _blocks[blockIndex];
    final removedItem = block.items[itemIndex];
    final wasNotEmpty = block.items.isNotEmpty;

    setState(() => block.items.removeAt(itemIndex));

    if (wasNotEmpty && block.items.isEmpty) {
      final routineBlock = RoutineBlock(
        id: block.id,
        time: block.time,
        notificationEnabled: block.notificationEnabled,
        apiTimeBlockId: block.apiTimeBlockId,
        items: const [],
      );
      ref
          .read(routineNotificationServiceProvider)
          .cancelBlockNotification(routineBlock);
    }

    if (block.apiTimeBlockId != null) {
      _syncBlock(block)
          .then((_) {
            // After a successful server DELETE (block.items empty), remove the
            // now-orphaned local block so it does not linger as an empty row.
            if (mounted && block.items.isEmpty) {
              setState(() => _blocks.remove(block));
            }
          })
          .catchError((e) {
            if (mounted) {
              setState(() => block.items.insert(itemIndex, removedItem));
              _showErrorSnackBar(_mapError(e));
            }
          });
    } else if (block.items.isEmpty) {
      // No server state to sync — drop the empty local block immediately.
      setState(() => _blocks.remove(block));
    }
  }

  ({Set<String> planIds, Set<String> recitationIds}) _collectRoutineItemIds() {
    final planIds = <String>{};
    final recitationIds = <String>{};
    for (final block in _blocks) {
      for (final item in block.items) {
        if (item.type == RoutineItemType.plan) planIds.add(item.id);
      }
    }
    return (planIds: planIds, recitationIds: recitationIds);
  }

  bool _isSelectingSession = false;

  Future<void> _navigateToSelectSession(int blockIndex) async {
    if (_isSelectingSession) return;
    _isSelectingSession = true;

    try {
      final excluded = _collectRoutineItemIds();
      final result = await Navigator.of(context).push<SessionSelection>(
        MaterialPageRoute(
          builder:
              (_) => SelectSessionScreen(excludedPlanIds: excluded.planIds),
        ),
      );

      if (result != null && mounted) {
        final (newItemId, newItemType) = switch (result) {
          PlanSessionSelection(:final plan) => (plan.id, RoutineItemType.plan),
          RecitationSessionSelection(:final recitation) => (
            recitation.textId,
            RoutineItemType.recitation,
          ),
        };

        final isDuplicate = _blocks[blockIndex].items.any(
          (item) => item.id == newItemId && item.type == newItemType,
        );

        if (isDuplicate) {
          _logger.warning('Duplicate item prevented: $newItemId');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.duplicateItem),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return;
        }

        final RoutineItem newItem;
        switch (result) {
          case PlanSessionSelection(:final plan):
            newItem = RoutineItem(
              id: plan.id,
              title: plan.title,
              imageUrl: plan.coverImageUrl,
              type: RoutineItemType.plan,
              enrolledAt: DateTime.now(),
            );
          case RecitationSessionSelection(:final recitation):
            newItem = RoutineItem(
              id: recitation.textId,
              title: recitation.title,
              type: RoutineItemType.recitation,
            );
        }

        final block = _blocks[blockIndex];
        setState(() => block.items.add(newItem));

        try {
          await _syncBlock(block);
        } catch (e) {
          if (mounted) {
            setState(() => block.items.remove(newItem));
            _showErrorSnackBar(_mapError(e));
          }
        }
      }
    } finally {
      _isSelectingSession = false;
    }
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show loading/error until the API data is hydrated into local editable
    // state. Watching the provider is limited to this guarded branch so that
    // external invalidations (e.g. ref.invalidate in _saveAndPop) never
    // rebuild the screen mid-editing once hydration is done.
    if (!_hydratedFromApi) {
      final routineAsync = ref.watch(userRoutineProvider);
      return routineAsync.when(
        loading: () => _buildLoadingScaffold(localizations),
        error: (e, _) => _buildErrorScaffold(e, localizations),
        data: (routineData) {
          // Data is ready — schedule hydration for the next frame.
          // addPostFrameCallback is used here because calling setState during
          // build is illegal. The _hydratedFromApi guard prevents multiple
          // callbacks from racing if the provider rebuilds before the frame
          // fires (e.g., a quick re-watch before hydration completes).
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _hydratedFromApi) return;
            setState(() {
              _hydratedFromApi = true;
              _applyInitialData(routineData);
              if (widget.initialPlan != null) {
                _injectInitialPlan(widget.initialPlan!);
              }
            });
            if (widget.initialPlan != null) {
              _syncInjectedPlan(widget.initialPlan!);
            }
          });
          return _buildLoadingScaffold(localizations);
        },
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _DoneButton(
                  onTap: _saveAndPop,
                  isDark: isDark,
                  label: localizations.done,
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.routine_edit_title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    itemCount: _calculateListItemCount(),
                    separatorBuilder: (_, index) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1),
                      );
                    },
                    itemBuilder: (context, index) {
                      if (_shouldShowAddButton && index == _blocks.length) {
                        return _AddBlockButton(
                          onTap: _addBlock,
                          isDark: isDark,
                        );
                      }
                      final block = _blocks[index];
                      return RoutineTimeBlock(
                        time: block.time,
                        notificationEnabled: block.notificationEnabled,
                        items: block.items,
                        onTimeChanged: () => _pickTime(index),
                        onNotificationToggle: () => _toggleNotification(index),
                        onDelete: () => _deleteBlock(index),
                        onAddSession: () => _navigateToSelectSession(index),
                        onReorderItems:
                            (oldIdx, newIdx) =>
                                _onReorderItems(index, oldIdx, newIdx),
                        onDeleteItem:
                            (itemIdx) => _onDeleteItem(index, itemIdx),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScaffold(AppLocalizations localizations) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  localizations.routine_edit_title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScaffold(Object e, AppLocalizations localizations) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$e', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(userRoutineProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Private widgets ───

class _DoneButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;
  final String label;

  const _DoneButton({
    required this.onTap,
    required this.isDark,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _AddBlockButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _AddBlockButton({required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add,
                size: 16,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                context.l10n.routine_add_block_label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
