import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stores the route a user attempted to access before being redirected to login.
/// Cleared on logout or after successful post-login redirect.
final pendingRouteProvider = StateProvider<String?>((ref) => null);
