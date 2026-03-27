import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:flutter_pecha/features/auth/domain/entities/auth_credentials.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pecha/features/auth/auth_service.dart';

/// Auth repository implementation (Data Layer)
///
/// Wraps the working AuthService to provide repository interface.
/// This maintains all existing functionality while providing clean abstraction.
/// Converts between Auth0 Credentials and domain AuthCredentials.
class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl({
    required AuthService authService,
    required AuthRemoteDataSource remoteDataSource,
  })  : _authService = authService,
        _remoteDataSource = remoteDataSource;

  /// Convert Auth0 Credentials to domain AuthCredentials
  AuthCredentials _toAuthCredentials(Credentials credentials) {
    final now = DateTime.now();
    final expiresAt = credentials.expiresAt;
    final expiresIn = expiresAt.difference(now).inSeconds;

    return AuthCredentials(
      accessToken: credentials.accessToken,
      idToken: credentials.idToken,
      tokenType: credentials.tokenType,
      expiresIn: expiresIn > 0 ? expiresIn : 3600,
      obtainedAt: now,
      refreshToken: credentials.refreshToken,
      scope: null, // Not exposed by Auth0 Credentials
    );
  }

  // ========== Initialization ==========

  @override
  Future<Either<Failure, void>> initialize() async {
    try {
      await _authService.initialize();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure('Failed to initialize auth: $e'));
    }
  }

  // ========== Authentication Operations ==========

  @override
  Future<Either<Failure, AuthCredentials>> loginWithGoogle() async {
    try {
      final credentials = await _authService.loginWithGoogle();
      if (credentials == null) {
        return const Left(AuthenticationFailure('Google login failed'));
      }
      return Right(_toAuthCredentials(credentials));
    } catch (e) {
      return Left(AuthenticationFailure('Google login failed: $e'));
    }
  }

  @override
  Future<Either<Failure, AuthCredentials>> loginWithApple() async {
    try {
      final credentials = await _authService.loginWithApple();
      if (credentials == null) {
        return const Left(AuthenticationFailure('Apple login failed'));
      }
      return Right(_toAuthCredentials(credentials));
    } catch (e) {
      return Left(AuthenticationFailure('Apple login failed: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> localLogout() async {
    try {
      await _authService.localLogout();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure('Logout failed: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> hasValidCredentials() async {
    try {
      final hasCredentials = await _authService.hasValidCredentials();
      return Right(hasCredentials);
    } catch (e) {
      return Left(UnknownFailure('Failed to check credentials: $e'));
    }
  }

  @override
  Future<Either<Failure, AuthCredentials>> getCredentials() async {
    try {
      final credentials = await _authService.getCredentials();
      if (credentials == null) {
        return const Left(AuthenticationFailure('No credentials found'));
      }
      return Right(_toAuthCredentials(credentials));
    } catch (e) {
      return Left(AuthenticationFailure('Failed to get credentials: $e'));
    }
  }

  @override
  bool isIdTokenExpired(String idToken) {
    return _authService.isIdTokenExpired(idToken);
  }

  @override
  Future<Either<Failure, String>> getValidIdToken() async {
    try {
      final idToken = await _authService.getValidIdToken();
      if (idToken == null) {
        return const Left(AuthenticationFailure('No valid ID token'));
      }
      return Right(idToken);
    } catch (e) {
      return Left(AuthenticationFailure('Failed to get valid ID token: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> refreshIdToken() async {
    try {
      final idToken = await _authService.refreshIdToken();
      if (idToken == null) {
        return const Left(AuthenticationFailure('Failed to refresh ID token'));
      }
      return Right(idToken);
    } catch (e) {
      return Left(AuthenticationFailure('Failed to refresh ID token: $e'));
    }
  }

  // ========== Guest Mode Operations ==========

  @override
  Future<Either<Failure, void>> continueAsGuest() async {
    try {
      await _authService.continueAsGuest();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure('Failed to continue as guest: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> isGuestMode() async {
    try {
      final isGuest = await _authService.isGuestMode();
      return Right(isGuest);
    } catch (e) {
      return Left(UnknownFailure('Failed to check guest mode: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearGuestMode() async {
    try {
      await _authService.clearGuestMode();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure('Failed to clear guest mode: $e'));
    }
  }

  // ========== User Data Operations ==========

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    // Get valid ID token for the API request
    final idTokenResult = await getValidIdToken();
    if (idTokenResult.isLeft()) {
      return idTokenResult.fold((failure) => Left(failure), (_) => const Left(UnknownFailure('Unknown error')));
    }

    final idToken = idTokenResult.getOrElse((_) => '');

    try {
      final userModel = await _remoteDataSource.getCurrentUser(idToken);
      return Right(userModel.toEntity());
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on AuthorizationException catch (e) {
      return Left(AuthorizationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to get current user: $e'));
    }
  }
}
