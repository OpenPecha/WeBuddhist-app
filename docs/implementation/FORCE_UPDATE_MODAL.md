# Force Update Modal Implementation

## Overview

Implements an app-wide, non-dismissible forced-update modal on Android and iOS. When the `upgrader` package detects that a newer version is available on the Play Store / App Store, a blocking dialog is shown over every route and cannot be dismissed — the user must tap "Update now" to be taken to the store.

The soft, dismissible update banner that previously appeared only on the home screen has been removed; the force modal supersedes it entirely.

---

## Files

| File | Role |
|------|------|
| `lib/core/services/upgrade/app_upgrade_service.dart` | Singleton wrapper around `upgrader`; exposes `isUpdateAvailable()` and `openAppStore()` |
| `lib/core/services/upgrade/upgrade_provider.dart` | Riverpod providers: `updateAvailableProvider`, `openAppStoreProvider` |
| `lib/core/services/upgrade/force_update_dialog.dart` | Non-dismissible `AlertDialog` UI |
| `lib/core/services/upgrade/force_update_gate.dart` | Gate widget mounted in `MaterialApp.router`'s `builder`; triggers the dialog |
| `lib/core/config/router/app_router.dart` | Exposes `rootNavigatorKey` used by the gate to obtain an in-tree context |

---

## Architecture

```
UncontrolledProviderScope
  └─ MaterialApp.router
      └─ builder: ForceUpdateGate          ← watches updateAvailableProvider
          └─ GoRouter Navigator            ← rootNavigatorKey attached here
              └─ ... all routes ...
```

`ForceUpdateGate` lives above the navigator so it covers every route. Because its own `BuildContext` is above the navigator, `showDialog` cannot resolve `Navigator.of(context)` from there. The gate therefore uses `rootNavigatorKey.currentContext` — a context that **is** inside the navigator tree — to push the dialog.

### Flow

```
App launch
  → ForceUpdateGate watches updateAvailableProvider (FutureProvider)
      → AppUpgradeService.initialize()
          → Upgrader fetches store version via Play Store / App Store API
      → AppUpgradeService.isUpdateAvailable()
          → upgrader.shouldDisplayUpgrade() → true if store > installed
  → whenData(true) fires once (_dialogShown guard)
      → addPostFrameCallback
          → showDialog(context: rootNavigatorKey.currentContext, barrierDismissible: false)
              → ForceUpdateDialog (PopScope canPop: false)
  → User taps "Update now"
      → AppUpgradeService.openAppStore()
          → upgrader.sendUserToAppStore() → deep-links to listing
```

---

## Key Design Decisions

### Non-dismissibility
- `barrierDismissible: false` on `showDialog` — tapping outside the dialog does nothing.
- `PopScope(canPop: false)` on the dialog widget — back button and predictive-back gesture are ignored.
- No "Later" / "Skip" / close button.

### Navigator context fix
`MaterialApp.router`'s `builder` context sits **above** the GoRouter `Navigator`. Calling `showDialog(context: builderContext)` would silently fail because `Navigator.of(context, rootNavigator: true)` traverses ancestors, not descendants. The fix: a `GlobalKey<NavigatorState> rootNavigatorKey` is passed to `GoRouter(navigatorKey:)` and used in the gate.

### `durationUntilAlertAgain: Duration.zero`
The `upgrader` package throttles re-checking by 24 hours by default. For a forced update, the dialog's own non-dismissibility handles re-prompting, so this cooldown is removed.

### Platform guard
The gate returns the unwrapped child on non-Android/iOS platforms (e.g. macOS) because neither the Play Store nor the App Store is reachable there.

### One-shot per session
`_dialogShown` flag in `_ForceUpdateGateState` prevents the dialog being stacked on every rebuild while the `FutureProvider` is in its data state.

---

## Localization

Three keys added to all ARB files (`app_en.arb`, `app_bo.arb`, `app_zh.arb`):

| Key | English | Tibetan | Chinese |
|-----|---------|---------|---------|
| `force_update_title` | Update required | གསར་བསྒྱུར་དགོས་མཁོ། | 需要更新 |
| `force_update_message` | A new version of the app is available. Please update to continue. | མཉེན་ཆས་ཀྱི་པར་གཞི་གསར་པ་ཞིག་ཡོད་པས། མུ་མཐུད་སྤྱོད་རོགས་གནང་བར་གསར་བསྒྱུར་མཛད་རོགས། | 有新版本可用，請更新後繼續使用。 |
| `force_update_button` | Update now | གསར་བསྒྱུར། | 立即更新 |

Access via `context.l10n.force_update_title` etc.

---

## Testing

To force the modal on every launch without a real store update, set `debugDisplayAlways = true` in `upgrade_provider.dart`:

```dart
// lib/core/services/upgrade/upgrade_provider.dart
const debugDisplayAlways = true; // revert to false before shipping
```

**Revert to `false` before releasing to production.**

### Checklist
- [ ] Modal appears over splash / login / home on cold start
- [ ] Back button does nothing while modal is visible
- [ ] Tapping outside the dialog does nothing
- [ ] "Update now" deep-links to the correct store listing
- [ ] Modal does NOT appear on macOS builds
- [ ] Modal does NOT appear when `debugDisplayAlways = false` and app is up to date

---

## Caveats

- **Any newer store version is treated as mandatory.** There is no backend-driven `min_supported_version` flag. If you need selective enforcement (e.g. patch versions optional, minor versions forced), add a `min_supported_version` field to the `/props` endpoint and compare against `PackageInfo.version`.
- **Store version detection requires network.** Offline users are not blocked and also cannot update — acceptable behaviour.
- **iOS iTunes lookup can lag** up to ~30 minutes after a new release is published. The modal will not appear until the lookup returns the new version.
