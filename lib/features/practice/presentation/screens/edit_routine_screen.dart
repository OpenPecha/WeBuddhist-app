import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/services/notification_service.dart';
import 'package:flutter_pecha/features/plans/data/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/data/models/session_selection.dart';
import 'package:flutter_pecha/features/practice/data/providers/routine_provider.dart';
import 'package:flutter_pecha/features/practice/data/utils/routine_time_utils.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/select_session_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/routine_time_block.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
final _logger = AppLogger('EditRoutineScreen');

class _EditableBlock {
  final String id;
  TimeOfDay time;
  bool notificationEnabled;
  List<RoutineItem> items;

  _EditableBlock({
    String? id,
    required this.time,
    required this.notificationEnabled,
    List<RoutineItem>? items,
  }) : id = id ?? _uuid.v4(),
       items = items ?? [];
}

class EditRoutineScreen extends ConsumerStatefulWidget {
  const EditRoutineScreen({super.key});

  @override
  ConsumerState<EditRoutineScreen> createState() => _EditRoutineScreenState();
}

class _EditRoutineScreenState extends ConsumerState<EditRoutineScreen> {
  late List<_EditableBlock> _blocks;

  /// Check if the last block in the list is empty (has no items)
  bool get _isLastBlockEmpty =>
      _blocks.isNotEmpty && _blocks.last.items.isEmpty;

  /// Check if there are any empty blocks
  bool get _hasEmptyBlocks => _blocks.any((b) => b.items.isEmpty);

