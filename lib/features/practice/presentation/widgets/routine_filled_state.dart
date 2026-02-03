import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/plans/data/providers/plans_providers.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/routine_item_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RoutineFilledState extends StatelessWidget {
  final RoutineData routineData;
  final VoidCallback onEdit;

  const RoutineFilledState({
    super.key,
    required this.routineData,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('EEE, MMM yyyy').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Header with Edit button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: _RoutineHeader(
            title: localizations.routine_title,
            editLabel: localizations.routine_edit,
            onEdit: onEdit,
            isDark: isDark,
          ),
        ),
        // Date
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            dateStr,
            style: TextStyle(
              fontSize: 15,
              color:
                  isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Divider(height: 1),
        ),
        // Routine blocks
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
            itemCount: routineData.blocks.length,
            itemBuilder: (context, index) {
              return _RoutineBlockSection(block: routineData.blocks[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _RoutineHeader extends StatelessWidget {
  final String title;
  final String editLabel;
  final VoidCallback onEdit;
  final bool isDark;

  const _RoutineHeader({
    required this.title,
    required this.editLabel,
    required this.onEdit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
        GestureDetector(
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              editLabel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoutineBlockSection extends ConsumerWidget {
  final RoutineBlock block;

  const _RoutineBlockSection({required this.block});

  Future<void> _onItemTap(
    BuildContext context,
    WidgetRef ref,
    RoutineItem item,
  ) async {
    if (item.type == RoutineItemType.recitation) {
      // Navigate to ChaptersScreen for recitation text
      context.push('/practice/texts/${item.id}');
    } else if (item.type == RoutineItemType.plan) {
      // Fetch plan data and navigate to PlanInfo for preview
      final planAsync = await ref.read(planByIdFutureProvider(item.id).future);
      if (context.mounted) {
        context.push('/practice/plans/info', extra: {'plan': planAsync});
        // Navigator.of(
        //   context,
        // ).push(MaterialPageRoute(builder: (_) => PlanInfo(plan: planAsync)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          block.formattedTime,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < block.items.length; i++) ...[
          RoutineItemCard(
            title: block.items[i].title,
            imageUrl: block.items[i].imageUrl,
            onTap: () => _onItemTap(context, ref, block.items[i]),
          ),
          if (i < block.items.length - 1) const Divider(height: 1, indent: 80),
        ],
        if (block.items.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Divider(height: 1),
          ),
      ],
    );
  }
}
