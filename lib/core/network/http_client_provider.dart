// lib/core/network/http_client_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_pecha/features/auth/application/auth_provider.dart';
import 'authenticated_http_client.dart';

// Singleton HTTP client provider
final httpClientProvider = Provider<http.Client>((ref) {
  final authState = ref.watch(authProvider);

  // For unauthenticated users, return simple HTTP client
  if (!authState.isLoggedIn || authState.isGuest) {
    return http.Client();
  }

  // For authenticated users, return singleton authenticated client
  final authService = ref.read(authProvider.notifier).authService;
  return AuthenticatedHttpClient(http.Client(), authService.auth0);
});

// Alternative: Separate providers for different use cases
final publicHttpClientProvider = Provider<http.Client>((ref) => http.Client());

final authenticatedHttpClientProvider = Provider<http.Client>((ref) {
  final authService = ref.read(authProvider.notifier).authService;
  return AuthenticatedHttpClient(http.Client(), authService.auth0);
});
