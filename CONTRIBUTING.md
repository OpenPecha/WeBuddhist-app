# Contributing

## Versioning (automatic — don't edit the version by hand)

CI bumps the app version from your **commit messages** / **branch names**:

| Bump | Commit starts with | or branch named |
| --- | --- | --- |
| **major** (`3.0.0`) | `feat!:` · `fix!:` · a `BREAKING CHANGE:` footer | `breaking/…` · `major/…` |
| **minor** (`2.10.0`) | `feat:` | `feat/…` · `feature/…` |
| **patch** (`2.9.3`) | anything else (`fix:`, `chore:`, …) | anything else |

**No convention → patch.** That's the only rule you need.

### Dev vs prod
- Merge to **`develop`** → the dev TestFlight build *previews* the next version (not saved).
- Merge to **`main`** → the version is bumped for real, shipped, and tagged.

So a change tested on dev and then shipped to prod bumps **once**, never twice.
