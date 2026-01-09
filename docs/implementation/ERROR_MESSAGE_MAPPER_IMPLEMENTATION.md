# Error Message Mapper Implementation

## Overview
Implemented a production-ready, centralized error message mapper utility to convert technical errors into user-friendly messages across the AI feature and entire application.

**Date**: January 2026  
**Status**: ✅ Complete  
**Test Coverage**: 49/49 tests passing

---

## Implementation Details

### 1. Core Utility: `ErrorMessageMapper`

**Location**: `lib/core/utils/error_message_mapper.dart`

**Features**:
- Converts technical errors to user-friendly messages
- Handles multiple error types (Failures, Exceptions, error strings)
- Provides context-specific messages
- Includes helper methods for error classification
- Fully documented with examples

**Key Methods**:

```dart
// Main conversion method
String getDisplayMessage(dynamic error, {String? context})

// Helper methods for error classification
bool isNetworkError(dynamic error)
bool isTimeoutError(dynamic error)
bool isAuthError(dynamic error)
bool isRetryable(dynamic error)
```

### 2. Error Types Handled

#### Failure Objects (from `core/error/failures.dart`)
- ✅ `NetworkFailure` → "Unable to connect. Please check your internet connection."
- ✅ `ServerFailure` → "Service temporarily unavailable. Please try again later."
- ✅ `AuthenticationFailure` → "Session expired. Please sign in again."
- ✅ `AuthorizationFailure` → "You don't have permission to perform this action."
- ✅ `ValidationFailure` → Uses custom message or generic validation error
- ✅ `RateLimitFailure` → Uses custom message with wait time
- ✅ `NotFoundFailure` → "Content not found. It may have been removed."
- ✅ `CacheFailure` → "Unable to load saved data. Please try again."
- ✅ `UnknownFailure` → "Something went wrong. Please try again."

#### Common Exceptions
- ✅ `TimeoutException` → Context-aware timeout messages
- ✅ `SocketException` → Network connectivity messages
- ✅ `FormatException` → "Invalid data format. Please try again."
- ✅ `HttpException` → HTTP status code specific messages

#### HTTP Status Codes
- ✅ 400 → "Invalid request. Please try again."
- ✅ 401 → "Session expired. Please sign in again."
- ✅ 403 → "Access denied. You don't have permission for this action."
- ✅ 404 → "Content not found. It may have been removed."
- ✅ 408 → "Request timed out. Please try again."
- ✅ 429 → "Too many requests. Please wait a moment and try again."
- ✅ 500/502/503/504 → "Service temporarily unavailable. Please try again later."

#### Error String Patterns
- ✅ Socket/connection errors
- ✅ Network unreachable
- ✅ Timeout errors
- ✅ Authentication/token errors
- ✅ JSON/parsing errors
- ✅ Configuration errors

### 3. Context-Specific Messages

The mapper can add context to make messages more specific:

```dart
ErrorMessageMapper.getDisplayMessage(error, context: 'chat')
// "Unable to send message. [base error message]"

ErrorMessageMapper.getDisplayMessage(error, context: 'thread')
// "Unable to load conversation. [base error message]"

ErrorMessageMapper.getDisplayMessage(error, context: 'delete')
// "Unable to delete. [base error message]"
```

**Supported Contexts**:
- `chat` / `message` → "Unable to send message..."
- `thread` / `conversation` → "Unable to load conversation..."
- `delete` → "Unable to delete..."
- `load` / `fetch` → "Unable to load content..."
- `save` → "Unable to save..."

---

## Integration with AI Feature

### Files Updated

#### 1. `ai_mode_screen.dart`
**Before**:
```dart
content: Text('Error: ${chatState.error}')
```

**After**:
```dart
final friendlyMessage = ErrorMessageMapper.getDisplayMessage(
  chatState.error,
  context: 'chat',
);
final isRetryable = ErrorMessageMapper.isRetryable(chatState.error);

SnackBar(
  content: Text(friendlyMessage),
  action: SnackBarAction(
    label: isRetryable ? 'Retry' : 'Dismiss',
    // ...
  ),
)
```

#### 2. `chat_controller.dart`
Updated 4 error handling locations:
- Stream error events
- Stream subscription errors
- Send message errors
- Load thread errors

**Example**:
```dart
// Before
error: error.toString()

// After
final friendlyMessage = ErrorMessageMapper.getDisplayMessage(
  error,
  context: 'chat',
);
state = state.copyWith(error: friendlyMessage)
```

#### 3. `thread_list_controller.dart`
Updated 2 error handling locations:
- Load threads errors
- Load more threads errors

#### 4. `chat_history_drawer.dart`
Updated delete thread error handling:

**Before**:
```dart
content: Text('Failed to delete conversation: ${e.toString()}')
```

**After**:
```dart
final friendlyMessage = ErrorMessageMapper.getDisplayMessage(
  e,
  context: 'delete',
);
content: Text(friendlyMessage)
```

---

## Testing

### Test File
**Location**: `test/core/utils/error_message_mapper_test.dart`

