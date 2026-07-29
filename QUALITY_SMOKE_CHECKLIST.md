# Production Smoke Checklist

Last updated: 2026-07-10

Run this checklist on each supported platform before a release candidate. No simulator run is required for routine implementation work.

## Startup and onboarding

- Fresh install opens the resumable setup journey.
- Existing install opens Home without being forced through setup.
- Closing and reopening setup resumes the saved step.
- System, English, Urdu, and Arabic UI choices launch without a blank screen.
- Denied location permission offers city search and does not block setup.
- Prayer preview matches the selected city, method, and Asr calculation.
- Notification permission appears only after the explanation and setup can finish when denied.

## Home

- Prayer, Verse of the Day, and resume-reading cards load independently.
- Missing prayer setup shows recovery guidance instead of fabricated times.
- Pull to refresh updates prayer data without clearing Quran progress.
- Verse of the Day opens the exact ayah and copies with citation.

## Quran reader

- Surah list, verse mode, continuous mode, direct ayah link, next Surah, and resume reading work offline.
- Arabic remains visible when translations or tafsir are unavailable.
- Translation visibility does not clear the selected edition.
- Tafsir edition stays independent from Quran translation.
- Combined mode requests word data only for the selected word-meaning language.
- Reader settings show content source, license review, and cache policy.
- Large text and RTL do not hide reader controls.

## Downloads and audio

- Translation, tafsir, word data, timing, Arabic audio, and meaning audio failures have retry paths.
- Expired Quran Foundation data is not shown as a valid complete download.
- Audio meaning language stays independent from Quran translation after an explicit choice.
- Pause, resume, repeat, range playback, and close restore state correctly.
- Deleting one audio type keeps unrelated downloads.

## Prayer and Qibla

- Manual city, current location, calculation method, madhab, and alerts persist after restart.
- Permission denied, denied forever, service disabled, and offline states give an action.
- Sunrise is never presented as a prayer.
- Qibla handles missing sensor/location without a crash.

## Hadith and Azkar

- Hadith and Azkar language choices do not change Quran translation.
- Missing language packs offer download or a clear unavailable state.
- Arabic source text remains visible when a translation pack is missing.
- Source attribution remains accessible.

## User data

- Bookmarks, notes, last read, settings, and Tasbieh state survive restart.
- Search result deep links open the correct resource and item.
- No sensitive location coordinates or private notes appear in diagnostic output.

## Verification commands

- `dart format` on touched Dart files.
- `flutter analyze lib`.
- Existing focused checks for touched production areas.
- `flutter build bundle --debug`.

Do not add or modify tests unless explicitly requested.
