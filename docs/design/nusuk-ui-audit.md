# Whole-App UI Audit

Date: 12 October 2026. Status: code-led redesign and source audit complete. Visual acceptance of the new design is not established by this report.

## Required Outcome

Reimagine every existing screen, menu, and bottom sheet using Nusuk's calm service-oriented visual language. Preserve functionality and saved data. Completely remove Guides. Prefer flat sections and rows, reserve cards for genuinely framed tools and repeated items. Minimize artificial sheet height. Keep Arabic reading, translation direction, audio controls, accessibility, and offline behavior intact.

Latest direction: proceed from code only. Keep both Combined and Separated Quran layouts. Retain only Light and Dark appearances, make Dark the monochrome counterpart of Light, use both prominent and subtle imagery, move infrequent Arabic script preferences into main Settings, and simplify reader and playback settings. This supersedes the earlier device-verification workflow; do not require another phone session to make source progress.

## Current Code-Led Pass

- Reduced the theme catalog to Light/Dark. Retired dark selection resolves to Dark, retired light selection to Light; saved reading, language, and font preferences are retained.
- Generated and bundled original 1200px architectural artwork (177,311 bytes). Home now displays prayer data over a full-width image; shell headers receive a faint background crop. No runtime image request is added for this artwork.
- Main Settings is organized as Appearance, Reading & language, and Downloads & data. Infrequent choices open compact sheets. Language catalog work starts only when its sheet opens. Error/retry states replace an indefinite loading spinner.
- Moved Arabic script, tafsir edition, and content attribution out of the Quran reader popup and into Settings. Reading settings retain both layouts, Arabic size, translation switch/language, conditional translation size, and audio follow.
- Quran/Hadith/Azkar now share the same release-to-commit reading-size control. The interface-size settings and playback-speed slider also preview locally before committing.
- Playback uses plain rows, an available-only translation toggle, conditional voice choice, speed, and expandable repeat mode/count/range/after-action controls. Repeat semantics and audio engine remain unchanged.
- Library uses familiar text tabs and flat collection/category rows. Prayer tools, alert switches, and schedule entries lose nested rounded frames.
- New main-settings labels are localized in English, Arabic, and Urdu. Retired theme labels were removed.
- Existing checks: analysis passes; 59 audio/repeat/floating-controls/home tests pass; 17 reader tests pass after updating three existing UI expectations. No new test cases added. The test runner emitted a Dart finalizer diagnostic while still reporting success, so device runtime behavior is not inferred from those results.
- No device/simulator inspection or installation was performed in this pass. All phone observations below are historical and predate these changes.

## Utility Screen Pass

- Reading Journey now starts with the daily goal and streak, then Khatma and plans, with Hifz as a compact destination row. Progress sections are unframed. Goal, custom-plan, and duration editors use the shared content-fit sheet.
- Hifz uses a fixed header with an add action, an unframed review summary, and compact collection rows. The collection editor uses the shared sheet. Review removes the nested blank card, uses wrapping hint/reveal controls and monochrome ratings, and bounds the completed-session counter.
- Prayer Journal uses flat sections and full-width status fields with separate prayer labels, so labels no longer compete with the dropdown. Qada, private-pause, and fasting editors use the shared sheet. Date, reminder, exemption, deletion, and private-record semantics remain intact.
- Backup is organized into unframed privacy, encrypted-transfer, and erasure sections. Destructive confirmations remain dialogs with explicit warnings. Password, erase, and restore dialogs scroll when space is constrained. Form-owned text controllers remain alive through route dismissal; password length, confirmation, ERASE matching, encryption, merge/replace, and category boundaries are preserved.
- Duas and Divine Names use lazy slivers rather than an eagerly built collection or fixed-height nested grid. Names can display full meanings and references without truncation. Dua of the day and source information are expandable. Favorites and learned-state keys are unchanged.
- Ramadan, Zakat, mosque search, and achievements use unframed sections, restrained progress indicators, and compact actions. Achievements uses monochrome Material icons rather than emoji. Financial formulas, prayer calculations, privacy choices, map attribution, and external handoff behavior were not redesigned.
- Utility headers reuse the bundled subtle architectural background. No added network dependency or image fetch is needed.
- Source review covered all eleven utility screens, their router entries, and the existing shared sheet implementation. Whole-library analysis and diff whitespace checks pass. Twenty-three existing route, Tasbieh, prayer-time, and Home checks pass; these are navigation/domain regressions, not visual coverage of the newly changed utility screens.
- No new tests, device/simulator sessions, personal record edits, export/import, or destructive actions were performed. Utility keyboard and large-text behavior were inspected in source, not visually verified.

