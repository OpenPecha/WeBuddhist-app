# Splash Screen & Guest Mode Improvements

**Date:** October 14, 2025  
**Version:** 0.8.5+18  
**Type:** UX Enhancement & Bug Fix

## Overview

This update significantly improves the app launch experience and guest user journey by:

1. Eliminating splash screen flicker on first app open
2. Adding branded native splash screens
3. Persisting guest mode across app sessions
4. Improving guest user profile experience

---

## 🎯 Changes Summary

### 1. Splash Screen Flicker Fix

**Problem:** Users experienced a visible flicker when opening the app for the first time, where the Flutter splash screen briefly appeared before transitioning to the login/home screen.

**Root Cause:** The app had both a native splash screen and a Flutter splash screen route, causing a double-splash problem and visible transition.

**Solution:** Removed the Flutter-level splash screen entirely and rely only on native splash screens for a seamless app launch experience.

**Files Modified:**

- `lib/features/auth/application/auth_provider.dart`
- `lib/core/config/router/go_router.dart`
- `lib/core/config/router/route_config.dart`
- `lib/features/splash/presentation/splash_screen.dart` (deleted)

**Technical Details:**

- Changed `AuthNotifier` initial loading state to `true`
- Updated router `initialLocation` from `'/'` to `RouteConfig.home`
- Simplified redirect logic to allow navigation during auth loading
- Removed splash route from router configuration
- Native splash remains visible until Flutter renders the final destination

---

### 2. Branded Native Splash Screens

**Enhancement:** Added app logo and proper theme colors to native splash screens for both Android and iOS.

**Android Changes:**

- `android/app/src/main/res/drawable/launch_background.xml` - Added centered app logo
- `android/app/src/main/res/drawable-v21/launch_background.xml` - Added logo with adaptive background
- `android/app/src/main/res/values/styles.xml` - Set white background for light mode
- `android/app/src/main/res/values-night/styles.xml` - Set dark background (#121212) for dark mode

**iOS Changes:**

- `ios/Runner/Assets.xcassets/LaunchImage.imageset/` - Updated all resolution images with app logo
- Splash screen now displays centered app logo on white background

**Result:** Professional, branded splash screens that match app identity across all platforms and themes.

---

### 3. Guest Mode Persistence

**Problem:** Guest users who chose "Continue as Guest" were redirected to the login page on subsequent app opens, forcing them to repeatedly dismiss the login screen.

**Solution:** Implemented persistent guest mode using SharedPreferences, treating guest users similar to authenticated users for navigation while keeping authentication easily accessible.

**Files Modified:**

- `lib/features/auth/auth_service.dart`
- `lib/features/auth/application/auth_provider.dart`
- `lib/features/auth/presentation/profile_page.dart`

**New Features:**

#### AuthService Methods

```dart
Future<void> saveGuestMode()    // Persist guest preference
Future<bool> isGuestMode()      // Check saved guest state
Future<void> clearGuestMode()   // Remove guest state
```

#### Auth State Restoration Flow

1. Check for valid credentials → Restore authenticated state
2. Check for saved guest mode → Restore guest state
3. No state found → Show login page

#### Guest Profile UI

- Custom guest profile page with:
  - Guest avatar icon
  - "Sign In" button prominently displayed
  - Benefits card showing features unlocked by signing in
  - Full dark mode support

**User Flows:**

**First Time User:**

```
App Opens → Login → Choose Guest → Home (Guest)
App Restarts → Home (Guest) ✨ No login prompt!
```

**Guest to Authenticated:**

```
Home (Guest) → Profile → "Sign In" → Authenticate → Home (Authenticated)
```

**Logout:**

```
Any Mode → Logout → Login Page → Choose Guest or Sign In
```

---

### 4. Guest User Navigation Fix

**Problem:** Guest users couldn't tap the account icon on the home screen to access their profile.

**Solution:** Added `GestureDetector` with navigation to guest user icon in the home screen top bar.

**Files Modified:**

- `lib/features/home/presentation/home_screen.dart`

**Change:**

```dart
// Before: Static icon with no interaction
if (authState.isGuest) Icon(Icons.account_circle, size: 32),

// After: Tappable icon that navigates to profile
if (authState.isGuest)
  GestureDetector(
    onTap: () => context.push('/profile'),
    child: Hero(
      tag: 'profile-avatar',
      child: Icon(Icons.account_circle, size: 32),
    ),
  ),
```

---

### 5. Dark Mode Support for Guest Profile

**Enhancement:** Made guest profile page fully compatible with dark mode.

**Files Modified:**

- `lib/features/auth/presentation/profile_page.dart`

**Dark Mode Adaptations:**

- Avatar background: `Colors.grey[800]` (dark) / `Colors.grey[400]` (light)
- Avatar icon: `Colors.grey[300]` (dark) / `Colors.white` (light)
- Description text: `Colors.grey[400]` (dark) / `Colors.grey[600]` (light)
- Card elevation and colors adapt to theme
- Benefit icons use `colorScheme.secondary` in dark mode
- All text elements use theme-appropriate colors

---

## 📊 Impact

### User Experience Improvements

- ✅ No more splash screen flicker
- ✅ Professional branded splash screens
- ✅ Seamless guest mode across sessions
- ✅ Easy upgrade path from guest to authenticated
- ✅ Consistent dark mode experience

### Technical Improvements

- ✅ Cleaner router architecture
- ✅ Proper state persistence
- ✅ Better theme support
- ✅ Reduced complexity (removed unnecessary splash route)

### Industry Best Practices

- ✅ Persistent user choice
- ✅ Minimal friction for guest users
- ✅ Clear visual hierarchy
- ✅ Accessible upgrade options
- ✅ Graceful feature degradation

---

## 🧪 Testing Checklist

- [ ] First app launch shows no flicker
- [ ] Branded splash screen displays on launch
- [ ] Guest mode persists after app restart
- [ ] Guest users can access profile from home icon
- [ ] Guest profile shows "Sign In" button
- [ ] Authenticated users maintain session
- [ ] Logout clears guest mode
- [ ] Dark mode works correctly in guest profile
- [ ] Theme transitions work smoothly
- [ ] Navigation flows work as expected

---

## 🔄 Migration Notes

**No Breaking Changes:** These are internal improvements that don't affect the public API or user data.

**Automatic Migration:** Existing users will seamlessly transition to the new experience. Previous guest sessions are not retained (fresh start with new persistence mechanism).

---

## 📝 Technical Details

### Dependencies Used

- `shared_preferences` - For guest mode persistence
- Existing routing and state management (go_router, riverpod)

### State Management

- Guest mode stored in SharedPreferences with key: `is_guest_mode`
- Auth state initialization happens before router build
- Loading state displayed via native splash

### Platform Support

- ✅ Android (API 21+)
- ✅ iOS
- ✅ Both light and dark modes

---

## 👥 Related Issues

This update addresses user feedback regarding:

- Poor first-launch experience with splash flicker
- Repeated login prompts for guest users
- Lack of clear path to sign in from guest mode
- Dark mode inconsistencies

---

## 📚 Additional Resources

- Technical Documentation: `/docs/architecture/GUEST_MODE_PERSISTENCE.md`
- Router Architecture: `/docs/architecture/AUTH_IMPLEMENTATION.md`
- Testing Guide: Coming soon

---

**Contributors:** Development Team  
**Review Status:** ✅ Completed  
**Release Date:** TBD
