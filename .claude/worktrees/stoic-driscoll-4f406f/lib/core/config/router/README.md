# Router Configuration - Protected Routes Implementation

This directory contains the production-ready routing implementation with authentication and authorization.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        User Navigation                       │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    appRouterProvider                         │
│                    (app_router.dart)                         │
│  - Riverpod Provider for GoRouter                           │
│  - Watches auth state changes                               │
│  - Defines all application routes                           │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                     RouteGuard.redirect()                    │
│                     (route_guard.dart)                       │
│  - Evaluates authentication state                           │
│  - Checks route permissions                                 │
│  - Handles onboarding flow                                  │
│  - Preserves deep links                                     │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                     AppRoutes Helpers                        │
│                     (app_routes.dart)                        │
│  - isPublicRoute()                                          │
│  - isGuestAccessible()                                      │
│  - requiresAuth()                                           │
└─────────────────────────────────────────────────────────────┘
```

## Files

### 1. `app_routes.dart`
**Purpose**: Single source of truth for all route definitions and access control logic.

**Key Features**:
- Route path constants organized by feature
- Route categorization (public, guest-accessible, protected)
- Helper methods for route access checking
- Pattern matching for nested routes

**Route Categories**:
- **Public Routes**: `/onboarding`, `/login` - No authentication required
- **Guest Accessible Routes**: `/home`, `/more`, `/ai-mode`, `/practice/plans/preview` - Accessible in guest mode
- **Protected Routes**: `/profile`, `/practice/*` (except preview), `/plans`, etc. - Require full authentication

### 2. `route_guard.dart`
**Purpose**: Centralized authentication and authorization logic for routing.

**Key Features**:
- Authentication state evaluation
- Guest mode restrictions
- Onboarding flow management
- Deep link preservation for post-login redirection
- Comprehensive logging for debugging

**Redirect Logic**:
1. **Loading State**: Show login screen while auth initializes
2. **Authenticated Users**: 
   - Check onboarding completion
   - Redirect to intended route after login
   - Allow full access to all routes
3. **Guest Users**:
   - Skip onboarding
   - Restrict to guest-accessible routes only
   - Redirect to home if accessing protected routes
4. **Unauthenticated Users**:
   - Allow public routes
   - Store intended route and redirect to login
   - Redirect back after successful authentication

### 3. `app_router.dart`
**Purpose**: Main router configuration with all application routes.

**Key Features**:
- Riverpod provider integration
- Auth state reactivity via `refreshListenable`
- Route guard integration
- Error handling
- All route definitions with proper builders

**Usage**:
```dart
// In main.dart or app initialization
final router = ref.watch(appRouterProvider);

MaterialApp.router(
  routerConfig: router,
  // ...
);
```

### 4. `route_config.dart`
**Purpose**: Backward compatibility layer (deprecated).

**Status**: Maintained for existing code, new code should use `AppRoutes` and `RouteGuard`.

## Usage Examples

### Checking Route Access

```dart
import 'package:flutter_pecha/core/config/router/app_routes.dart';

// Check if route is public
if (AppRoutes.isPublicRoute('/login')) {
  // Allow access
}

// Check if guest can access
if (AppRoutes.isGuestAccessible('/home')) {
  // Allow guest access
}

// Check if requires authentication
if (AppRoutes.requiresAuth('/profile')) {
  // Require login
}
```

### Navigation

```dart
import 'package:go_router/go_router.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';

// Navigate to a route
context.go(AppRoutes.home);

// Navigate with parameters
context.go('/reader/$textId', extra: navigationContext);

// Navigate to nested route
context.go(AppRoutes.practiceEditRoutine);
```

### Adding New Protected Routes

1. **Add route constant** in `app_routes.dart`:
```dart
static const String myNewRoute = '/my-new-route';
```

2. **Add to appropriate category**:
```dart
static const Set<String> protectedRoutes = {
  // ... existing routes
  myNewRoute,
};
```

3. **Add route definition** in `app_router.dart`:
```dart
GoRoute(
  path: "/my-new-route",
  name: "my-new-route",
  builder: (context, state) => const MyNewScreen(),
),
```

4. **Add API endpoint protection** (if needed) in `api_client_provider.dart`:
```dart
static const List<String> _protectedPaths = [
  // ... existing paths
  '/api/v1/my-new-endpoint',
];
```

## Authentication Flow

### Login Flow
```
User clicks login
  ↓
Auth state changes to loading
  ↓
RouteGuard redirects to login
  ↓
User authenticates
  ↓
Auth state changes to logged in
  ↓
Router refreshes
  ↓
RouteGuard checks pending route
  ↓
Redirect to intended route or home
```

### Deep Link Flow
```
User opens deep link to /practice
  ↓
Not authenticated
  ↓
RouteGuard stores /practice as pending route
  ↓
Redirect to login
  ↓
User authenticates
  ↓
RouteGuard retrieves pending route
  ↓
Redirect to /practice
```

### Guest Mode Flow
```
User continues as guest
  ↓
Auth state changes to guest mode
  ↓
Router refreshes
  ↓
User navigates to /profile
  ↓
RouteGuard checks guest accessibility
  ↓
Not guest accessible
  ↓
Redirect to home
```

## Security Considerations

1. **Route Protection**: All protected routes are checked on every navigation
2. **Token Management**: API client automatically adds auth tokens to protected endpoints
3. **Token Refresh**: Automatic token refresh on 401 responses
4. **Guest Restrictions**: Guest users cannot access user-specific features
5. **State Reactivity**: Router automatically responds to auth state changes

## Testing

### Manual Testing Checklist
- [ ] Unauthenticated user cannot access protected routes
- [ ] Authenticated user can access all routes
- [ ] Guest user has limited access (home, more, ai-mode only)
- [ ] Login page redirects to home when already authenticated
- [ ] Onboarding flow works correctly for new users
- [ ] Onboarding is skipped for guest users
- [ ] Deep links preserve intended destination
- [ ] Deep links redirect back after login
- [ ] Route transitions preserve state
- [ ] Token refresh doesn't interrupt navigation
- [ ] Logout clears pending routes
- [ ] Error handling for invalid routes works

### Debug Logging

Enable debug logging to see route guard decisions:
```dart
// RouteGuard logs all decisions with 'RouteGuard' tag
// Check console for messages like:
// [RouteGuard] Route guard check: path=/profile, isLoggedIn=false
// [RouteGuard] Unauthenticated user trying to access: /profile, redirecting to login
```

## Migration from Old Router

If you're migrating from `go_router.dart` (old router):

1. **Update provider usage**:
```dart
// Old
final router = ref.watch(goRouterProvider);

// New
final router = ref.watch(appRouterProvider);
```

2. **Update route references**:
```dart
// Old
RouteConfig.isProtectedRoute(path)

// New
AppRoutes.requiresAuth(path)
```

3. **No changes needed** for navigation code - GoRouter API remains the same

## Performance Considerations

- **Route Guard Caching**: Route checks use efficient pattern matching
- **Auth State Reactivity**: Router only rebuilds when auth state actually changes
- **Lazy Route Building**: Routes are built only when navigated to
- **Memory Management**: GoRouterRefreshStream properly disposes subscriptions

## Troubleshooting

### Issue: Routes not protecting properly
**Solution**: Check that route is in correct category in `app_routes.dart`

### Issue: Deep links not working
**Solution**: Verify `RouteGuard._pendingRoute` is being set and cleared properly

### Issue: Infinite redirect loop
**Solution**: Check redirect logic doesn't create circular dependencies

### Issue: Auth state not updating router
**Solution**: Verify `GoRouterRefreshStream` is properly watching auth provider

## Future Enhancements

- [ ] Persistent storage for pending routes (survive app restart)
- [ ] Role-based access control (RBAC) for fine-grained permissions
- [ ] Route analytics and tracking
- [ ] A/B testing support for routes
- [ ] Route preloading for better performance