## Downloads And Personal Reading Pass

- Downloads now uses a lazy, unframed list with compact reciter/language rows, visible full-download/delete actions, and wrapping file-count summaries. Text/tafsir availability futures are reused instead of recreated on every audio-progress rebuild. Delete confirmation still respects the selected Arabic or translation scope.
- Quran/tafsir progress sheets use the shared opaque content-fit sheet. Completion checks route ownership before navigating, so a dismissed download cannot pop the screen underneath. Reader translation/word-cache sheets also have retry and route-ownership guards. Existing in-flight repository request cancellation semantics are unchanged.
- Onboarding keeps all six steps, consent choices, defaults and persistence. It now uses an unframed image header, the shared searchable translation picker, a cached prayer preview, and visible catalog/city retry and empty states.
- Translation management uses a lazy edition list, visible offline actions, expandable full attribution metadata, and safe download completion/error cleanup. Bookmarks now have a colored collection shelf, instant search/filtering, sort and move actions, and validated collection creation. Notes has category filters, date groups, sorting, a persistent new-note action, and a save-before-dismiss editor. See `bookmarks-notes-redesign.md` for the 2026-10-12 redesign and its evidence boundary.
- Quran, Hadith, Azkar and Notes share a form-owned note editor. Controllers no longer expire during modal exit animations. Quran still rejects empty notes; Hadith/Azkar still allow saving an empty value to clear an existing note.

## Final Source Audit

- Checked the route inventory, five shell destinations, their active sheets/popups, shared providers and input lifetimes. The unused legacy interlinear startup gate is not an active destination and was not reintroduced.
- Both Quran layouts remain. Existing Arabic script, font-size, word-color, translation-direction, selection, next-surah and audio-follow paths are retained. Fixed reader/header heights now grow with interface text scale; scrollbar positioning accounts for the actual header height and safe area, bounded by the available viewport.
- Corrected dark-theme contrast for scrollbar previews, the jump action and the selected calendar day. Search match text now respects text scale; RTL secondary search text and HadeethEnc translations use the existing translation direction behavior.
- Hadith/Azkar navigation popups scroll above the keyboard. Chapter/category selection uses expanded menus rather than clipped fixed-height chips. The Hadith popup captures its owning cubit before creating the separate route. Library selected-item actions use a bounded horizontal row under the title, with matching scroll clearance and safe-area handling.
- Prayer permission rationales use scrollable dialogs without nested panels. Qibla bearing/reference and calendar metadata are unframed; sensor calibration, prayer calculation and calendar conversion are unchanged. Calendar arrows have named tooltips. Search filters and chapter strips accommodate larger text, and bottom navigation grows with label height.
- The bundled artwork and local font/license paths are registered and present. Guides have no remaining route, feature or localization references. No new runtime asset download or dependency was added in this pass.
- No new tests, device/simulator sessions, installs, live downloads, backup exports/imports, notifications, personal record mutations or destructive actions were performed in this code-only continuation.

## Evidence Boundary

