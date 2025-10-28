# Authentication Architecture

## Overview

Flutter Pecha uses Auth0 for authentication with **ID token-based authorization**. This document describes the architecture, design decisions, and implementation details.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Application                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │    UI      │  │ AuthNotifier │  │   ApiClient      │   │
│  │  Widgets   │──│  (Riverpod)  │──│ (HTTP Client)    │   │
│  └────────────┘  └──────────────┘  └──────────────────┘   │
│                         │                    │              │
│                         │                    │              │
│                  ┌──────────────┐            │              │
│                  │ AuthService  │────────────┘              │
│                  │  (Singleton) │                           │
│                  └──────────────┘                           │
│                         │                                    │
└─────────────────────────┼────────────────────────────────────┘
                          │
                          ▼
                 ┌─────────────────┐
                 │   Auth0 SDK     │
                 │ (Credentials    │
                 │   Manager)      │
                 └─────────────────┘
                          │
                          ▼
              ┌──────────────────────┐
              │   Platform Storage   │
              │  Keychain/Keystore   │
              └──────────────────────┘
```

---

## Design Decisions

### 1. **Why ID Tokens for API Authorization?**

**Backend Requirement:**

- Backend validates JWT ID tokens
- ID tokens contain user identity claims
- Access tokens not used by backend

**Implication:**

- Must manually check ID token expiry
- Cannot rely on Auth0 SDK's automatic refresh
- Requires custom token validation logic

### 2. **Why Singleton AuthService?**

**Benefits:**

- Single source of truth for auth state
- Prevents multiple Auth0 instances
- Consistent credential management
- Easy to test and mock

**Implementation:**

```dart
class AuthService {
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  static AuthService get instance => _instance;
}
```

### 3. **Why Riverpod for State Management?**

**Benefits:**

- Compile-time safety
- Easy dependency injection
- Proper disposal lifecycle
- Testing-friendly

**Usage:**

```dart
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = AuthService.instance;
  return AuthNotifier(authService: authService);
});
```

---

## Component Details

### AuthService

**Responsibilities:**

- Auth0 SDK initialization
- Login/logout operations
- Token validation and refresh
- Credential storage management

**Key Methods:**

```dart
Future<void> initialize()
Future<Credentials?> loginWithGoogle()
Future<Credentials?> loginWithApple()
Future<String?> getValidIdToken()
Future<String?> refreshIdToken()
Future<void> localLogout()
Future<void> globalLogout()
bool isIdTokenExpired(String idToken)
```

### ApiClient

**Responsibilities:**

- HTTP request interception
- Automatic token injection
- 401 retry logic
- Request/response logging

**Key Methods:**

```dart
Future<StreamedResponse> send(BaseRequest request)
void close()
BaseRequest _cloneRequest(BaseRequest request)
bool _isProtectedRoute(String path)
```

### AuthNotifier

**Responsibilities:**

- Authentication state management
- Login state restoration
- Error handling
- User logout coordination

**State:**

```dart
class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final bool isGuest;
  final String? userId;
  final UserProfile? userProfile;
  final String? errorMessage;
}
```

---

## Security Architecture

### Token Storage

- **Platform:** iOS Keychain, Android Keystore
- **Managed by:** Auth0 `credentialsManager`
- **Encryption:** Platform-provided
- **Access:** App-scoped only

### Token Transmission

- **Protocol:** HTTPS only
- **Header:** `Authorization: Bearer {token}`
- **Scope:** Protected routes only

### Token Refresh

- **Trigger:** Automatic on expiry
- **Method:** OAuth 2.0 refresh token grant
- **Concurrency:** Single refresh per expiry
- **Fallback:** User logout on refresh failure

---

## Error Handling Strategy

### Error Types

```dart
class AuthException implements Exception {
  final String message;
  final String? code;
}
```

### Error Flow

```
Authentication Error
        │
        ├─ WebAuthenticationException
        │  └─ User cancelled → Show message
        │
        ├─ ApiException (refresh failed)
        │  ├─ Network error → Retry
        │  └─ 403/Invalid token → Logout
        │
        └─ CredentialsManagerException
           └─ No credentials → Require login
```

---

## Performance Considerations

### Token Validation

- **Cost:** O(1) - local JWT parsing
- **Network:** None
- **Frequency:** Every API call

### Token Refresh

- **Cost:** 1 network call to Auth0
- **Duration:** ~500ms typical
- **Frequency:** Every 50-60 minutes
- **Concurrency:** Serialized

### Optimization Strategies

1. **Local validation** before network calls
2. **Concurrency control** for refresh operations
3. **2-minute buffer** to reduce edge cases
4. **Caching** by Auth0 SDK

---

## Testing Strategy

### Unit Tests

- Token expiry validation
- Concurrency control
- Error handling
- State management

### Integration Tests

- Login flow
- Token refresh flow
- 401 retry mechanism
- Multiple simultaneous requests

### Manual Testing

- Login with Google/Apple
- Token expiry scenarios
- Network failure handling
- App backgrounding/foregrounding

---

## Deployment Considerations

### Environment Variables

```env
AUTH0_DOMAIN=your-tenant.auth0.com
AUTH0_CLIENT_ID=your-client-id
AUTH0_AUDIENCE=your-api-audience
```

### Auth0 Configuration

- **Application Type:** Native
- **Grant Types:** Authorization Code, Refresh Token
- **Token Settings:**
  - ID Token Expiration: 3600s (1 hour)
  - Refresh Token Expiration: 2592000s (30 days)
  - Refresh Token Rotation: Enabled

### Monitoring

- Token refresh frequency
- Authentication failure rate
- 401 retry success rate
- Auth0 API call volume

---

## API Endpoints

### Protected Routes

```dart
static const List<String> _protectedPaths = [
  '/api/v1/users/me',
  '/api/v1/users/me/plans',
];
```

### Adding New Protected Routes

1. Add path to `_protectedPaths` in `ApiClient`
2. Ensure backend validates ID token
3. Test 401 retry mechanism
4. Update documentation

---

## Login Flow

```
User clicks "Login with Google"
        ↓