  @override
  void initState() {
    super.initState();
    final existingData = ref.read(routineProvider);
    if (existingData.hasItems) {
      _blocks =
          existingData.blocks
              .map(
                (b) => _EditableBlock(
                  id: b.id,
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

  Future<void> _saveAndPop() async {
    // If there are empty blocks, show validation dialog
    if (_hasEmptyBlocks) {
      final shouldDelete = await _showEmptyBlockDialog();
      if (!mounted) return;

      if (shouldDelete == true) {
        // Remove empty blocks from state
        setState(() {
          _blocks.removeWhere((b) => b.items.isEmpty);
        });

        // If all blocks were empty, save empty list and pop
        if (_blocks.isEmpty) {
          await ref.read(routineProvider.notifier).saveRoutine([]);
          if (mounted) Navigator.of(context).pop();
          return;
        }
      } else {
        // User chose to add items, don't save yet
        return;
      }
    }

    // Save non-empty blocks
    final blocks =
        _blocks
            .map(
              (b) => RoutineBlock(
                id: b.id,
                time: b.time,
                notificationEnabled: b.notificationEnabled,
                items: b.items,
              ),
            )
            .toList();

    await ref.read(routineProvider.notifier).saveRoutine(blocks);
    if (mounted) Navigator.of(context).pop();
  }

  Future<bool?> _showEmptyBlockDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emptyCount = _blocks.where((b) => b.items.isEmpty).length;
    final hasMultipleEmpty = emptyCount > 1;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            hasMultipleEmpty ? 'Empty Time Blocks' : 'Empty Time Block',
          ),
          content: Text(
            hasMultipleEmpty
                ? 'You have $emptyCount time blocks without any items. Would you like to add items or delete these blocks?'
                : 'This time block has no items. Would you like to add an item or delete the block?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Add Items',
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
                hasMultipleEmpty ? 'Delete Empty Blocks' : 'Delete Block',
              ),
            ),
          ],
        );
      },
    );
  }

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
      setState(() {
        _blocks[index].time = adjusted;
        _sortBlocks();
      });
      if (adjusted != picked && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Adjusted to ${_formatTime(adjusted)} ($kMinBlockGapMinutes-min minimum gap)',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _sortBlocks() {
    _blocks.sort(
      (a, b) => (a.time.hour * 60 + a.time.minute).compareTo(
        b.time.hour * 60 + b.time.minute,
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _toggleNotification(int index) async {
    // If currently enabled, just disable — no permission check needed
    if (_blocks[index].notificationEnabled) {
      setState(() {
        _blocks[index].notificationEnabled = false;
      });
      return;
    }

    // Enabling: check notification permission first
    final enabled = await NotificationService().areNotificationsEnabled();
    if (!enabled && mounted) {
      final granted = await _showNotificationPermissionModal();
      if (granted != true) return;
    }

    if (mounted) {
      setState(() {
        _blocks[index].notificationEnabled = true;
      });
    }
  }

  Future<bool?> _showNotificationPermissionModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  'Make Prayer Daily',
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
                  'Allow notifications to receive your reminder to pray.',
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
                      if (!granted) {
                        await openAppSettings();
                      }
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
                    child: const Text(
                      'Enable Notifications',
                      style: TextStyle(
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
                      'Skip',
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

  void _deleteBlock(int index) {
    // Confirmation dialog is already handled in RoutineTimeBlock._confirmDeleteBlock
    final items = List<RoutineItem>.from(_blocks[index].items);
    setState(() => _blocks.removeAt(index));
    // Unenroll/unsave all items in the deleted block
    for (final item in items) {
      _unenrollItem(item);
    }
  }

  void _addBlock() {
    final otherTimes = _blocks.map((b) => b.time).toList();
    final defaultTime = const TimeOfDay(hour: 12, minute: 0);
    final adjusted = adjustTimeForMinimumGap(defaultTime, otherTimes);
    setState(() {
      _blocks.add(_EditableBlock(time: adjusted, notificationEnabled: false));
      _sortBlocks();
    });
  }

  void _onReorderItems(int blockIndex, int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _blocks[blockIndex].items.removeAt(oldIndex);
      _blocks[blockIndex].items.insert(newIndex, item);
    });
  }

  void _onDeleteItem(int blockIndex, int itemIndex) {
    final item = _blocks[blockIndex].items[itemIndex];
    setState(() {
      _blocks[blockIndex].items.removeAt(itemIndex);
    });
    // Unenroll/unsave immediately in background
    _unenrollItem(item);
  }

  /// Collects all item IDs currently in the routine to prevent duplicates.
  ({Set<String> planIds, Set<String> recitationIds}) _collectRoutineItemIds() {
    final planIds = <String>{};
    final recitationIds = <String>{};
    for (final block in _blocks) {
      for (final item in block.items) {
        if (item.type == RoutineItemType.plan) {
          planIds.add(item.id);
        } else {
          recitationIds.add(item.id);
        }
      }
    }
    return (planIds: planIds, recitationIds: recitationIds);
  }

  Future<void> _navigateToSelectSession(int blockIndex) async {
    final excluded = _collectRoutineItemIds();
    final result = await Navigator.of(context).push<SessionSelection>(
      MaterialPageRoute(
        builder: (_) => SelectSessionScreen(
          excludedPlanIds: excluded.planIds,
          excludedRecitationIds: excluded.recitationIds,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        switch (result) {
          case PlanSessionSelection(:final plan):
            _blocks[blockIndex].items.add(
              RoutineItem(
                id: plan.id,
                title: plan.title,
                imageUrl: plan.imageThumbnail,
                type: RoutineItemType.plan,
              ),
            );
          case RecitationSessionSelection(:final recitation):
            _blocks[blockIndex].items.add(
              RoutineItem(
                id: recitation.textId,
                title: recitation.title,
                type: RoutineItemType.recitation,
              ),
            );
        }
      });
    }
  }

  /// Unenrolls a plan or unsaves a recitation in the background.
  /// Shows error snackbar if the API call fails.
  Future<void> _unenrollItem(RoutineItem item) async {
    try {
      if (item.type == RoutineItemType.plan) {
        await ref.read(userPlanUnsubscribeFutureProvider(item.id).future);
        ref.invalidate(userPlansFutureProvider);
        ref.invalidate(myPlansPaginatedProvider);
      } else {
        await ref.read(unsaveRecitationProvider(item.id).future);
        ref.invalidate(savedRecitationsFutureProvider);
      }
    } catch (e) {
      _logger.error('Failed to unenroll/unsave item: ${item.title}', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to unenroll "${item.title}". Please try again.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    itemCount:
                        _isLastBlockEmpty
                            ? _blocks.length
                            : _blocks.length + 1, // +1 for add block button
                    separatorBuilder: (_, index) {
                      final isLastItem =
                          _isLastBlockEmpty
                              ? index == _blocks.length - 1
                              : index == _blocks.length - 1;
                      if (isLastItem) {
                        return const SizedBox(height: 16);
                      }
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1),
                      );
                    },
                    itemBuilder: (context, index) {
                      // Show add block button only if last block is not empty
                      if (!_isLastBlockEmpty && index == _blocks.length) {
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
}

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
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                'Time Block',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
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