- Public Nusuk screenshots establish the reference direction, not private design tokens or proprietary fonts.
- Manrope is licensed under OFL and included locally. It is not claimed to be Nusuk's actual font.
- Route inventory is checked against `lib/app/router/app_router.dart` and the five shell destinations.
- Source checks use the code graph plus direct reads. Shared-token changes alone do not establish screen-specific completion.
- The mirrored iPhone initially showed an installed Search screen. That was baseline evidence, not proof that the current worktree had been installed.
- Installation of an earlier local build was approved. Any later device checks must identify the actual build and inspected screen; they are outside the latest code-only direction.
- No simulator runtime download and no destructive data action are authorized by this audit.

## Shared Findings And Changes

| Finding | Change | Status |
| --- | --- | --- |
| Ordinary surfaces inherited borders, rounded framing, and shadows | Neutral opaque backgrounds, 8px repeated-item corners, no default border or shadow | Implemented and source reviewed |
| Many interface labels used very heavy weights | Manrope chrome, medium titles and labels; Quran reading spans excluded from broad weight changes | Implemented; script choices retained |
| Bottom navigation covered the scroll viewport | Navigation is a bottom sibling; audio floats above it | Implemented; text-scale sizing reviewed |
| Shell lists always reserved large audio space | Bottom content allowance depends on actual audio dock visibility | Implemented; active/inactive paths reviewed |
| Sheets reserved 72-90% height irrespective of content | Shared content-fit `AppSheet`, bounded scrolling, safe area, keyboard allowance, close button | Applied to active sheets; confirmations remain scrollable dialogs |
| Reader and Downloads duplicated the translation picker | One shared flat, searchable picker with selected/download state and cached status checks | Implemented; also reused by onboarding |
| Open Hadith/Azkar settings switches did not keep local visual state | Settings sheet tracks toggle changes while forwarding existing callbacks | Implemented and source reviewed |
| Library tools used large promotional tiles | Flat icon, title, subtitle, and destination rows | Implemented and source reviewed |
| Guides conflicted with requested scope | Removed destination, source code, artwork, data directories, generator tools, and localization labels | Source removal checked |

## Screen And Overlay Inventory

All rows retain their original functional scope. Status below describes the current source, not historical phone screenshots or artistic approval.

