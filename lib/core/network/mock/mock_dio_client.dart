import 'package:dio/dio.dart';

/// Mock Dio client for testing.
///
/// This client can be used in unit tests and widget tests to provide
/// fake responses to API calls without making real network requests.
class MockDioClient {
  MockDioClient();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.test.com',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  final Map<String, dynamic> _mockResponses = {};
  final Map<String, Exception> _mockErrors = {};

  /// Set a mock response for a specific path.
  void setMockResponse(String path, dynamic data) {
    _mockResponses[path] = data;
  }

  /// Set a mock error for a specific path.
  void setMockError(String path, Exception error) {
    _mockErrors[path] = error;
  }

  /// Clear all mocks.
  void clearMocks() {
    _mockResponses.clear();
    _mockErrors.clear();
  }

  /// Get the underlying Dio instance for testing.
  Dio get dio => _dio;

  /// Get a response for testing without going through the full stack.
  dynamic getMockResponse(String path) => _mockResponses[path];

  /// Get an error for testing.
  Exception? getMockError(String path) => _mockErrors[path];
}
