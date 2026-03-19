import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/recitation/domain/entities/recitation.dart';
import 'package:flutter_pecha/features/recitation/domain/content_type.dart';
import 'package:flutter_pecha/shared/domain/base_classes/repository.dart';

/// Recitation repository interface.
abstract class RecitationRepository extends Repository {
  /// Get all recitations.
  Future<Either<Failure, List<Recitation>>> getRecitations();

  /// Get recitations by content type.
  Future<Either<Failure, List<Recitation>>> getRecitationsByType(ContentType type);

  /// Get recitations for a specific text.
  Future<Either<Failure, List<Recitation>>> getRecitationsByText(String textId);

  /// Search recitations.
  Future<Either<Failure, List<Recitation>>> searchRecitations(String query);

  /// Get user's saved/favorite recitations.
  Future<Either<Failure, List<Recitation>>> getSavedRecitations();
}
