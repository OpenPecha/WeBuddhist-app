import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/routine_action_button.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/routine_item_card.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class RoutineTimeBlock extends StatelessWidget {
  final TimeOfDay time;
  final bool notificationEnabled;
  final List<RoutineItem> items;
  final VoidCallback onTimeChanged;
  final VoidCallback onNotificationToggle;
  final VoidCallback onDelete;
  final VoidCallback onAddPlan;
  final VoidCallback onAddRecitation;
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
    required this.onAddPlan,
    required this.onAddRecitation,
    required this.onReorderItems,
    required this.onDeleteItem,
  });

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
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
              onTap: onDelete,
              label: localizations.routine_delete_block,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: RoutineActionButton(
                icon: PhosphorIconsRegular.plus,
                label: localizations.routine_add_plan,
                onTap: onAddPlan,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RoutineActionButton(
                icon: PhosphorIconsRegular.plus,
                label: localizations.routine_add_recitation,
                onTap: onAddRecitation,
              ),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 12),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
              return Dismissible(
                key: ValueKey(item.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => onDeleteItem(i),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    PhosphorIconsRegular.trash,
                    color: Colors.white,
                  ),
                ),
                child: RoutineItemCard(
                  title: item.title,
                  imageUrl: item.imageUrl,
                ),
              );
            },
          ),
        ],
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
        enabled ? PhosphorIconsRegular.bellSlash : PhosphorIconsRegular.bell,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? AppColors.textSubtleDark : AppColors.grey500,
        ),
      ),
    );
  }
}
