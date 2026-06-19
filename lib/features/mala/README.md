# Mala (Prayer-Bead Counter)

A per-mantra recitation counter. The user taps an arc of prayer beads; each tap
is a monotonic +1 that is persisted locally and synced to the backend as an
**absolute lifetime total**. Counting never decreases.

## Architecture

Clean architecture, Riverpod for DI/state:

```
data/
  datasources/
    mala_remote_datasource.dart   REST calls (dio)
    mala_local_datasource.dart    Hive store (LocalMalaState), namespaced by user
  models/
    accumulator_model.dart        JSON DTOs + toEntity()/toMalaCount()
  repositories/
    mala_repository_impl.dart     maps exceptions → Failure (fpdart Either)
domain/
  entities/
    mantra.dart                   Mantra, MantraText, AccumulatorMetadata; kBeadsPerRound = 108
    mala_count.dart               MalaCount (total, accumulatorId, beadImageUrl)
  repositories/mala_repository.dart
  usecases/mala_usecases.dart     GetCatalogue / GetAccumulatorDetail / Create / Update
presentation/
  providers/
    mala_providers.dart           all DI providers + user-id resolution
    mala_counter_notifier.dart    per-mantra counter (seed + increment)
    mala_sync_manager.dart        app-scoped background sync
  services/
    mala_sound_player.dart        bead-tap click (just_audio)
  screens/mala_screen.dart        screen layout (40% switcher / 60% counter+beads)
  widgets/
    mala_beads.dart               the tappable bead-arc CustomPainter
    mantra_switcher.dart          infinite looping carousel (swipe + ‹ › chevrons)
    mala_skeleton.dart            loading placeholder
```

## Backend API