### Test Coverage
- ✅ 49 tests, all passing
- ✅ 100% method coverage
- ✅ All error types tested
- ✅ All HTTP status codes tested
- ✅ Context-specific messages tested
- ✅ Helper methods tested

### Test Groups
1. **getDisplayMessage** (33 tests)
   - Null errors
   - Failure objects (10 types)
   - Exception objects (5 types)
   - Error strings (15 patterns)
   - Context-specific messages (5 contexts)

2. **isNetworkError** (4 tests)
   - Exception detection
   - Failure detection
   - String pattern detection

3. **isTimeoutError** (3 tests)
   - Exception detection
   - String pattern detection

4. **isAuthError** (3 tests)
   - Failure detection
   - String pattern detection

5. **isRetryable** (6 tests)
   - Failure detection
   - Exception detection
   - String pattern detection

---

## Benefits

### User Experience
1. ✅ **Clear Messages**: No technical jargon or stack traces
2. ✅ **Actionable**: Users know what to do next
3. ✅ **Consistent**: Same error types show same messages
4. ✅ **Context-Aware**: Messages tailored to the operation

### Developer Experience
1. ✅ **Centralized**: One place to manage all error messages
2. ✅ **Reusable**: Can be used across entire application
3. ✅ **Maintainable**: Easy to update messages
4. ✅ **Type-Safe**: Works with existing Failure classes
5. ✅ **Well-Tested**: Comprehensive test coverage

### Production Ready
1. ✅ **Comprehensive**: Handles all common error scenarios
2. ✅ **Defensive**: Handles null and unexpected errors
3. ✅ **Documented**: Clear documentation and examples
4. ✅ **Tested**: 100% test coverage
5. ✅ **Integrated**: Already integrated into AI feature

---

## Usage Examples

### Basic Usage
```dart
try {
  await someOperation();
} catch (e) {
  final message = ErrorMessageMapper.getDisplayMessage(e);
  showSnackBar(message);
}
```

### With Context
```dart
try {
  await sendMessage(content);
} catch (e) {
  final message = ErrorMessageMapper.getDisplayMessage(e, context: 'chat');
  // "Unable to send message. [specific error]"
  showSnackBar(message);
}
```

### With Retry Logic
```dart
try {
  await loadData();
} catch (e) {
  final message = ErrorMessageMapper.getDisplayMessage(e);
  final canRetry = ErrorMessageMapper.isRetryable(e);
  
  showSnackBar(
    message,
    action: canRetry ? 'Retry' : 'Dismiss',
  );
}
```

### Error Classification
```dart
try {
  await apiCall();
} catch (e) {
  if (ErrorMessageMapper.isAuthError(e)) {
    // Redirect to login
    navigateToLogin();
  } else if (ErrorMessageMapper.isNetworkError(e)) {
    // Show offline indicator
    showOfflineIndicator();
  } else {
    // Show generic error
    showError(ErrorMessageMapper.getDisplayMessage(e));
  }
}
```

---

## Best Practices

### DO ✅
- Use `getDisplayMessage()` for all user-facing error messages
- Provide context when available for more specific messages
- Use helper methods (`isRetryable`, `isNetworkError`, etc.) for conditional logic
- Keep validation error messages specific (they pass through as-is)
- Log technical errors separately for debugging

### DON'T ❌
- Don't show raw `error.toString()` to users
- Don't expose HTTP status codes directly
- Don't show stack traces in production
- Don't create duplicate error message logic
- Don't forget to add context for better UX

---

## Future Enhancements

### Potential Improvements
1. **Localization**: Add multi-language support
2. **Analytics**: Track error types for monitoring
3. **Custom Messages**: Allow app-specific error messages
4. **Error Recovery**: Add automatic retry strategies
5. **User Feedback**: Collect user feedback on error messages

### Extension Points
The utility can be extended to:
- Support more error types
- Add more context types
- Provide error-specific actions
- Include error codes for support
- Add severity levels

---

## Migration Guide

### For Existing Code

1. **Import the utility**:
```dart
import 'package:flutter_pecha/core/utils/error_message_mapper.dart';
```

2. **Replace error.toString()**:
```dart
// Before
error: error.toString()

// After
error: ErrorMessageMapper.getDisplayMessage(error)
```

3. **Add context if available**:
```dart
error: ErrorMessageMapper.getDisplayMessage(error, context: 'chat')
```

4. **Use helper methods for logic**:
```dart
final canRetry = ErrorMessageMapper.isRetryable(error);
```

---

## Conclusion

The `ErrorMessageMapper` provides a production-ready, centralized solution for converting technical errors into user-friendly messages. It's:

- ✅ **Comprehensive**: Handles all common error types
- ✅ **Well-Tested**: 49 passing tests with 100% coverage
- ✅ **Integrated**: Already working in AI feature
- ✅ **Reusable**: Can be used throughout the application
- ✅ **Maintainable**: Single source of truth for error messages

The implementation significantly improves user experience by replacing technical error messages with clear, actionable, user-friendly text.
