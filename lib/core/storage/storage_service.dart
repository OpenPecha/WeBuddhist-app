/// Abstract storage service for persistent key-value storage.
///
/// This interface provides a generic way to store and retrieve
/// simple values using SharedPreferences or similar mechanisms.
abstract class StorageService {
  /// Get a value from storage
  Future<T?> get<T>(String key);

  /// Set a value in storage
  Future<bool> set<T>(String key, T value);

  /// Remove a value from storage
  Future<bool> delete(String key);

  /// Clear all values from storage
  Future<bool> clear();

  /// Check if a key exists in storage
  Future<bool> containsKey(String key);
}

/// Abstract secure storage service for sensitive data.
///
/// This interface provides a secure way to store and retrieve
/// sensitive values like tokens using FlutterSecureStorage.
abstract class SecureStorage {
  /// Get a value from secure storage
  Future<String?> get(String key);

  /// Set a value in secure storage
  Future<void> set(String key, String value);

  /// Remove a value from secure storage
  Future<void> delete(String key);

  /// Clear all values from secure storage
  Future<void> clear();

  /// Check if a key exists in secure storage
  Future<bool> containsKey(String key);

  /// Get all keys from secure storage
  Future<Map<String, String>> getAll();
}
