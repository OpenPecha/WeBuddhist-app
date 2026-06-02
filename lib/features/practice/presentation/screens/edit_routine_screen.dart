import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/storage/plan_metadata_store.dart';
import 'package:flutter_pecha/core/storage/special_plan_started_at_store.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/data/services/notification_service.dart';
import 'package:flutter_pecha/features/notifications/data/special_plan_notifications.dart';
import 'package:flutter_pecha/features/notifications/presentation/providers/notification_provider.dart';
import 'package:flutter_pecha/features/notifications/presentation/widgets/notification_permission_sheet.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_enrollment_provider.dart';
import 'package:flutter_pecha/features/plans/domain/usecases/user_plans_usecases.dart';
import 'package:flutter_pecha/features/plans/plans.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/use_case_providers.dart'
    show getUserPlansUseCaseProvider;
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/data/models/session_selection.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
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

  /// When provided, after hydration the screen fetches all currently-active
  /// plans from the given series and injects them into the routine, reusing
  /// any existing empty block or creating a new one at the user's current
  /// local time (with the standard 10-minute gap). Backend filters out future
  /// plans by start date.
  final String? enrollSeriesId;

  const EditRoutineScreen({
    super.key,
    this.initialPlan,
    this.enrollSeriesId,
  });

  @override
  ConsumerState<EditRoutineScreen> createState() => _EditRoutineScreenState();
}

class _EditRoutineScreenState extends ConsumerState<EditRoutineScreen> {
  late List<_EditableBlock> _blocks;

  /// Server routine id once loaded or after first create.
  String? _apiRoutineId;

  bool _hydratedFromApi = false;