| Screen | Specific work or overlays | Current status |
| --- | --- | --- |
| Home | Unframed prayer overview and reading entry, compact shortcuts, fixed header, conditional audio clearance | Source reviewed; prominent image and flat daily ayah added |
| Quran browser | Surah and all structure sections, lookup, scrollbar, flat rows | Source reviewed; scale-aware header and scrollbar positioning |
| Quran reader | Fixed header, surah/ayah popup, anchored settings, both layouts, floating controls, next-surah gesture | Source reviewed; existing layout/selection/gesture tests pass |
| Reader translation picker | Search, all editions, selected/downloaded state, errors and retry | Source reviewed; shared content-fit picker |
| Reader content sources | Attribution, editions, licenses, review status, cache policy | Source reviewed; accessible from main Settings |
| Reader tafsir | Edition picker, current ayah content, source and unavailable states | Source reviewed; live provider availability not checked |
| Reader downloads | Full translation and interlinear progress/cancel/error states | Source reviewed; retry and modal ownership guards |
| Reader sharing | Text/card preview, Arabic/translation inclusion, platform share actions | Source reviewed; platform export not invoked |
| Reader note editor | Text input, private persistence, cancel/save | Shared keyboard-safe editor; validation preserved |
| Search | Query, grouped results, category filters, Quran/library navigation, fallback result detail | Source reviewed; natural-height filters, text scaling and RTL corrected |
| Quran downloads | Arabic/translation filters, reciters, text/tafsir/audio actions, progress/deletion dialogs | Source reviewed; lazy list, stable cache checks and shared progress sheets |
| Translation manager | Active/downloaded editions, enable state, delete confirmation | Source reviewed; lazy rows, expandable attribution, guarded stream cleanup |
| Bookmarks | Collection shelf/counts, search, sorting, creation, move/remove, reader links | Redesigned; local browser interactions and small-screen/dark/large-text layout review; device review pending |
| Notes | Search/category filters, date groups, sorting, save-before-dismiss editor, verse links, confirmed deletion | Redesigned; local browser interactions and small-screen/dark/large-text layout review; device review pending |
| Prayer | Next prayer, schedule, calculation controls, worship tools | Source reviewed; flat sections/rows, no calculation changes |
| Prayer location | Offline search, suggestions, current location, loading/errors | Source reviewed; content-fit search and scrollable consent |
| Prayer alerts | All/timing/per-prayer switches, minutes, save, permission dialog | Source reviewed; flat switches and explicit consent preserved |
| Qibla | Orbiting Kaaba, fixed alignment target, shortest-turn arc, stable confirmation, haptic, quality feedback, retry | Redesigned after the original audit; actual page reviewed in a simulated-heading browser preview. Native providers unchanged; physical accuracy/haptics pending. See `qibla-compass-redesign.md`. |
| Hijri calendar | Month navigation, day selection, today, event metadata | Source reviewed; named arrows and corrected Dark selection contrast |
| Library browser | Hadith books, Azkar categories, tool destinations, local search | Source reviewed; flat browser and preserved routes |
| HadeethEnc sheet | Language, downloads, progress, paging, errors | Source reviewed; content-fit sheet, expanded language menu and RTL text |
| Hadith book reader | Fixed header, lookup/chapter navigation, numbered scrollbar, authenticity/source metadata | Source reviewed; keyboard-safe navigation and preserved normal opening |
| Hadith overlays | Settings, language, source, details, note, download progress | Source reviewed; shared note sheet, bounded actions, route-owned progress |
| Azkar category reader | Fixed header, category/item navigation, per-item counters, numbered scrollbar | Source reviewed; unframed summary and keyboard-safe navigation |
| Azkar overlays | Settings, language, source, details, note, download progress | Source reviewed; shared note sheet and text-size controls |
| Settings | Theme, global font controls, interface/content languages, backup access | Source reviewed; Light/Dark, infrequent reading choices relocated |
| Onboarding | Six existing steps, summary, city search, permission confirmation | Source reviewed; imagery, shared language picker, cached preview and retry states |
| Tasbieh | Classic bead gesture/animations, count/target, undo/reset | Source reviewed; existing swipe/reduced-motion tests pass |
| Tasbieh target | 33/99 presets, positive custom target, keyboard, set action | Source reviewed; content-fit form and existing tests pass |
| Reading goals | Goal/streak/dashboard, Khatma/range editors, actions menu | Flat sections and content-fit editors implemented; source reviewed |
| Hifz dashboard | Collections, review overview, range editor | Compact collection browser and editor implemented; source reviewed |
| Hifz review | Arabic reveal/grading/review controls | Unframed review area and wrapping controls implemented; source reviewed |
| Prayer tracking | Calendar/day records, reminder/exemption settings, log editor | Flat sections and shared editors implemented; source reviewed; no personal records modified |
| Backup | Export/import, password, restore preview, merge/replace and deletion confirmations | Flat sections and scrollable confirmations implemented; encryption and destructive operations not exercised |
| Duas | Categories/search/favorites and item actions | Lazy list and expandable daily/source sections implemented; source reviewed |
| Divine names | Search, meanings, learned progress | Lazy variable-height rows implemented; no truncated meaning/reference; source reviewed |
| Zakat | Inputs, assumptions, currency, calculation/results | Flat sections and wrapping results implemented; formulas unchanged |
| Ramadan | Suhoor/Iftar, fasting/Quran goal, progress | Flat sections and selected fasting status implemented; source reviewed |
| Achievements | Optional private milestones and progress | Flat rows, monochrome icons, retry state implemented; privacy settings unchanged |
| Mosque locator | Location/search/results/map handoff, permission and offline/error states | Flat search/results implemented; source reviewed; no location transmission or map launch performed |

