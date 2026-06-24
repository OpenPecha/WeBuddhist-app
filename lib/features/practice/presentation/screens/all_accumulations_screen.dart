import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_accumulation_item.dart';

class AllAccumulationsScreen extends StatelessWidget {
  const AllAccumulationsScreen({
    super.key,
    required this.mantras,
    required this.language,
    required this.onTap,
  });

  final List<Mantra> mantras;
  final String language;
  final ValueChanged<Mantra> onTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.accumulations,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 8,
          childAspectRatio: 0.72,
        ),
        itemCount: mantras.length,
        itemBuilder: (context, index) {
          final mantra = mantras[index];
          return PracticeAccumulationItem(
            mantra: mantra,
            language: language,
            onTap: () => onTap(mantra),
          );
        },
      ),
    );
  }
}
