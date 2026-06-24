import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_plan_list_tile.dart';

class AllPlansScreen extends StatefulWidget {
  const AllPlansScreen({
    super.key,
    required this.seriesList,
    required this.onTap,
  });

  final List<Series> seriesList;
  final ValueChanged<Series> onTap;

  @override
  State<AllPlansScreen> createState() => _AllPlansScreenState();
}

class _AllPlansScreenState extends State<AllPlansScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() => _isSearching = true);
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _query = '';
    });
  }

  List<Series> get _filteredList {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.seriesList;
    return widget.seriesList
        .where((series) => series.title.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filtered = _filteredList;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        scrolledUnderElevation: 0,
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l10n.search_plans,
                    border: InputBorder.none,
                  ),
                  onChanged: (value) => setState(() => _query = value),
                )
                : Text(
                  l10n.home_shortcut_plans,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? null : l10n.search_for_plans,
            onPressed: _isSearching ? _stopSearch : _startSearch,
          ),
        ],
      ),
      body:
          filtered.isEmpty
              ? Center(
                child: Text(
                  l10n.search_no_results(_query),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final series = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PracticePlanListTile(
                      series: series,
                      onTap: () => widget.onTap(series),
                    ),
                  );
                },
              ),
    );
  }
}
