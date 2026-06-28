import 'package:equatable/equatable.dart';

class MantraCount extends Equatable {
  final String mantraId;
  final String mantraTitle;
  final String? malaImageUrl;
  final int totalCount;

  const MantraCount({
    required this.mantraId,
    required this.mantraTitle,
    this.malaImageUrl,
    required this.totalCount,
  });

  @override
  List<Object?> get props => [mantraId, mantraTitle, malaImageUrl, totalCount];
}

class MantraCountPage extends Equatable {
  final List<MantraCount> counts;

  const MantraCountPage({required this.counts});

  static const empty = MantraCountPage(counts: []);

  @override
  List<Object?> get props => [counts];
}
