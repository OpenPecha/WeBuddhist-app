# Contributing

## Versioning & releases

The app version (`version:` in [`pubspec.yaml`](pubspec.yaml), e.g. `2.9.2+92`)
is **bumped automatically** by CI when changes are released to **production**
(a push/merge to `main` runs the *🚀 Release • Prod* workflow). You do **not**
edit the version by hand.

That single bump propagates everywhere — there is no other place to update:

- **Play Store** build → `versionName` (`android/app/build.gradle.kts`)
- **App Store / TestFlight** build → `CFBundleShortVersionString` (`ios/Runner/Info.plist`)
- **In-app Settings page** → the "Version X.Y.Z" label (`PackageInfo` → `appVersionLabelProvider`)

All three read the version from `flutter build --build-name`, which CI feeds
from the bumped `pubspec.yaml`.

> Dev/TestFlight builds off `develop` do **not** bump the version — they reuse
> the current version name with a fresh build number. The semantic version only
> advances on a production release.

### How the bump size is decided

CI inspects every commit (and merged branch name) since the previous release tag
and picks the **highest** bump it finds. The version is `MAJOR.MINOR.PATCH`:

| Bump  | Version part | Triggered by a commit… | …or a branch named |
| ----- | ------------ | ---------------------- | ------------------ |
| **major** | `X` → `X+1.0.0` | `feat!:` / `fix!:` (any `type!:`), or a `BREAKING CHANGE:` footer | `breaking/*`, `major/*` |
| **minor** | `Y` → `X.Y+1.0` | `feat:` / `feat(scope):` | `feat/*`, `feature/*` |
| **patch** | `Z` → `X.Y.Z+1` | `fix:`, `perf:`, `refactor:`, `chore:`, `docs:`, … | anything else |

**If no convention is detected at all, the release still ships as a `patch` bump.**
So the conventions are how you *opt into* a bigger bump — nothing breaks if they
are missed, you just get a patch.

### Commit message format ([Conventional Commits](https://www.conventionalcommits.org))

```
<type>[(optional scope)][!]: <short summary>

[optional body]

[optional BREAKING CHANGE: <description>]
```

Examples:

```
feat: add verse-of-the-day widget          # → minor (2.9.2 → 2.10.0)
fix(timer): stop preset card overflow       # → patch (2.9.2 → 2.9.3)
feat!: drop legacy onboarding route         # → major (2.9.2 → 3.0.0)
chore: bump dependencies                     # → patch
```

Common `type` values: `feat`, `fix`, `perf`, `refactor`, `docs`, `style`,
`test`, `build`, `ci`, `chore`.

### Branch naming

Use a `type/short-description` prefix; it is used as a fallback signal when the
commit subjects on a PR are not conventional:

```
feat/verse-of-day        feature/new-routine     # → minor
fix/login-crash          fix/ci-ios-archive       # → patch
breaking/remove-v1-api                            # → major
```

### Build numbers

The build number (the `+N` after the version, and the store build number) is set
by CI as `github.run_number + BUILD_NUMBER_OFFSET` (repo variable, default `100`)
and is always unique. You don't manage it manually.
