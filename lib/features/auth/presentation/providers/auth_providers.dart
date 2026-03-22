import 'package:flutter_pecha/features/auth/application/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:flutter_pecha/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pecha/features/auth/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Provider for Auth Service (working implementation)
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});

/// Provider for basic HTTP client (for remote data source)
/// This breaks the circular dependency between ApiClient and AuthRepository
final basicHttpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

/// Provider for Auth Remote Data Source
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final client = ref.watch(basicHttpClientProvider);
  return AuthRemoteDatasourceImpl(client: client);
});

/// Provider for Auth Repository (wraps AuthService)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authService = ref.watch(authServiceProvider);
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);

  return AuthRepositoryImpl(
    authService: authService,
    remoteDataSource: remoteDataSource,
  );
});

/// Provider for Auth State Management
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository: authRepository, ref: ref);
});
