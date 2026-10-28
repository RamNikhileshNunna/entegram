# Memories and stories

Entegram now uses local, deterministic curation inspired by the daily memories,
people/place groupings and highlight collections in Google Photos and Immich.
It does not reproduce either product's proprietary models or visual ranking.
All grouping uses metadata already decrypted from the user's Ente library.

## Source review and resulting changes

The review covered the Dart application, authentication and crypto boundaries,
metadata decryption, API client, Isar models, sync, media services, feed and both
viewers, plus the Android/iOS/Linux entry points and build configuration.

| Previous behavior | Replacement |
| --- | --- |
| A shuffled pool was copied repeatedly into a 5,000-card feed | A finite unique feed, stable ordering during sync, filters, explicit pagination and an end state |
| Each rebuild cleared the memory table and assigned new ids | Atomic signature-based updates retaining ids and skipping unchanged records |
| "On this day" included ±7 days and only ten previous years | Exact local calendar dates over every available year; broader flashbacks have separate labels |
| The most photographed person was assumed to be the owner | No inferred owner identity or invented "You and…" titles |
| People pairing scanned every pair and allowed redundant cards | Inverted per-photo membership; together stories contain both named people in every slide |
| Trips could merge through home visits or use a vacation burst as home | Home confidence from distinct dates over a month; home visits, long gaps and duration limits split trips |
| Every photo and many originals were prefetched eagerly | Lazy thumbnails, bounded neighbours, byte-limited original caches and visibility-aware video playback |
| Story loads could complete after navigation; image and video timers competed | Request generations, keyed media states, guarded navigation and actual video position/end events |
| Releasing a hold could advance; backgrounding did not pause reliably | Monotonic pointer timestamps, separate hold/zoom/manual/background/route pause reasons |
| Archive progress came from the newest locally stored file | Separate persistent backfill cursors; recent-priority inserts cannot skip old history |
| Removing a photo from one album deleted its shared library row | Persisted album links retain the file and a usable encrypted key until its last link is removed |
| Per-photo people labels repeatedly scanned the database | One shared people stream and an inverted file index |

Authentication, SRP/Argon2 and encrypted media protocols were retained. Database open errors now surface without silently deleting the local library. The Isar file schema adds embedded album links with ciphertext key slots.
A one-time v3 cursor replay verifies memberships and recovers files previously
lost locally through album unlinking. Legacy cached files remain available while
the replay runs; unconfirmed obsolete rows are removed after all albums finish.
Only derived memories are replaced on the first v2 curation rebuild.

## Curation rules

`MemoryEngine` is a database-free function with an injected date. `MemoryMapper`
reads one file/people snapshot and sends a plain data object to a worker using
Flutter's `compute`. Neither the database handle nor the widget tree crosses
that boundary. Concurrent rebuild requests coalesce and catch up with a final
snapshot before completing.

Eligible files have a valid capture timestamp, are not deleted or in the future,
and are photos, live photos or videos. Identical content hashes are deduplicated.
Hidden-person files (including known duplicate hashes) and filenames clearly
indicating screenshots, screen recordings or receipts are excluded. Filename
filtering is a heuristic, not a visual classifier.

- **On this day:** the exact month/day in each earlier year, including archives
  older than ten years. February 29 is never rolled into another date.
- **Month flashbacks:** the same calendar month in earlier years, labelled as a
  month rather than claiming that every slide was taken today.
- **Recent:** the previous complete Monday–Sunday week and previous calendar
  month, with start-inclusive/end-exclusive boundaries.
- **People:** named, visible people with at least four photos. Pair memories need
  at least three photos genuinely shared by both people. Large crowd photos
  do not generate a combinatorial set of relationship stories.
- **Trips:** a home area requires at least five distinct photo dates spanning
  30 days. An away event needs four located photos over at least four hours,
  more than 60 km from home. An observed return home, a gap over 48 hours, or
  a 21-day span separates events. No city names are invented without geocoding.
- **Seasons:** completed three-month seasons with GPS-based hemisphere labels;
  December and the following January/February form one season. Without GPS,
  neutral calendar-quarter labels are used.
- **Year highlights:** a sufficiently populated earlier year, sampled across
  dates rather than dominated by one burst. Small libraries get day collections
  or a clearly labelled latest-moments fallback.

