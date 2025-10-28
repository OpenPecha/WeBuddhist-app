# Guest Mode Persistence - Technical Documentation

## Overview

This document describes the implementation of persistent guest mode in the Flutter Pecha app, allowing users to browse as guests without repeated login prompts across app sessions.

---

## Architecture

### High-Level Flow

```
App Launch
    ↓
AuthNotifier Constructor (isLoading: true)
    ↓
_restoreLoginState()
    ↓
├─ Check Valid Credentials
│  ├─ Yes → Restore Authenticated State
│  └─ No → Continue
│
├─ Check Guest Mode (SharedPreferences)
│  ├─ Yes → Restore Guest State
│  └─ No → Show Login
│
└─ Router Redirect Logic
   ├─ isLoading: true → Allow navigation (native splash visible)
   └─ isLoading: false → Route based on auth state
```

---

## Implementation Details

### 1. Guest Mode Storage

**Location:** `lib/features/auth/auth_service.dart`

**Storage Mechanism:** SharedPreferences

**Key:** `is_guest_mode` (boolean)

#### Methods

```dart
/// Save guest mode preference to SharedPreferences
Future<void> saveGuestMode() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_guestModeKey, true);
}

/// Check if user previously chose guest mode
Future<bool> isGuestMode() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_guestModeKey) ?? false;
}

/// Clear guest mode state (called on login or logout)
Future<void> clearGuestMode() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_guestModeKey);
}
```

**Why SharedPreferences?**

- Simple boolean value
- Persistent across app sessions
- Platform-agnostic
- Fast access
- No security concerns (public state)

---

### 2. Auth State Management

**Location:** `lib/features/auth/application/auth_provider.dart`

#### AuthState Properties

```dart
class AuthState {
  final bool isLoggedIn;    // Both authenticated and guest users
  final bool isLoading;     // During auth initialization
  final bool isGuest;       // Distinguishes guest from authenticated
  final String? userId;     // 'guest' for guests, auth ID for users
  final UserProfile? userProfile;  // Null for guests
}
```

#### State Restoration Logic

```dart
Future<void> _restoreLoginState() async {
  try {
    await authService.initialize();

    // 1. Check credentials first (authenticated users)
    final hasCredentials = await authService.hasValidCredentials();
    if (hasCredentials) {
      final credentials = await authService.getCredentials();
      state = state.copyWith(
        isLoggedIn: true,
        isGuest: false,
        userId: credentials?.user.sub,
        userProfile: credentials?.user,
        isLoading: false,
      );
      return;
    }

    // 2. Check guest mode (returning guest users)
    final isGuest = await authService.isGuestMode();
    if (isGuest) {
      state = state.copyWith(
        isLoggedIn: true,
        isGuest: true,
        userId: 'guest',
        userProfile: null,
        isLoading: false,
      );
      return;
    }

    // 3. No state found (new users)
    state = state.copyWith(
      isLoggedIn: false,
      isGuest: false,
      isLoading: false,
    );
  } catch (e) {
    await _handleAuthFailure();
  }
}
```

#### State Transitions

**Choosing Guest Mode:**

```dart
Future<void> continueAsGuest() async {
  await authService.saveGuestMode();  // Persist choice
  state = state.copyWith(
    isLoggedIn: true,
    isGuest: true,
    userId: 'guest',
  );
}
```

**Guest → Authenticated:**

```dart
Future<void> login({String? connection}) async {
  // ... authenticate with Auth0 ...
  await authService.clearGuestMode();  // Clear guest state
  state = state.copyWith(
    isLoggedIn: true,
    isGuest: false,
    userId: credentials.user.sub,
    userProfile: credentials.user,
  );
}
```

**Logout (Any Mode):**

```dart
Future<void> logout() async {
  await authService.localLogout();  // Clears credentials AND guest mode
  state = state.copyWith(
    isLoggedIn: false,
    isGuest: false,
  );
}
```

---

### 3. Router Integration

**Location:** `lib/core/config/router/go_router.dart`

#### Key Design Decision

