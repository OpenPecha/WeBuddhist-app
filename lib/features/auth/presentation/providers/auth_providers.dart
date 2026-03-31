import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:flutter_pecha/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pecha/features/auth/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for Auth Service (working implementation)
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});

/// Provider for Auth Remote Data Source
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRemoteDatasourceImpl(dio: dio);
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
