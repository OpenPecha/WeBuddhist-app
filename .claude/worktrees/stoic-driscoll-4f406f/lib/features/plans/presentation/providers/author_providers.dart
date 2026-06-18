import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/features/plans/domain/usecases/plans_usecases.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/author_repository.dart';
import '../../data/datasource/author_remote_datasource.dart';
import '../../data/models/author/author_model.dart';

// Repository provider
final authorRepositoryProvider = Provider<AuthorRepository>((ref) {
  return AuthorRepository(
    authorRemoteDatasource: AuthorRemoteDatasource(
      dio: ref.watch(dioProvider),
    ),
  );
});

// Get author by ID provider
final authorByIdFutureProvider = FutureProvider.family<Either<Failure, AuthorModel>, String>((
  ref,
  id,
) {
  return ref.watch(authorRepositoryProvider).getAuthorById(id);
});

// Get plans by author ID provider (using use case)
final authorPlansFutureProvider =
    FutureProvider.family<Either<Failure, List<Plan>>, String>((ref, authorId) async {
      final getPlansUseCase = ref.watch(getPlansUseCaseProvider);

      final result = await getPlansUseCase(const GetPlansParams(
        language: 'en',
        limit: 100,
      ));

      return result.fold(
        (failure) => Left(failure),
        (plans) => Right(plans.where((plan) => plan.authorId == authorId).toList()),
      );
    });

// Author state notifier for managing local state
class AuthorState {
  final List<AuthorModel> authors;
  final bool isLoading;
  final String? errorMessage;

  const AuthorState({
    this.authors = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  AuthorState copyWith({
    List<AuthorModel>? authors,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthorState(
      authors: authors ?? this.authors,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthorNotifier extends StateNotifier<AuthorState> {
  final AuthorRepository repository;
  AuthorNotifier(this.repository) : super(const AuthorState());

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authorNotifierProvider =
    StateNotifierProvider<AuthorNotifier, AuthorState>((ref) {
      final repository = ref.watch(authorRepositoryProvider);
      return AuthorNotifier(repository);
    });
