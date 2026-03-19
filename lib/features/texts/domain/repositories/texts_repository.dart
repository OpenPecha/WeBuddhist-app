import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/texts/domain/entities/text.dart';
import 'package:flutter_pecha/features/texts/domain/entities/section.dart';
import 'package:flutter_pecha/features/texts/domain/entities/version.dart';
import 'package:flutter_pecha/shared/domain/base_classes/repository.dart';

/// Texts repository interface.
abstract class TextsRepository extends Repository {
  /// Get all texts.
  Future<Either<Failure, List<TextEntity>>> getTexts();

  /// Get a specific text by ID.
  Future<Either<Failure, TextEntity?>> getText(String id);

  /// Get texts by collection.
  Future<Either<Failure, List<TextEntity>>> getTextsByCollection(String collectionId);

  /// Search texts by query.
  Future<Either<Failure, List<TextEntity>>> searchTexts(String query);

  /// Get table of contents for a text.
  Future<Either<Failure, List<SectionEntity>>> getTableOfContents(String textId);

  /// Get specific section content.
  Future<Either<Failure, SectionEntity>> getSection(String sectionId);

  /// Get available versions for a text.
  Future<Either<Failure, List<VersionEntity>>> getVersions(String textId);
}