Selection prefers specific/relevant collections, caps output at 80 memories and
24 slides per memory, limits broad categories and photo reuse, and requires
novel content for overlapping collections. Covers are distinct. Sampling spreads
across capture dates; resolution, orientation and media type are modest cover
heuristics. There are no face-confidence, aesthetic, CLIP or visual-near-duplicate
scores in the available metadata, so the engine does not pretend to use them.

The UI distinguishes eight categories through the versioned signature while
preserving the existing persisted three-value enum. Category round-robin and a
stable daily hash diversify the story rail. Existing feed positions survive
background updates; refresh deliberately recalculates the ordering. There is no
synthetic infinite scroll or repeated-memory padding.

## Playback and responsiveness

`StoryPlayback` owns navigation, async request generations, empty-memory skipping,
retryable errors and completion. `StoryViewer` owns the photo clock and pause
reasons; `StoryMedia` owns one keyed image/video resource. Photos start timing
on their first rendered frame. Video progress follows the player's actual
position and completion, so downloading or buffering does not consume a fake
five-second/60-second timer. Hold, zoom, manual pause, app backgrounding and
opening an original all pause playback. Buttons are outside the media gesture
listener, preventing double navigation. A bundle swipe does not mark skipped
stories as watched. Seen fingerprints include the caption and selected slide ids and are
persisted per account/server; changed selections become unread again.

The feed uses lazy sliver rows, one column on phones and two on wide layouts,
with a maximum readable content width. Headers, captions, story cards and filter
controls accommodate enlarged text. Feed thumbnails have decode-size limits;
originals are fetched only in viewers. The thumbnail cache is limited to 256
entries/24 MiB with eight network slots; originals are limited to 12 entries/
64 MiB. The Flutter decoded-image cache is capped at 64 MiB. These are cache
budgets, not a bound on all app/codec memory. Gallery neighbours do not autoplay
videos or eagerly decode full-size originals. Unsupported image containers keep
an available thumbnail instead of replacing it with a broken original.

Disk media caches are account/server scoped and removed on sign-out along with
seen state, cursors and local database contents. They are not yet subject to a
storage quota. Legacy flat cache files are also removed on sign-out; the v2 services never read them.
The pre-existing session-key storage still uses SharedPreferences; migrating
those secrets to platform secure storage is a separate security change, not
part of the grouping/playback rewrite.

## Validation and practical limits

Run from the repository after activating the cloud toolchain:

```sh
source /workspace/.entegram-setup/env.sh
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter build apk --release --no-pub
```

Tests cover calendar/leap/year boundaries, hidden people and duplicates,
co-occurrence precision, home/trip separation, hemispheres, balanced/bounded
sampling, determinism, stale async loads, empty/error stories, hold/manual and
lifecycle pauses, real native-Isar upserts and file streams, persisted archive
recovery, pagination retries and enlarged-text phone/tablet layouts. Native
Isar integration tests use the dependency's bundled Linux library and are
explicitly skipped on other platforms until their native test-library paths
are configured.

A real Ente account and photo library are needed to validate end-to-end sync,
metadata completeness, codecs and native video behavior on a device. Cloud
widget tests and an APK build do not establish device frame rates, video-codec
support, iOS readiness or equality with Google Photos/Immich's ML results.

### Opt-in self-hosted account verification

On Linux with the Flutter dependencies installed and `ffprobe`/`ffmpeg` on the
path, run `python3 tool/verify_selfhost.py`. Enter the endpoint, email and password
at its prompts. The password is hidden and passed only in the child process
environment. The checker uses the production authentication, crypto, sync and
media services with native Isar; the feed and viewer run in Flutter's widget
harness. It downloads the complete metadata archive, compares active collection
links with local files, checks memory invariants and samples actual encrypted
media. Server activity is limited to authentication and reads.

The runner discards raw framework output, displays only explicit sanitized
checkpoints, and removes its temporary database, report and decrypted media on
exit. It does not configure the installed app or store a reusable account
session. A missing completion marker or any failed checkpoint returns a nonzero
exit code. This file is named `selfhost_live_check.dart` so ordinary `flutter
test` never attempts an account login. Android hardware video playback still
requires a device or emulator.