AuthNotifier.login(connection: 'google')
        ↓
AuthService.loginWithGoogle()
        ↓
Auth0 WebAuthentication
        ↓
User authenticates in browser
        ↓
Auth0 returns credentials
        ↓
Store credentials in credentialsManager
        ↓
Update AuthState (isLoggedIn: true)
        ↓
Navigate to home screen
```

---

## Token Refresh Flow

```
API call needs authentication
        ↓
ApiClient calls getValidIdToken()
        ↓
Check if token expired (JWT parsing)
        ↓
Token expired? → Refresh token
        ↓
Call Auth0 /oauth/token endpoint
        ↓
Get new ID token + access token
        ↓
Store new credentials
        ↓
Return new ID token to ApiClient
        ↓
Add Bearer token to request
        ↓
Make API call
```

---

## Logout Flow

### Local Logout

```
User clicks "Logout"
        ↓
AuthNotifier.logout()
        ↓
AuthService.localLogout()
        ↓
Clear credentials from device
        ↓
Update AuthState (isLoggedIn: false)
        ↓
Navigate to login screen
```

### Global Logout

```
User clicks "Logout from all devices"
        ↓
AuthNotifier.logout()
        ↓
AuthService.globalLogout()
        ↓
Call Auth0 logout endpoint
        ↓
Clear Auth0 session
        ↓
Clear credentials from device
        ↓
Update AuthState (isLoggedIn: false)
        ↓
Navigate to login screen
```

---

## State Restoration

```
App launches
        ↓
AuthNotifier._restoreLoginState()
        ↓
AuthService.initialize()
        ↓
Check hasValidCredentials()
        ↓
Credentials exist?
    ├─ Yes → Get credentials
    │         ├─ Success → Update state (logged in)
    │         └─ Fail → Clear credentials, show login
    └─ No → Show login screen
```

---

## Best Practices

### 1. **Always Use getValidIdToken()**

```dart
// ✅ Good
final token = await authService.getValidIdToken();

// ❌ Bad - might return expired token
final creds = await authService.getCredentials();
final token = creds.idToken;
```

### 2. **Force Refresh on 401**

```dart
// ✅ Good
if (response.statusCode == 401) {
  final token = await authService.refreshIdToken(); // Forces refresh
}

// ❌ Bad - might return same expired token
if (response.statusCode == 401) {
  final token = await authService.getValidIdToken();
}
```

### 3. **Handle Errors Gracefully**

```dart
// ✅ Good
try {
  final token = await authService.getValidIdToken();
} on AuthException catch (e) {
  logger.warning('Auth failed: $e');
  // Show error to user
}

// ❌ Bad - no error handling
final token = await authService.getValidIdToken();
```

### 4. **Dispose Resources**

```dart
// ✅ Good
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(authService);
  ref.onDispose(() => client.close());
  return client;
});

// ❌ Bad - memory leak
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(authService);
});
```

---

## Troubleshooting

### Issue: Token refresh loops

**Symptom:** Multiple refresh calls in quick succession  
**Cause:** Race condition in concurrency control  
**Solution:** Verify `_ongoingIdTokenRefresh` is captured to local variable

### Issue: 401 errors persist

**Symptom:** Retry still returns 401  
**Cause:** Using `getValidIdToken()` instead of `refreshIdToken()`  
**Solution:** Force refresh with `refreshIdToken()` on 401

### Issue: User logged out unexpectedly

**Symptom:** User returns to login screen  
**Cause:** Refresh token expired  
**Solution:** Expected behavior - refresh tokens expire after 30 days

### Issue: High Auth0 API call volume

**Symptom:** Many `renewCredentials()` calls  
**Cause:** Concurrency control not working  
**Solution:** Check logs for "Waiting for ongoing refresh" messages

---

## Metrics & Monitoring

### Key Performance Indicators

| Metric                        | Target  | Alert Threshold |
| ----------------------------- | ------- | --------------- |
| Token Refresh Frequency       | 1/hour  | > 2/minute      |
| 401 Error Rate                | < 1%    | > 5%            |
| Auth0 API Success Rate        | > 99%   | < 95%           |
| Average Refresh Time          | < 600ms | > 2s            |
| Concurrent Refresh Efficiency | > 95%   | < 80%           |

### Log Analysis

```bash
# Count token refreshes
grep "ID token refreshed successfully" logs.txt | wc -l

# Check for race conditions
grep "Waiting for ongoing" logs.txt

# Find 401 retries
grep "Received 401" logs.txt

# Auth errors
grep "Auth0 API error" logs.txt
```

---

**Version:** 1.0  
**Last Updated:** October 13, 2025  
**Status:** ✅ Production Ready