## Checks Run

- Final code-only run: `flutter analyze --no-pub lib` and `git diff --check` passed.
- Final combined focused run: 96 existing checks passed across reader layouts, Arabic highlights, reader settings, next-surah gestures, audio/repeat, downloads, translations, bookmarks/user data, search bloc, Home, Tasbieh, prayer repository and routes. No new cases were authored. The Dart finalizer diagnostic still appeared even though the runner exited successfully.
- A separate expanded run passed 48 checks but failed to compile `test/features/search/data/local_deep_search_repository_test.dart`: its fake Hadith/Azkar repositories lack current translation methods and `languageCode` parameters. This is not a passing full-suite result; the UI pass did not change those interfaces or fixtures.

Historical checks below predate the final code-only pass:

- `flutter analyze --no-pub lib`: passed after the shared picker/sheet/library changes.
- 63 existing Tasbieh, Quran audio, and reader floating-control tests: passed.
- Broader Hadith/Azkar run: not green. Old repository fixtures omit newly required parameters; source-count/authenticity expectations also disagree with the current corpus. Do not repair data behavior merely to satisfy stale fixture assumptions during a UI pass.
- Bootstrap widget test: existing path-provider setup failure. Not proof of UI regression or full-suite success.
- No new tests written.
- First iPhone release build installed and inspected: Home, Settings White/Dark, Quran Surah browser, Quran Combined IndoPak/Urdu reader, reader settings, translation picker, Bukhari reader/settings/language picker, Azkar browser/reader/settings, playback sheet, shell audio, and the earlier Tasbieh target sheet.
- Surah artwork displayed in both reader and shell audio controls. Shell audio stayed above navigation and changed its subtitle from Arabic ayah to translation. Complete media-session, timing, seeking and follow-audio correctness are not established by these screenshots.
- White theme was restored after the Dark appearance check. Verification playback was stopped with the audio close control; no downloads, destructive actions, backup/share exports, or count/reset actions were performed.
- Subsequent earlier release builds were installed for Tasbieh, Qibla/calendar, search/note, progress sheets, and unframed Prayer sections. Tasbieh/target, Qibla, Prayer overview, and Prayer alerts were checked on the physical phone. Calendar/search-note/progress were not physically verified; no current visual approval is inferred.
- Hadith/Azkar completion callbacks check that their sheet route is still current before dismissing. This prevents a delayed completion from popping the underlying reader after cancellation; live concurrent cancellation/download testing remains an evidence limitation.
- Shared sheet dismissal also verifies route ownership and guards repeated close requests. Final analysis and the same 63 focused existing tests pass with these guards; no new test files were created.

## Completion Gates

1. Complete: reviewed every listed active destination and overlay against the source inventory. Input/provider lifetimes and asynchronous modal ownership were checked in touched flows.
2. Complete: active sheets use content-fit bounded layouts; retained fixed geometry is for intentional controls, tiles, compass graphics and scroll rails. Removed remaining unnecessary permission, metadata and navigation framing without dropping attribution or validation.
3. Complete: performed code-only constraint, safe-area, keyboard, empty/error and cancellation-path review. No historical screenshot is used as acceptance of the new work.
4. Complete within source/test scope: both reader layouts, IndoPak/Uthmani selection, Arabic size stability, RTL translation and playback interactions remain. Gesture/layout regressions have existing focused coverage, not new device evidence.
5. Complete: final library-wide analyzer and focused existing checks were run. The separate deep-search data suite cannot compile because its old fake Hadith/Azkar repositories omit translation APIs and language parameters. Earlier broader corpus/bootstrap fixture limitations remain. Do not describe the entire test suite as green.

Residual verification: actual small/large-device rendering, screen-reader behavior, physical Qibla accuracy, touch sheet dismissal, live download cancellation, platform share/export and artistic comparison with Nusuk were not exercised in this code-only pass. No new tests were authored. These are evidence limits, not claims of device or user approval.
