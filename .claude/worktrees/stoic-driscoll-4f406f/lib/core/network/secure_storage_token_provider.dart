import 'package:flutter_pecha/core/network/token_provider.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/storage/storage_service.dart';

/// TokenProvider that retrieves tokens from SecureStorage.
class SecureStorageTokenProvider implements TokenProvider {
  SecureStorageTokenProvider(this._secureStorage);

  final SecureStorage _secureStorage;

  @override
  Future<String?> getToken() => _secureStorage.get(StorageKeys.accessToken);
}
