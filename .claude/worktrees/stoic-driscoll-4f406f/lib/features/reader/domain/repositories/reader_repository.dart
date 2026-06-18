import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/reader/domain/entities/text_content.dart';
import 'package:flutter_pecha/shared/domain/base_classes/repository.dart';

/// Reader repository interface.
///
/// Defines the contract for text content operations.
abstract class ReaderRepository extends Repository {
  /// Load initial text content by ID.
  Future<Either<Failure, TextContent>> loadInitialText(String textId);

  /// Load next page of verses for a text.
  Future<Either<Failure, List<Verse>>> loadNextPage(String textId, int pageIndex);

  /// Navigate to a specific section.
  Future<Either<Failure, Section>> navigateToSection(String sectionId);

  /// Search for text within content.
  Future<Either<Failure, List<Verse>>> searchContent(String textId, String query);

  /// Get text metadata without full content.
  Future<Either<Failure, TextContent>> getTextMetadata(String textId);
}
