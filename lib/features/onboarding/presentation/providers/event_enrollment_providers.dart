import 'package:flutter_pecha/features/onboarding/application/event_enrollment_service.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/use_case_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_api_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [EventEnrollmentService] wired up with all required use cases.
final eventEnrollmentServiceProvider = Provider<EventEnrollmentService>((ref) {
  return EventEnrollmentService(
    subscribeToPlanUseCase: ref.read(subscribeToPlanUseCaseProvider),
    getUserRoutineUseCase: ref.read(getUserRoutineUseCaseProvider),
    createRoutineWithTimeBlockUseCase: ref.read(createRoutineWithTimeBlockUseCaseProvider),
    createTimeBlockUseCase: ref.read(createTimeBlockUseCaseProvider),
    getUserPlansUseCase: ref.read(getUserPlansUseCaseProvider),
    ref: ref,
  );
});
