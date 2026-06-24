import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_chant_list_tile.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';

class AllRecitationsScreen extends StatelessWidget {
  const AllRecitationsScreen({
    super.key,
    required this.recitations,
    required this.onTap,
  });

  final List<RecitationModel> recitations;
  final ValueChanged<RecitationModel> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.home_chants,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: recitations.length,
        itemBuilder: (context, index) {
          final r = recitations[index];
          return PracticeChantListTile(
            recitation: r,
            onTap: () => onTap(r),
          );
        },
      ),
    );
  }
}
