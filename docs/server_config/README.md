# Server-Side Configuration for Deep Linking

When you get control of `webuddhist.app`, you need to host these files to enable Universal Links (iOS) and App Links (Android).

## 1. Apple Universal Links (iOS)

**File:** `apple-app-site-association` (No extension!)

**Required Change:**
- Replace `<REPLACE_WITH_TEAM_ID>` with your Apple Team ID (found in Apple Developer Portal).

**Hosting:**
- Upload to: `https://webuddhist.app/.well-known/apple-app-site-association`
- Content-Type must be `application/json` (even without extension)

## 2. Android App Links

**File:** `assetlinks.json`

**Required Change:**
- Replace `<REPLACE_WITH_SHA256_FINGERPRINT>` with your release keystore SHA256 fingerprint.
- To get SHA256: `keytool -list -v -keystore my-release-key.keystore`

**Hosting:**
- Upload to: `https://webuddhist.app/.well-known/assetlinks.json`
- Content-Type must be `application/json`

## 3. Switch App Code

Once these files are hosted and verified:

1. Go to `lib/features/plans/services/plan_share_service.dart`
2. Change the scheme back to HTTPS:
   ```dart
   return 'https://webuddhist.app/plans/invite?planId=$planId';
   ```
