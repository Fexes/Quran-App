# Recommended Next Steps

Last updated: 2026-07-10

This is the ordered implementation plan for the next product phase. Steps are executed in sequence because later offline, search, backup, and learning features depend on the source and preference foundations established first.

## Delivery rules

- Preserve the current offline Quran reader, prayer, Hadith, and Azkar journeys.
- Keep religious content traceable to a named source and edition.
- Never machine translate Quran, tafsir, Hadith, or Azkar content.
- Store user-created data locally by default and make export or deletion explicit.
- Run focused analysis and existing checks after every step. Do not add tests unless requested.
- Update `PROJECT_TRACKER.md` when a step ships.

## 1. Content provenance, provider access, and cache policy

Goal: make every bundled or downloaded religious-content resource traceable and keep provider data only for the period its terms permit.

Implementation:

1. Extend `ContentSource` with content kind, provider, edition, language, direction, publisher, revision, license URL, retrieval mode, cache policy, and review status.
2. Add an app-owned source manifest under `assets/data/content_sources/` covering Quran Arabic, bundled English, tafsir, translation catalog/downloads, interlinear words, timings, Hadith, and Azkar.
3. Add reusable cache-policy helpers with a seven-day maximum for Quran Foundation derived responses.
4. Timestamp translation catalogs, downloaded translation chapters, interlinear pages, and timing results.
5. Reject expired records during reads and remove stale completion markers so downloads can refresh safely.
6. Keep Quran Foundation requests behind repository fetcher boundaries. Do not place client secrets in the app. Production authenticated access must use an approved backend or provider-supported public flow.
7. Surface attribution and expiry metadata from repository state to download and reader screens.
8. Replace or formally approve any bundled edition whose redistribution rights remain unresolved before release.

Primary files:

- `lib/core/content/content_source.dart`
- `lib/core/content/content_cache_policy.dart`
- `assets/data/content_sources/quran_sources.json`
- `lib/features/quran/data/stores/quran_translation_store.dart`
- `lib/features/quran/data/stores/quran_interlinear_words_store.dart`
- `lib/features/quran_audio/data/stores/quran_word_timing_store.dart`
- Quran translation, interlinear, timing repositories and download UI

Acceptance checks:

- Every Quran content type has visible source, edition, and license metadata.
- Expired provider data is not returned as valid offline content.
- A full-cache marker cannot remain valid after its provider cache window expires.
- No API secret is bundled in Dart code or assets.
- Release checklist clearly identifies any source still awaiting written approval.

## 2. Independent language and content preferences

Goal: stop one language choice from unexpectedly changing unrelated content.

Implementation:

1. Create independent settings for UI locale, Quran translation editions, primary continuous translation, tafsir edition, word-meaning language, Quran audio meaning language, Hadith language, and Azkar language.
2. Migrate existing selected translation and visibility preferences without losing user choices.
3. Make each feature read only its own preference.
4. Allow System UI language without using it to overwrite an explicitly selected religious-content language.
5. Suggest suitable editions once from device locale during onboarding, then remember explicit choices.

Primary files:

- `lib/core/storage/settings_store.dart`
- settings entities, cubit, state, and pages
- Quran reader, audio, Hadith, and Azkar cubits

Acceptance checks:

- Hiding a translation does not remove its selected edition.
- Changing app language does not silently replace Quran, tafsir, Hadith, or Azkar editions.
- Each preference survives restart independently.

## 3. First-run setup and recovery journey

Goal: take a new user from install to accurate prayer times and a readable Quran experience with minimal friction.

Implementation:

1. Add a resumable onboarding flow for language, Quran translation, prayer location, calculation method, madhab, notifications, and reading intent.
2. Explain why location and notification permissions are needed before the platform prompts.
3. Offer city search/manual location when permission is denied.
4. Preview calculated prayer times and the selected translation before completion.
5. Store onboarding progress and allow every choice to be changed later in Settings.
6. Route returning users directly to Home and provide recovery cards for incomplete prayer or translation setup.

Acceptance checks:

- Denying location never traps the user.
- Prayer times are never fabricated while setup is incomplete.
- Onboarding can be interrupted and resumed.
- All onboarding decisions are editable later.

## 4. Reliability baseline and release harness

Goal: make regressions visible and platform startup safe before larger feature work.

Implementation:

1. Align stale fake repositories with current production interfaces when test editing is authorized.
2. Isolate plugin initialization behind injected adapters so widget startup can use safe in-memory implementations.
3. Add explicit empty, retry, permission-denied, offline, and expired-cache states to critical screens.
4. Add non-sensitive diagnostic logging for content source, cache age, prayer configuration, and failed imports.
5. Maintain a manual smoke checklist for Home, reader, translation switching, downloads, prayer, bookmarks, and resume reading.

Acceptance checks:

- `flutter analyze lib` is clean.
- Existing focused production checks pass.
- App startup does not require a simulator-only plugin call in reusable UI code.
- No new test files are authored without explicit approval.

## 5. Reading goals, streaks, Khatma pacing, and plans

Goal: turn reading into a clear, forgiving daily journey.

Implementation:

1. Add local reading-session and goal entities based on verses, pages, or minutes.
2. Record progress from real reader movement, not screen opens.
3. Add daily goal progress and continue-reading actions to Home.
4. Calculate streaks using local calendar days with one configurable grace rule.
5. Add Khatma targets with start date, target date, daily page requirement, catch-up pacing, pause, and completion.
6. Add structured plans such as 30-day Quran, selected Surahs, and user-defined page ranges.
7. Exclude private learning analytics from general content caches and include them in user-data backup.

Acceptance checks:

- Reopening the same verse does not inflate progress.
- Missed days recalculate pacing without losing completed work.
- Time-zone changes do not duplicate a daily streak entry.
- Home always offers one obvious next reading action.

## 6. Hifz learning system

Goal: support memorization, review scheduling, and weak-area discovery without overwhelming the reader.

Implementation:

1. Add Hifz collections made from Surahs, verse ranges, pages, or Juz.
2. Add learn, review, and mastered states per verse.
3. Add an SM-2 style review scheduler with Again, Hard, Good, and Easy outcomes.
4. Add hide, reveal, first-word hint, repeat audio, and verse-range looping.
5. Calculate due count, retention, weak Surahs, repeated failures, and review load.
6. Add a focused Hifz dashboard and a reader mode that reuses current Quran and audio infrastructure.

Acceptance checks:

- Every rating produces a deterministic next-review date.
- Hidden text remains accessible through an intentional reveal control.
- Audio loops stop cleanly when leaving Hifz mode.
- Weak-area analytics come from actual review results.

## 7. Bookmark collections, ayah notes, and sharing

Goal: make saved verses useful for study and personal reflection.

Implementation:

1. Extend bookmarks into named collections with color, icon, sorting, and optional description.
2. Add private notes linked to exact verse keys and optional translation edition IDs.
3. Add collection filters, full-text note search, and recent activity.
4. Add native text sharing with Arabic, selected translations, citation, and source attribution.
5. Add share-card rendering with explicit content selection and accessible contrast.
6. Preserve existing bookmarks through a storage migration.

Acceptance checks:

- Existing bookmarks appear in a default collection.
- Notes never alter source Quran content.
- Shared output identifies Surah, ayah, translation edition, and translator.
- Users can share text without creating an image.

## 8. Local backup, restore, merge, and privacy controls

Goal: protect user progress without requiring an account.

Implementation:

1. Define a versioned JSON backup schema for settings, reading state, goals, Hifz, bookmarks, notes, prayer tracking, and fasting tracking.
2. Exclude downloaded religious content and audio that can be fetched again.
3. Add encrypted export, file import, schema validation, preview, replace, and merge flows.
4. Resolve duplicate records using stable IDs and updated timestamps.
5. Add erase controls by data category plus a full local-data reset.
6. Show backup date, app schema version, included categories, and restore result.

Acceptance checks:

- Importing malformed or newer unsupported data cannot overwrite local data.
- Merge is deterministic and previewed before writing.
- Erase controls state exactly what is retained.
- No private user data leaves the device without an explicit export action.

## 9. Prayer, Qada, cycle-pause, and missed-fast tracking

Goal: provide respectful private worship tracking alongside accurate prayer times.

Implementation:

1. Add daily prayer completion with on-time, late, missed, Qada, congregation, and exempt states.
2. Add Qada totals and an adjustable repayment plan without assigning religious rulings.
3. Add private cycle-pause ranges that suppress prayer reminders and streak penalties when enabled.
4. Add Ramadan and voluntary fasting logs with missed-fast and make-up counters.
5. Add weekly/monthly summaries focused on reflection rather than competitive scoring.
6. Include all tracker data in backup and erase controls.

Acceptance checks:

- Exempt days do not count as missed.
- Date-boundary and timezone changes retain the intended local worship day.
- Reminder suppression follows the selected pause interval.
- Sensitive data has no sharing or analytics path by default.

## 10. Juz, Hizb, Rub, and Mushaf-page navigation

Goal: support the ways users actually navigate printed and memorized Quran structure.

Implementation:

1. Add indexed Juz, Hizb, Rub al-Hizb, Sajdah, Manzil, and Mushaf-page boundaries to the repository model.
2. Add browse tabs and jump controls alongside Surah navigation.
3. Show structural markers in verse and continuous modes without clutter.
4. Persist the exact structure and reading mode in resume state.
5. Make search results and deep links open the correct page and focused verse.

Acceptance checks:

- Every page from 1 to 604 opens deterministically.
- Juz and Hizb starts match the approved Quran data source.
- Resume reading returns to the same mode, page, and focused verse.
- Navigation works offline.

## 11. Additional worship utilities

Goal: add complementary tools only after core reading and prayer journeys are dependable.

Implementation order:

1. Curated Duas with source, authenticity/reference, categories, favorites, and offline search.
2. The 99 Names with Arabic, transliteration, reviewed meanings, references, and audio where licensed.
3. Zakat calculator with explicit assumptions, nisab basis, asset categories, liabilities, currency date, and disclaimer.
4. Ramadan dashboard with Suhoor/Iftar times, fasting log, Quran goal, and last-ten-nights plan.
5. Private achievements tied to meaningful app actions, with the ability to disable them.
6. Mosque locator using OpenStreetMap attribution, cache limits, map handoff, and location-denied fallback.

Acceptance checks:

- Religious content remains sourced and editioned.
- Financial calculations show all inputs and assumptions.
- The app never claims a mosque result is exhaustive.
- Gamification can be disabled and never penalizes exemptions.

## 12. Localization and translation platform

Goal: make language support accurate, transparent, scalable, and pleasant for multilingual reading.

Implementation:

1. Replace hardcoded user-facing English with ARB keys and add System language support.
2. Add per-edition metadata: ISO language, endonym, script, direction, translator, publisher, license, revision, source URL, checksum, and footnote support.
3. Allow multiple selected translations in verse mode while keeping one primary translation in continuous mode.
4. Replace all-6236-verse downloads with per-Surah resumable packs and optional full-pack orchestration.
5. Show pack size, source revision, download date, expiry, progress, retry, update, and delete actions.
6. Make Quran search resource-aware and rebuild indexes when translation packs change.
7. Suggest a locale-matched translation once and never overwrite an explicit choice.
8. Add curated Urdu editions and a configurable Nastaliq-capable Urdu reading font after source and font-license review.
9. Keep Quran, tafsir, Hadith, and Azkar translations human-authored and reviewed. Machine translation is limited to non-religious app interface drafts and requires human review before release.
10. Add bidirectional layout review for Arabic and Urdu, including mixed Arabic/Latin citations, numerals, dialogs, download lists, and share output.

Acceptance checks:

- Translation picker displays endonym, translator, edition, direction, source, and license.
- Two or more translations can render together in verse mode without losing edition attribution.
- Downloaded packs resume after interruption and expired packs are clearly marked.
- Search identifies which translation matched and updates after pack changes.
- Explicit content choices survive locale changes.
- All supported screens pass an RTL and large-text manual review.

## Completion sequence

| Order | Step | Dependency | Status |
| --- | --- | --- | --- |
| 1 | Content provenance and cache policy | None | Implemented; external release approvals remain open |
| 2 | Independent language preferences | Step 1 metadata | Implemented |
| 3 | First-run setup | Step 2 settings | Implemented |
| 4 | Reliability baseline | Steps 1 to 3 | Production safeguards implemented; test edits deferred by instruction |
| 5 | Reading goals and plans | Reliable reader state | Implemented |
| 6 | Hifz | Reading and audio state | Implemented |
| 7 | Collections, notes, sharing | Edition metadata | Implemented |
| 8 | Backup and privacy | User schemas from steps 5 to 7 | Implemented |
| 9 | Worship tracking | Backup/privacy model | Implemented |
| 10 | Structural navigation | Approved Quran metadata | Implemented |
| 11 | Additional utilities | Core journeys stable | Implemented |
| 12 | Localization and translation platform | All source and preference foundations | Implemented; native-language, font, edition-rights, and manual RTL release gates remain open |