Both authenticated and guest users have `isLoggedIn: true`, allowing them to access protected routes. The router doesn't need to distinguish between them.

```dart
redirect: (context, state) {
  final isLoading = authState.isLoading;
  final isLoggedIn = authState.isLoggedIn;  // True for both types
  final currentPath = state.fullPath ?? RouteConfig.home;

  // 1. While loading, allow navigation (native splash visible)
  if (isLoading) {
    return null;
  }

  // 2. Logged-in users (guest or authenticated) on login page → home
  if (isLoggedIn && currentPath == RouteConfig.login) {
    return RouteConfig.home;
  }

  // 3. Not logged-in trying to access protected routes → login
  if (!isLoggedIn && RouteConfig.isProtectedRoute(currentPath)) {
    return RouteConfig.login;
  }

  return null;
}
```

**Why This Works:**

- Simplifies routing logic
- Guest users get same navigation access
- Feature restrictions handled at component level, not routing level
- Login page accessible via profile (not blocked by router)

---

### 4. Guest Profile UI

**Location:** `lib/features/auth/presentation/profile_page.dart`

#### Conditional Rendering

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final authState = ref.watch(authProvider);

  if (authState.isGuest) {
    return _buildGuestProfile(context, ref);
  }

  // Show authenticated user profile
  return _buildAuthenticatedProfile(context, authState);
}
```

#### Guest Profile Components

1. **Guest Avatar**

   - Icon: `Icons.person_outline`
   - Background color: Theme-aware grey

2. **Guest Label**

   - Title: "Guest User"
   - Description: "You're browsing as a guest"

3. **Sign In Button**

   - Prominent placement
   - Direct navigation to login page
   - Primary action style

4. **Benefits Card**
   - Lists features available after sign-in:
     - Save progress
     - Sync across devices
     - Personalized content
     - Custom notifications

#### Dark Mode Support

```dart
final isDarkMode = Theme.of(context).brightness == Brightness.dark;

// Avatar
CircleAvatar(
  backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[400],
  child: Icon(
    Icons.person_outline,
    color: isDarkMode ? Colors.grey[300] : Colors.white,
  ),
)

// Card
Card(
  elevation: isDarkMode ? 2 : 1,
  color: Theme.of(context).cardColor,
  // ...
)

// Icons
Icon(
  icon,
  color: isDarkMode
    ? Theme.of(context).colorScheme.secondary
    : Theme.of(context).primaryColor,
)
```

---

## State Diagram

```
┌─────────────────┐
│   App Launch    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Auth Loading   │ isLoading: true
│ (Native Splash) │ isLoggedIn: false
└────────┬────────┘
         │
         ▼
┌─────────────────────────────┐
│  Check Credentials          │
├─────────────────────────────┤
│ Has Valid Credentials?      │
│  ├─ Yes → Authenticated     │
│  └─ No  → Check Guest Mode  │
└────────┬────────────────────┘
         │
         ├─── Yes ──────────────────┐
         │                          │
         ▼                          ▼
┌────────────────┐        ┌────────────────┐
│ Authenticated  │        │  Guest Mode    │
│ State          │        │  State         │
├────────────────┤        ├────────────────┤
│ isLoggedIn: T  │        │ isLoggedIn: T  │
│ isGuest: F     │        │ isGuest: T     │
│ userId: auth_id│        │ userId: 'guest'│
│ userProfile: ✓ │        │ userProfile: ✗ │
└────────┬───────┘        └────────┬───────┘
         │                         │
         └──────────┬──────────────┘
                    │
                    ▼
            ┌───────────────┐
            │  Home Screen  │
            └───────────────┘

         No Credentials & No Guest Mode
                    │
                    ▼
            ┌───────────────┐
            │  Login Page   │
            └───────────────┘
```

---

## Testing Strategy

### Unit Tests

```dart
// Test guest mode persistence
test('saveGuestMode persists to SharedPreferences', () async {
  await authService.saveGuestMode();
  expect(await authService.isGuestMode(), true);
});

