import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/recitations_search_screen.dart';
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

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RecitationsSearchScreen(onTap: onTap)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.home_chants,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.recitations_search_for,
            onPressed: () => _openSearch(context),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: recitations.length,
        itemBuilder: (context, index) {
          final recitation = recitations[index];
          return PracticeChantListTile(
            recitation: recitation,
            onTap: () => onTap(recitation),
          );
        },
      ),
    );
  }
}
