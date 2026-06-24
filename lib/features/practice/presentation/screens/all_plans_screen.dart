import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_plan_card.dart';

class AllPlansScreen extends StatelessWidget {
  const AllPlansScreen({
    super.key,
    required this.seriesList,
    required this.onTap,
  });

  final List<Series> seriesList;
  final ValueChanged<Series> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.home_shortcut_plans,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: seriesList.length,
        itemBuilder: (context, index) {
          final series = seriesList[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PracticePlanCard(
              series: series,
              width: double.infinity,
              onTap: () => onTap(series),
            ),
          );
        },
      ),
    );
  }
}
