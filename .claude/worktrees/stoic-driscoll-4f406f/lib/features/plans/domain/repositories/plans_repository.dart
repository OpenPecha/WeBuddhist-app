import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/plans/domain/entities/author.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan_day.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan_progress.dart';
import 'package:flutter_pecha/shared/domain/base_classes/repository.dart';

/// Plans repository interface.
abstract class PlansRepository extends Repository {
  /// Get all available plans with pagination and filtering support.
  Future<Either<Failure, List<Plan>>> getPlans({
    required String language,
    String? search,
    String? tag,
    int? skip,
    int? limit,
  });

  /// Get a specific plan by ID.
  Future<Either<Failure, Plan?>> getPlan(String id);

  /// Get plans filtered by tags.
  Future<Either<Failure, List<Plan>>> getPlansByTags(List<String> tags);

  /// Search plans by query string.
  Future<Either<Failure, List<Plan>>> searchPlans(String query);

  /// Get plans for a specific author.
  Future<Either<Failure, List<Plan>>> getPlansByAuthor(String authorId);

  /// Get author information.
  Future<Either<Failure, Author?>> getAuthor(String authorId);

  /// Get user's plan progress.
  Future<Either<Failure, PlanProgress?>> getUserPlanProgress(String planId);

  /// Enroll user in a plan.
  Future<Either<Failure, PlanProgress>> enrollInPlan(String planId);

  /// Update plan progress (mark task/day complete).
  Future<Either<Failure, PlanProgress>> updateProgress(
    String planId,
    int dayNumber,
    String? taskId,
  );

  /// Unenroll from a plan.
  Future<Either<Failure, void>> unenrollFromPlan(String planId);

  /// Get a specific day's content.
  Future<Either<Failure, PlanDay?>> getPlanDay(String planId, int dayNumber);
}