  /// Guard so series-enrollment prefill runs exactly once after hydration.
  bool _seriesEnrollmentHydrated = false;

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
        time: TimeOfDay.now(),
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
          time: TimeOfDay.now(),
          notificationEnabled: true,
        ),
      ];
    }
  }

  /// Resolves where to place auto-injected items (plan deep-link or series
  /// enrollment prefill). Prefers the earliest existing empty block, re-timed
  /// to the user's current local time (with the standard 10-minute gap from
  /// other blocks). Falls back to a brand-new block at the current local
  /// time, and finally to `_blocks.first` if no valid slot is available.
  ///
  /// Mutates `block.time` and reorders `_blocks` (via `_sortBlocks`), so the
  /// caller must wrap this in `setState` when called outside the build phase.
  ({_EditableBlock target, bool isNewBlock}) _resolveInjectionTarget() {
    _sortBlocks();

    for (final block in _blocks) {
      if (block.items.isEmpty) {
        final otherTimes = _blocks
            .where((b) => !identical(b, block))
            .map((b) => b.time)
            .toList();
        final adjusted = adjustTimeForMinimumGap(TimeOfDay.now(), otherTimes);
        if (adjusted != null) {
          block.time = adjusted;
        }
        return (target: block, isNewBlock: false);
      }
    }

    final allTimes = _blocks.map((b) => b.time).toList();
    final adjusted = adjustTimeForMinimumGap(TimeOfDay.now(), allTimes);
    if (adjusted == null) {
      return (target: _blocks.first, isNewBlock: false);
    }
    final newBlock = _EditableBlock(
      time: adjusted,
      notificationEnabled: true,
    );
    return (target: newBlock, isNewBlock: true);
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

    final resolved = _resolveInjectionTarget();
    resolved.target.items.add(newItem);
    if (resolved.isNewBlock) {
      _blocks.add(resolved.target);
    }
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

  /// Fetches all currently active plans for the just-enrolled series and
  /// injects them into the routine. Plans whose start date is in the future
  /// are excluded by the backend (`GET /users/me/plans?series_id=`), so the
  /// client just trusts the result. Plans already in the routine are skipped.
  Future<void> _hydrateSeriesEnrollment(String seriesId) async {
    final locale = ref.read(localeProvider);
    final useCase = ref.read(getUserPlansUseCaseProvider);
    final result = await useCase(
      GetUserPlansParams(
        language: locale.languageCode,
        seriesId: seriesId,
      ),
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        _logger.warning(
          '[SERIES-ENROLL-PREFILL] failed to fetch series plans: '
          '${failure.message}',
        );
        _showErrorSnackBar(failure.message);
      },
      (response) {
        if (response.userPlans.isEmpty) {
          _logger.info(
            '[SERIES-ENROLL-PREFILL] no active plans returned for series '
            '$seriesId',
          );
          return;
        }
        final injectedBlock = _injectSeriesUserPlans(response.userPlans);
        if (injectedBlock != null) {
          _syncBlock(injectedBlock).catchError((e) {
            if (mounted) _showErrorSnackBar(_mapError(e));
          });
        }
      },
    );
  }

  /// Adds [plans] into the routine, reusing the earliest empty block (re-timed
  /// to the user's current local time) or creating a new block at that time
  /// with the standard 10-minute gap. Plans that already exist in any block
  /// (by id + plan type) are skipped.
  ///
  /// Returns the affected block (to drive a follow-up server sync) or null
  /// if every plan was already present.
  _EditableBlock? _injectSeriesUserPlans(List<UserPlansModel> plans) {
    final existingPlanIds = <String>{};
    for (final b in _blocks) {
      for (final item in b.items) {
        if (item.type == RoutineItemType.plan) {
          existingPlanIds.add(item.id);
        }
      }
    }

    final newItems = <RoutineItem>[];
    for (final p in plans) {
      if (existingPlanIds.contains(p.id)) continue;
      newItems.add(
        RoutineItem(
          id: p.id,
          title: p.title,
          imageUrl: p.imageUrl,
          type: RoutineItemType.plan,
          enrolledAt: DateTime.now(),
        ),
      );
      existingPlanIds.add(p.id);
    }

    if (newItems.isEmpty) return null;

    late _EditableBlock target;
    setState(() {
      final resolved = _resolveInjectionTarget();
      target = resolved.target;
      if (resolved.isNewBlock) {
        _blocks.add(target);
      }
      target.items.addAll(newItems);
      _sortBlocks();
    });

    return target;
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
    return AppLocalizations.of(context)!.something_went_wrong;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ─── Save flow ───

  /// Optimistic save: persists local state synchronously, then pops and
  /// defers slow work (notification reschedule, paginated plans refetch,
  /// in-flight API drain) to the background.
  ///
  /// Why: the previous serial flow could block the user for 3–4s because
  /// (1) `_opQueue` waited for every in-flight `_syncBlock` to finish,
  /// (2) notification sync issues 60+ platform-channel calls per plan
  /// block, and (3) `myPlansPaginatedProvider.refresh()` is a network
  /// round-trip. None of those need to complete before the user leaves
  /// the screen — Hive is the source of truth for the next render, and
  /// the startup bootstrap re-syncs notifications on the next launch if
  /// the background work fails.
  Future<void> _saveAndPop() async {
    // 1. Empty-block confirmation must run synchronously — it depends on
    //    the user's input and changes what we persist below.
    if (_hasEmptyBlocks) {
      final shouldDelete = await _showEmptyBlockDialog();
      if (!mounted) return;
      if (shouldDelete == true) {
        setState(() => _blocks.removeWhere((b) => b.items.isEmpty));
      } else {
        return;
      }
    }

    // 2. Capture Riverpod handles BEFORE pop. `ref` becomes invalid once
    //    this State is disposed, but the captured notifier instances are
    //    kept alive by the ProviderScope (these providers are not
    //    autoDispose), so the background block below can use them safely.
    final routineNotifier = ref.read(routineProvider.notifier);
    final myPlansNotifier = ref.read(myPlansPaginatedProvider.notifier);
    final pendingOps = _opQueue;
    final blocks = _blocks.map(_toRoutineBlock).toList();

    // 3. Await ONLY the Hive write. It is fast (~ms) and the next screen
    //    reads from Hive-backed state, so this must complete before pop.
    //    A failure here is fatal: we surface it and stay on the screen.
    _logger.info('[EDIT-SAVE] persisting ${blocks.length} blocks');
    try {
      await routineNotifier.saveRoutineLocalOnly(blocks);
    } catch (e, st) {
      _logger.error('[EDIT-SAVE] local save failed', e, st);
      if (mounted) _showErrorSnackBar(_mapError(e));
      return;
    }

    // 4. Invalidate while context is alive. These are cheap; the actual
    //    refetch happens lazily when the next screen reads the provider.
    ref.invalidate(userRoutineProvider);
    ref.invalidate(userPlansFutureProvider);

    // After saving the first block ever, prompt for notification permission if
    // not already granted. We await the sheet so context remains valid for pop.
    if (blocks.length == 1 && mounted) {
      final hasPermission = await NotificationService().areNotificationsEnabled();
      if (!hasPermission && mounted) {
        final allow = await NotificationPermissionSheet.show(context);
        if (allow && mounted) {
          await ref
              .read(notificationProvider.notifier)
              .requestEnableNotifications();
        }
      }
    }

    if (mounted) {
      _logger.info('[EDIT-SAVE] popping (background tasks continuing)');
      context.pop();
    }

    // 5. Fire-and-forget the slow work. Errors are non-fatal:
    //    - API queue: each op's user-visible error was already surfaced
    //      inline when the user added the item.
    //    - Notification sync: startup bootstrap re-syncs on next launch.
    //    - Plans refresh: the list refetches when next viewed.
    //    We intentionally do NOT touch `setState`, `ref`, or `context`
    //    below — this closure outlives the widget.
    unawaited(() async {
      try {
        await pendingOps;
      } catch (e) {
        _logger.warning('[EDIT-SAVE-BG] op queue drained with error: $e');
      }
      try {
        await routineNotifier.syncNotifications(blocks);
      } catch (e) {
        _logger.warning('[EDIT-SAVE-BG] notification sync failed: $e');
      }
      try {
        await myPlansNotifier.refresh();
      } catch (e) {
        _logger.warning('[EDIT-SAVE-BG] plans refresh failed: $e');
      }
    }());
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

    // Clean up metadata for all plan items in this block
    for (final item in block.items) {
      if (item.type == RoutineItemType.plan) {
        if (isSpecialPlan(item.id)) {
          await SpecialPlanStartedAtStore.clear(item.id);
        } else {
          await PlanMetadataStore.clear(item.id);
        }
      }
    }

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
    final adjusted = adjustTimeForMinimumGap(TimeOfDay.now(), otherTimes);

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

  Future<void> _onDeleteItem(int blockIndex, int itemIndex) async {
    final block = _blocks[blockIndex];
    final removedItem = block.items[itemIndex];
    final wasNotEmpty = block.items.isNotEmpty;

    setState(() => block.items.removeAt(itemIndex));

    // Await cleanup so re-enrollment never races with stale metadata or
    // stale "already shown" flags.
    if (removedItem.type == RoutineItemType.plan) {
      if (isSpecialPlan(removedItem.id)) {
        await SpecialPlanStartedAtStore.clear(removedItem.id);
      } else {
        await PlanMetadataStore.clear(removedItem.id);
      }
    }

    if (wasNotEmpty && block.items.isEmpty) {
      final routineBlock = RoutineBlock(
        id: block.id,
        time: block.time,
        notificationEnabled: block.notificationEnabled,
        apiTimeBlockId: block.apiTimeBlockId,
        items: const [],
      );
      await ref
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

  bool _isSelectingSession = false;

  Future<void> _navigateToSelectSession(int blockIndex) async {
    if (_isSelectingSession) return;
    _isSelectingSession = true;

    try {
      final result = await Navigator.of(context).push<SessionSelection>(
        MaterialPageRoute(builder: (_) => const SelectSessionScreen()),
      );

      if (result == null || !mounted) return;

      switch (result) {
        case PlanSessionSelection(:final plan):
          await _addPlanToBlock(blockIndex, plan);
        case RecitationSessionSelection(:final recitation):
          await _addRecitationToBlock(blockIndex, recitation);
        case SeriesSessionSelection(:final series):
          await _handleSeriesEnrollmentFromSelection(blockIndex, series);
      }
    } finally {
      _isSelectingSession = false;
    }
  }

  Future<void> _addPlanToBlock(int blockIndex, Plan plan) async {
    final isDuplicate = _blocks[blockIndex].items.any(
      (item) => item.id == plan.id && item.type == RoutineItemType.plan,
    );
    if (isDuplicate) {
      _logger.warning('Duplicate item prevented: ${plan.id}');
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

    final newItem = RoutineItem(
      id: plan.id,
      title: plan.title,
      imageUrl: plan.coverImageUrl,
      type: RoutineItemType.plan,
      enrolledAt: DateTime.now(),
    );
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

  Future<void> _addRecitationToBlock(
    int blockIndex,
    RecitationModel recitation,
  ) async {
    final isDuplicate = _blocks[blockIndex].items.any(
      (item) =>
          item.id == recitation.textId &&
          item.type == RoutineItemType.recitation,
    );
    if (isDuplicate) {
      _logger.warning('Duplicate item prevented: ${recitation.textId}');
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

    final newItem = RoutineItem(
      id: recitation.textId,
      title: recitation.title,
      type: RoutineItemType.recitation,
    );
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

  /// Enrolls the user in [series] (if not already enrolled) and injects the
  /// series' currently-active plans (started, not future — the backend excludes
  /// future plans by start date) into the tapped [blockIndex].
  ///
  /// Per-timeblock rule: if that block already contains every active plan of
  /// the series, nothing is added and the user sees a duplicate notice. The
  /// same series can still be added to other blocks that are missing plans.
  ///
  /// Auth guard: guests get the login drawer instead of an enroll attempt.
  /// Re-enrollment guard: if the user is already enrolled, skip the POST and
  /// go straight to injecting plans. `_isSelectingSession` already serializes
  /// taps at the caller, so no extra in-flight flag is needed here.
  Future<void> _handleSeriesEnrollmentFromSelection(
    int blockIndex,
    Series series,
  ) async {
    final auth = ref.read(authProvider);
    if (auth.isGuest) {
      if (mounted) LoginDrawer.show(context, ref);
      return;
    }

    final seriesId = series.id;
    final alreadyEnrolled = ref
            .read(userSeriesEnrollmentsProvider)
            .valueOrNull
            ?.contains(seriesId) ??
        false;

    if (!alreadyEnrolled) {
      final notifier = ref.read(seriesEnrollmentProvider(seriesId).notifier);
      final ok = await notifier.enroll();
      if (!mounted) return;

      if (!ok) {
        final state = ref.read(seriesEnrollmentProvider(seriesId));
        final message = state is SeriesEnrollmentFailure
            ? state.failure.message
            : 'Failed to enroll in series';
        _showErrorSnackBar(message);
        return;
      }
    }

    // Fetch the series' active plans (backend excludes future plans by start
    // date) and inject the ones missing from the tapped block.
    final locale = ref.read(localeProvider);
    final result = await ref.read(getUserPlansUseCaseProvider)(
      GetUserPlansParams(language: locale.languageCode, seriesId: seriesId),
    );
    if (!mounted) return;

    result.fold(
      (failure) => _showErrorSnackBar(failure.message),
      (response) => _injectSeriesPlansIntoBlock(blockIndex, response.userPlans),
    );
  }

  /// Adds the series' active [plans] that are missing from the block at
  /// [blockIndex]. If the block already holds all of them, shows a duplicate
  /// notice and adds nothing (the series can still be added to other blocks).
  Future<void> _injectSeriesPlansIntoBlock(
    int blockIndex,
    List<UserPlansModel> plans,
  ) async {
    if (plans.isEmpty) return;
    if (blockIndex < 0 || blockIndex >= _blocks.length) return;
    final block = _blocks[blockIndex];

    final existingPlanIds = block.items
        .where((i) => i.type == RoutineItemType.plan)
        .map((i) => i.id)
        .toSet();

    final newItems = <RoutineItem>[];
    for (final p in plans) {
      if (existingPlanIds.contains(p.id)) continue;
      newItems.add(
        RoutineItem(
          id: p.id,
          title: p.title,
          imageUrl: p.imageUrl,
          type: RoutineItemType.plan,
          enrolledAt: DateTime.now(),
        ),
      );
    }

    if (newItems.isEmpty) {
      // Block already holds every active plan of the series → block re-add to
      // THIS block. Mirrors the per-block duplicate guard used for plans.
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

    setState(() => block.items.addAll(newItems));

    try {
      await _syncBlock(block);
    } catch (e) {
      if (mounted) {
        setState(() => block.items.removeWhere(newItems.contains));
        _showErrorSnackBar(_mapError(e));
      }
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
            if (widget.enrollSeriesId != null &&
                !_seriesEnrollmentHydrated) {
              _seriesEnrollmentHydrated = true;
              _hydrateSeriesEnrollment(widget.enrollSeriesId!);
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
                    child: Text(localizations.retry),
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