Base dio (`dioProvider`). **All `/accumulators/*` routes require the bearer
token** — they are registered as protected in
`lib/core/config/protected_routes.dart` (`'/accumulators/'` catch-all). Without
it the user-scoped endpoints return **403**. The public preset catalogue is only
fetched by authenticated users, so the catch-all is safe.

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/accumulators/presets` | Catalogue of preset mantras (paged, `language`). |
| `GET` | `/accumulators/{parent_id}` | The user's detail for one preset. **404 ⇒ no accumulator yet ⇒ seed at 0.** |
| `POST` | `/accumulators/user` | Lazily create the user's accumulator (`{parent_id}`, starts at 0). |
| `PUT` | `/accumulators/user/{id}` | Push the absolute `current_count`. |

`mala_image_url` appears at both the accumulator and mantra level; it drives the
bead artwork (see below).

## Counting model

- **Monotonic absolute totals.** The client always sends the absolute lifetime
  total, and both sides take `max()`. Re-sending the same total is a no-op, so
  retries are always safe and counts reconcile across devices.
- **Seed-before-send.** `MalaCounterNotifier.seed()` fetches the server total
  and `max()`-merges with the local total *before* taps are enabled
  (`isSeeding`), so a stale low value is never sent.
- **`beadInRound = total % 108`, `rounds = total ~/ 108`** (`kBeadsPerRound`).
- Taps are blocked while `isSeeding`; a failed seed shows a retry
  (`seedFailed`).

### User-id resolution (important)

`mala_providers._resolveUserId()` reads the **persisted** `currentUserId`
(`StorageKeys.currentUserId`, written at login *before* auth state flips) and
only falls back to `userProvider.user?.id`. This avoids a race where the screen
is reachable (auth gate passes) but the async profile fetch hasn't populated
`userProvider` yet. The counter caches the resolved id (`_userId`) on a
successful seed so the synchronous `incrementBead` can persist taps.

The local store **and** the sync manager must use the *same* id (the counter
writes Hive taps keyed by it; the sync manager reads dirty entries by it), so
both resolve through `_resolveUserId` (the sync manager's `currentUserId`
callback is async).

## Sync (`MalaSyncManager`)

App-scoped (`malaSyncManagerProvider`, kept alive for the app lifetime),
observes lifecycle + connectivity. Reads dirty entries straight from Hive, so it
flushes even after the user leaves the screen.

- **Triggers:** launch, each tap (debounced 5s), round completion (immediate),
  background/pause, connectivity reconnect, screen-leave.
- **Flow per dirty preset:** create the accumulator once if `accumulatorId` is
  null (POST), then PUT the absolute total. On success, `max()`-merge the
  returned total into local `total`/`syncedTotal`.
- **Failure:** entry stays dirty; exponential backoff retry (cap 60s).
- Concurrent triggers collapse via an `_isSyncing`/`_dirty` guard.

## Local store (`MalaLocalDataSource`)

Hive box `mala_counts`, keys `userId:presetId`, value = JSON `LocalMalaState`
(`total`, `syncedTotal`, `accumulatorId`, `beadImageUrl`). `isDirty =
total > syncedTotal`. `pruneSynced` removes fully-synced entries (keeps dirty
tails). Opened once in app bootstrap via `MalaLocalDataSource.init()`.

## Bead artwork & caching

Resolution order in `MalaScreen`:
**accumulator detail `beadImageUrl` → preset/mantra `beadImageUrl` → drawn
gradient bead**. There is no bundled asset fallback: while the network image
loads, or whenever there's no URL or it fails to load, the painter draws a
gradient bead (`_drawDrawnBead`).

- **Preset preview source.** `Mantra.beadImageUrl` resolves to the
  **mantra-level** `mala_image_url` (`PresetMantraModel`) first, falling back to
  the accumulator-level one (`PresetAccumulatorModel`). The mantra-level image
  mirrors what the detail endpoint (`AccumulatorDetailModel.mala_image_url`)
  returns, so the pre-seed preview and the post-seed image share one URL — the
  URL doesn't change after seeding, so `MalaBeads` skips a second fetch and the
  bead doesn't flicker. (See `PresetAccumulatorModel.toEntity()`.)
- The detail image is threaded through `MalaCount → MalaCounterState →
  MalaBeads` so per-user bead customization works.
- It is **persisted** in `LocalMalaState.beadImageUrl` and surfaced into state at
  seed start (before/without network) so the correct bead shows offline on a
  cold start.
- `MalaBeads` loads via **`CachedNetworkImageProvider`** (on-disk cache), so the
  image bytes survive across launches and load offline.

## Bead input & feedback

Counting is triggered two ways over the bead region (`HitTestBehavior.opaque`),
both +1 and both blocked while seeding:
- **Tap** anywhere on the strand.
- **Right-to-left swipe** — a leftward drag past `_kSwipeDistance` (24px) or a
  leftward fling past `_kFlingVelocity` (200px/s), matching the strand's right→
  left motion. Left-to-right is ignored (counting is monotonic).

Each `incrementBead`:
1. `_sound?.play()` — `MalaSoundPlayer` plays `AppAssets.malaSound`
   (`assets/audios/mala-sound.wav`), loaded once and restarted from the top per
   tap so rapid counting stays responsive. Provider:
   `malaSoundPlayerProvider` (`Provider.autoDispose`, disposed with the screen).
2. `HapticFeedback.lightImpact()` (and `mediumImpact()` on round completion).

## Bead arc rendering (`MalaBeads` / `_MalaBeadsPainter`)

A `CustomPaint` strand that advances **forward only** (counting is monotonic).

- **Curve:** a quadratic Bézier from bottom-left (`a`) up to top-right (`b`) with
  the control point (`c`) **above the chord** so the arc bows *outward* (convex
  toward the bottom-right) — flat near the top-right, steepening toward the
  bottom-left. Drawn as the red mala thread (`threadColor`).
- **Even spacing:** beads are spaced by **arc length**, not by the Bézier
  parameter `t` (a Bézier isn't uniform in `t`, which would bunch/overlap beads
  at the ends). An arc-length lookup table (sampled over an extended `t` range)
  maps a bead's position → `t`, so on-screen spacing is constant and the strand
  fills out to the edges.
- **One gap:** a single fixed gap (the counting point, right-of-centre) where
  the red thread shows through. Implemented by pushing beads right of the focal
  slot by `_gap` bead-steps via a `_smoothstep`, so the front-right bead glides
  smoothly *through* the gap on a tap.
- **Animation:** on each increment the strand slides one bead **right → left**
  (the front-right bead crosses the gap to join the left pile, a new bead enters
  from the top-right). `AnimationController` 280ms, `Curves.easeOut`, forward
  only — never `reverse()`.

### Tuning knobs (all in `_MalaBeadsPainter`)

| Constant | Meaning | Current |
| --- | --- | --- |
| `_radiusFactor` | bead radius as a fraction of width | `0.075` (diameter ≈ 15% of width) |
| `_spacingFactor` | centre-to-centre spacing × radius | `2.0` (touching) |
| `_focalT` | arc position (0..1) of the gap | `0.56` |
| `_gap` | empty bead-steps of thread at the gap | `1.0` |
| `_from` / `_to` | candidate bead indices drawn (rest skipped/clipped) | `-9 / 9` |
| `a`, `c`, `b` | Bézier points (overall curvature) | see `paint()` |

> Note: a `canvas.clipRect(...)` line exists in `paint()` to cut overflow at the
> edges; toggle it depending on whether beads should be hard-cut at the bounds.

## Screen layout (`MalaScreen`)

Below the app bar: **40%** `MantraSwitcher` — an **infinite looping carousel**
(an unbounded `PageView` seeded at `_loopBase * length + index`, mapped back
with `page % length`); swipe or tap the chevrons and it wraps endlessly
(last → first, first → last). The screen owns `_index`; the carousel reports
settles via `onIndexChanged`. With one mantra it locks (no swipe, chevrons
disabled). **60%** `_CounterBlock` (`n/108`, rounds) above the `MalaBeads` arc. States: skeleton (loading), error+retry (catalogue or seed
failure), data.

## Analytics

`mala_screen_opened`, `mala_mantra_switched`, `mala_round_completed`,
`mala_synced` (see `AnalyticsEvents`).

## Tests (`test/features/mala/`)

- `mala_counter_notifier_test.dart` — seed merge, offline-tail preservation,
  no-op while seeding, monotonic increment, round completion, fresh-install
  seed-at-0.
- `mala_sync_manager_test.dart` — create-once-then-update, absolute-total PUT,
  `max()` adoption, dirty-on-failure, logged-out no-op, per-user namespacing.
- `mala_beads_test.dart` — tap increments, right-to-left swipe increments,
  left-to-right doesn't, and disabled beads ignore both.

`currentUserId` callbacks are async (`Future<String?> Function()`) in both the
notifier and sync manager.
