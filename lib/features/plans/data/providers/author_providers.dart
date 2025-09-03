import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../repositories/author_repository.dart';
import '../datasource/author_remote_datasource.dart';
import '../../models/author_model.dart';

// Repository provider
final authorRepositoryProvider = Provider<AuthorRepository>((ref) {
  return AuthorRepository(
    authorRemoteDatasource: AuthorRemoteDatasource(client: http.Client()),
  );
});

// Get author by ID provider
final authorByIdFutureProvider = FutureProvider.family<AuthorModel, String>((
  ref,
  id,
) {
  return ref.watch(authorRepositoryProvider).getAuthorById(id);
});

// Create author provider
final createAuthorProvider = FutureProvider.family<AuthorModel, AuthorModel>((
  ref,
  author,
) {
  return ref.watch(authorRepositoryProvider).createAuthor(author);
});

// Update author provider
final updateAuthorProvider =
    FutureProvider.family<AuthorModel, MapEntry<String, AuthorModel>>((
      ref,
      entry,
    ) {
      final id = entry.key;
      final author = entry.value;
      return ref.watch(authorRepositoryProvider).updateAuthor(id, author);
    });

// Delete author provider
final deleteAuthorProvider = FutureProvider.family<void, String>((ref, id) {
  return ref.watch(authorRepositoryProvider).deleteAuthor(id);
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
  final AuthorRepository _repository;

  AuthorNotifier(this._repository) : super(const AuthorState());

  Future<void> addAuthor(AuthorModel author) async {
    try {
      final newAuthor = await _repository.createAuthor(author);
      state = state.copyWith(authors: [...state.authors, newAuthor]);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> updateAuthor(String id, AuthorModel author) async {
    try {
      final updatedAuthor = await _repository.updateAuthor(id, author);
      final updatedAuthors =
          state.authors.map((a) {
            return a.id == id ? updatedAuthor : a;
          }).toList();

      state = state.copyWith(authors: updatedAuthors);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> removeAuthor(String id) async {
    try {
      await _repository.deleteAuthor(id);
      final updatedAuthors = state.authors.where((a) => a.id != id).toList();
      state = state.copyWith(authors: updatedAuthors);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authorNotifierProvider =
    StateNotifierProvider<AuthorNotifier, AuthorState>((ref) {
      final repository = ref.watch(authorRepositoryProvider);
      return AuthorNotifier(repository);
    });
