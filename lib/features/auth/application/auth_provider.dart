// Riverpod provider and logic for authentication state.
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final bool isLoggedIn;
  final String? userId;
  const AuthState({required this.isLoggedIn, this.userId});

  AuthState copyWith({bool? isLoggedIn, String? userId}) => AuthState(
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    userId: userId ?? this.userId,
  );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isLoggedIn: false));

  void login({String? userId}) {
    state = AuthState(isLoggedIn: true, userId: userId);
  }

  void logout() {
    state = const AuthState(isLoggedIn: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
