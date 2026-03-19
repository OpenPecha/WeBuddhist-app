import 'package:equatable/equatable.dart';

/// Daily quote/verse entity.
class DailyQuote extends Equatable {
  final String id;
  final String content;
  final String? source;
  final String? author;
  final DateTime date;

  const DailyQuote({
    required this.id,
    required this.content,
    this.source,
    this.author,
    required this.date,
  });

  @override
  List<Object?> get props => [id, content, source, author, date];
}