// Test guest mode clearing
test('clearGuestMode removes from SharedPreferences', () async {
  await authService.saveGuestMode();
  await authService.clearGuestMode();
  expect(await authService.isGuestMode(), false);
});

// Test state restoration
test('restores guest state on app restart', () async {
  await authService.saveGuestMode();
  final notifier = AuthNotifier(authService: authService);
  await Future.delayed(Duration.zero); // Allow async init
  expect(notifier.state.isGuest, true);
  expect(notifier.state.isLoggedIn, true);
});
```

### Integration Tests

```dart
testWidgets('guest user can navigate to profile', (tester) async {
  // Set up guest state
  await authService.saveGuestMode();

  // Launch app
  await tester.pumpWidget(MyApp());
  await tester.pumpAndSettle();

  // Find and tap profile icon
  final profileIcon = find.byIcon(Icons.account_circle);
  await tester.tap(profileIcon);
  await tester.pumpAndSettle();

  // Verify profile page shown
  expect(find.text('Guest User'), findsOneWidget);
  expect(find.text('Sign In'), findsOneWidget);
});
```

### Manual Test Scenarios

1. **First Launch as Guest**

   - Open app → Tap "Continue as Guest" → Close app → Reopen
   - Expected: Home screen (guest mode)

2. **Guest to Authenticated**

   - Open as guest → Tap profile icon → Tap "Sign In" → Authenticate → Close app → Reopen
   - Expected: Home screen (authenticated)

3. **Logout from Guest**

   - Open as guest → Navigate to settings → Tap "Logout"
   - Expected: Login page shown

4. **Dark Mode**
   - Enable dark mode → Open as guest → Navigate to profile
   - Expected: Proper dark mode colors throughout

---

## Performance Considerations

### SharedPreferences Access

- **Read:** ~1-2ms (async but fast)
- **Write:** ~5-10ms (async, non-blocking)
- **Impact:** Negligible - happens once at app startup

### Auth State Initialization

- Runs asynchronously in constructor
- Native splash visible during initialization
- No blocking of UI thread

### Memory Footprint

- Single boolean value in SharedPreferences
- Minimal impact on app memory

---

## Security Considerations

### Why Guest Mode is Safe

1. **No Sensitive Data:** Only stores a boolean flag
2. **Public State:** Guest status is not private information
3. **Easy Reset:** User can logout to clear state
4. **No Credentials:** No auth tokens or passwords stored
5. **Platform Secure:** SharedPreferences uses platform keystore

### What Guest Users Cannot Do

- Access personalized data
- Sync across devices
- Save preferences permanently
- Access user-specific features

---

## Future Enhancements

### Possible Improvements

1. **Guest Data Migration**

   - Allow guests to keep their progress when signing in
   - Sync guest bookmarks to authenticated account

2. **Guest Feature Tracking**

   - Analytics on guest user behavior
   - Conversion rate from guest to authenticated

3. **Time-Limited Guest Mode**

   - Prompt sign-in after X days of guest usage
   - Progressive nudges to authenticate

4. **Guest Mode Customization**
   - Allow some preferences in guest mode
   - Theme preferences, language, etc.

---

## Troubleshooting

### Guest Mode Not Persisting

**Symptoms:** Guest users see login screen on restart

**Check:**

1. SharedPreferences write succeeding?
2. App has storage permissions?
3. `saveGuestMode()` being called?

**Debug:**

```dart
final prefs = await SharedPreferences.getInstance();
print('Guest mode: ${prefs.getBool('is_guest_mode')}');
```

### Cannot Access Profile as Guest

**Symptoms:** Tapping profile icon does nothing

**Check:**

1. `GestureDetector` wrapping icon in home screen?
2. Navigation route configured?
3. `authState.isGuest` returning true?

---

## References

- [SharedPreferences Package](https://pub.dev/packages/shared_preferences)
- [Flutter State Management Best Practices](https://docs.flutter.dev/data-and-backend/state-mgmt)
- [Material Design - Guest Access Patterns](https://material.io)

---

**Last Updated:** October 14, 2025  
**Version:** 1.0  
**Author:** Development Team
