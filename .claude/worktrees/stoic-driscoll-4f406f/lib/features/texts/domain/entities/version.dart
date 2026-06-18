import 'package:equatable/equatable.dart';

/// Version entity - a translation/version of a text.
class VersionEntity extends Equatable {
  final String id;
  final String name;
  final String language;
  final String? translatorName;
  final int year;

  const VersionEntity({
    required this.id,
    required this.name,
    required this.language,
    this.translatorName,
    this.year = 0,
  });

  @override
  List<Object?> get props => [id, name, language, translatorName, year];
}
