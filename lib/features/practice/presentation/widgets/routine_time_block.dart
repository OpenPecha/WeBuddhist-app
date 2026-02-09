import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/routine_item_card.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class RoutineTimeBlock extends StatelessWidget {
  final TimeOfDay time;
  final bool notificationEnabled;
  final List<RoutineItem> items;
  final VoidCallback onTimeChanged;
  final VoidCallback onNotificationToggle;
  final Future<void> Function() onDelete;
  final VoidCallback onAddSession;
  final void Function(int oldIndex, int newIndex) onReorderItems;
  final void Function(int itemIndex) onDeleteItem;

  const RoutineTimeBlock({
    super.key,
    required this.time,
    required this.notificationEnabled,
    required this.items,
    required this.onTimeChanged,
    required this.onNotificationToggle,
    required this.onDelete,
    required this.onAddSession,
    required this.onReorderItems,
    required this.onDeleteItem,
  });

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _confirmDeleteItem(BuildContext context, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Item'),
            content: Text('Remove "${items[index].title}" from this block?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Remove',
                  style: TextStyle(color: Colors.red.shade400),
                ),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      onDeleteItem(index);
    }
  }

  Future<void> _confirmDeleteBlock(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations.routine_delete_block),
            content: const Text(
              'This will remove the time block and all its items.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.red.shade400),
                ),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      await onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Time selector row
        Row(
          children: [
            _TimeSelector(
              time: time,
              onTap: onTimeChanged,
              isDark: isDark,
              formattedTime: _formatTime(time),
            ),
            const SizedBox(width: 8),
            _NotificationIcon(
              enabled: notificationEnabled,
              onTap: onNotificationToggle,
              isDark: isDark,
            ),
            const Spacer(),
            _DeleteBlockButton(
              onTap: () => _confirmDeleteBlock(context),
              label: localizations.routine_delete_block,
            ),
          ],
        ),
        // Items list (above action buttons)
        if (items.isNotEmpty) ...[
          const SizedBox(height: 12),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: items.length,
            onReorder: onReorderItems,
            proxyDecorator: (child, index, animation) {
              return Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(10),
                child: child,
              );
            },
            itemBuilder: (context, i) {
              final item = items[i];
              return Column(
                key: ValueKey(item.id),
                mainAxisSize: MainAxisSize.min,
                children: [
                  RoutineItemCard(
                    title: item.title,
                    imageUrl: item.imageUrl,
                    onDelete: () => _confirmDeleteItem(context, i),
                    reorderIndex: i,
                  ),
                  if (i < items.length - 1)
                    const Divider(height: 1, indent: 100),
                ],
              );
            },
          ),
        ],
        // Add Session button (below items)
        const SizedBox(height: 16),
        _AddSessionButton(
          label: localizations.routine_add_session,
          onTap: onAddSession,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _TimeSelector extends StatelessWidget {
  final TimeOfDay time;
  final VoidCallback onTap;
  final bool isDark;
  final String formattedTime;

  const _TimeSelector({
    required this.time,
    required this.onTap,
    required this.isDark,
    required this.formattedTime,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
            Text(
              formattedTime,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              PhosphorIconsRegular.caretDown,
              size: 16,
              color:
                  isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  final bool isDark;

  const _NotificationIcon({
    required this.enabled,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        enabled ? PhosphorIconsRegular.bell : PhosphorIconsRegular.bellSlash,
        size: 22,
      ),
    );
  }
}

class _DeleteBlockButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const _DeleteBlockButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(fontSize: 14, color: Colors.red.shade400),
      ),
    );
  }
}

/// Add Session button matching the design - square icon placeholder with + icon,
/// "Add Session" text, whole area clickable.
class _AddSessionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _AddSessionButton({
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8, left: 32),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  PhosphorIconsRegular.plus,
                  size: 24,
                  color:
                      isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
