/// Interface for network connectivity information.
///
/// Provides a clean abstraction for checking network status
/// without depending on the concrete implementation.
abstract class NetworkInfo {
  /// Whether the device currently has internet connectivity
  bool get isOnline;

  /// Check current connectivity status
  Future<bool> checkConnectivity();

  /// Stream of connectivity changes (true = online, false = offline)
  Stream<bool> get onConnectivityChanged;
}
