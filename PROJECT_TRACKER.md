# Quran App Project Tracker

Last updated: 2026-07-10

This document is the living project tracker for the Quran app. Update it whenever architecture changes, a feature starts, a feature ships, a bug is found, a bug is fixed, or an implementation technique proves useful.

## 1. Project Goal

Build a clean, attractive, easy-to-use Flutter Quran app using BLoC architecture.

Core feature areas:

- Quran reading
- Tafsir
- Islamic calendar
- Qibla direction
- Prayer times
- Azkar
- Mosque locations
- Hadith
- Settings, theme, localization, font size, dashboard, and bottom navigation

Primary product values:

- Clean first screen with useful daily Islamic context
- Fast reading experience
- Simple navigation for non-technical users
- Strong offline behavior for core content
- Respectful Islamic content handling with source tracking
- Accessibility through readable typography, language support, and font controls

## 2. Current Repo Snapshot

Current app:

- `lib/main.dart` is the default Flutter counter app and should be replaced.
- `pubspec.yaml` only contains Flutter and `cupertino_icons`.
- No root `assets/` folder exists yet.
- No root localization files exist yet.
- The root folder is not currently a git repository.

Demo app:

- `demo/lib` contains a larger Flutter app named `cires`.
- Demo uses GetX heavily. The new Quran app will use BLoC instead.
- Demo code is useful for theme, localization structure, font scaling ideas, shell/dashboard layout ideas, bottom navigation behavior, shared UI patterns, and settings concepts.

Important demo files to study and adapt:

| Area | Demo files | How to use |
| --- | --- | --- |
| App bootstrap | `demo/lib/main.dart` | Reuse the startup ordering idea, but replace GetX dependency setup with BLoC/get_it setup. |
| Theme system | `demo/lib/theme/app_theme.dart` | Adapt color presets, semantic colors, adaptive metrics, system UI overlay, radius, font scaling, and typography. |
| Settings state | `demo/lib/controllers/app_settings_controller.dart` | Convert theme, locale, font, icon, and notification settings to `SettingsCubit`. |
| Settings storage | `demo/lib/data/app_settings_hive.dart`, `demo/lib/data/settings_repository.dart` | Reuse the local settings concept with Quran-specific fields. |
| Localization | `demo/lib/l10n/*.arb`, `demo/lib/l10n/gen/*` | Recreate root app ARB structure with Quran app strings. |
| Shell navigation | `demo/lib/ui/shell/shell_screen.dart`, `demo/lib/ui/shell/shell_controller.dart` | Adapt docked bottom nav and tab persistence, but replace controller with `ShellCubit`. |
| Dashboard | `demo/lib/ui/tabs/dashboard/dashboard_screen.dart`, `demo/lib/ui/tabs/dashboard/dashboard_controller.dart` | Use as visual inspiration only. Build a simpler Quran dashboard first. |
| Shared UI | `demo/lib/ui/shared/*` | Move useful widgets one by one only when needed. Avoid copying finance-specific widgets. |
| Icon switching | `demo/lib/ui/shared/huge_icon.dart`, icon map files | Consider later if icon-pack switching is still desired. |

## 3. Architecture Target

Use feature-first clean architecture with BLoC.

Target folders:

```text
lib/
  app/
    app.dart
    bootstrap.dart
    router/
      app_router.dart
      app_routes.dart
    di/
      injection.dart
    observers/
      app_bloc_observer.dart

  core/
    constants/
      app_constants.dart
    errors/
      app_exception.dart
      failure.dart
    localization/
      locale_cubit.dart
      locale_state.dart
    network/
      api_client.dart
      network_info.dart
    permissions/
      permission_service.dart
    storage/
      app_database.dart
      settings_store.dart
    theme/
      quran_colors.dart
      quran_theme.dart
      quran_theme_cubit.dart
      quran_theme_state.dart
    utils/
      date_utils.dart
      geo_utils.dart
      text_normalizer.dart
    widgets/
      app_scaffold.dart
      app_error_view.dart
      app_loading_view.dart
      adaptive_inset_area.dart
      feature_card.dart
      section_header.dart

  features/
    shell/
      presentation/
        bloc/
          shell_cubit.dart
          shell_state.dart
        pages/
          shell_page.dart
        widgets/
          app_bottom_nav.dart

    home/
      data/
      domain/
      presentation/
        bloc/
        pages/
        widgets/

    quran/
      data/
        datasources/
        models/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        bloc/
        pages/
        widgets/

    tafsir/
    prayer_times/
    qibla/
    islamic_calendar/
    azkar/
    mosque_locator/
    hadith/
    settings/

  l10n/
    app_en.arb
    app_ur.arb
    app_ar.arb

  main.dart
```

Architecture rules:

- UI talks to BLoC/Cubit only.
- BLoC/Cubit talks to use cases or repositories.
- Repositories hide local data, remote data, permissions, and platform APIs.
- Models are data-layer objects. Entities are domain objects.
- Feature UI must not import another feature's data layer.
- Shared widgets stay in `core/widgets` only when reused by at least two features.
- Keep feature modules small. Do not build a large shared abstraction until duplication is real.

Recommended state-management split:

| State type | Use |
| --- | --- |
| `Bloc` | Quran reader, search, prayer time calculation, qibla sensor stream, mosque search, hadith search. |
| `Cubit` | Theme, locale, shell tab, font size, simple settings toggles. |
| Repository stream | Bookmarks, last read, downloads, prayer notification schedule changes. |

## 4. Planned Dependencies

Dependencies to add during implementation, after compatibility checks:

| Category | Candidate packages | Reason |
| --- | --- | --- |
| BLoC | `flutter_bloc`, `bloc`, `equatable` | App state management. |
| Dependency injection | `get_it` | Simple dependency registration without tying UI to service lookup. |
| Routing | `go_router` or Flutter Navigator 2 wrapper | Declarative routes and deep links. |
| Local settings | `hive`, `hive_flutter`, `path_provider` | Small user preferences, bookmarks, downloaded flags. |
| Large local data | `drift` or `sqflite` | Quran, tafsir, and hadith search/storage need indexed local data. |
| Localization | `flutter_localizations`, `intl` | English, Urdu, Arabic and later more languages. |
| Prayer calculations | `adhan_dart` | Local prayer time calculation. Avoid network dependency for daily prayer times. |
| Location | `geolocator`, `geocoding` | Prayer times, Qibla, mosque search. |
| Compass | `flutter_compass` | Device heading for Qibla compass. |
| Permissions | `permission_handler` | Location, notifications, sensor-related permission flows. |
| Notifications | `flutter_local_notifications`, `timezone` | Prayer and azkar reminders. |
| HTTP | `http` or `dio` | Quran.com, AlAdhan validation, hadith API, mosque API if needed. |
| Maps/links | `url_launcher` | Open mosque directions in maps. |
| Icons | `lucide_icons_flutter` or Material icons | Clean iconography. |

Avoid at first:

- Firebase, subscriptions, analytics, or authentication.
- Heavy animation libraries until the base app is stable.
- Copying all demo services. Most are finance-specific and not relevant.

## 5. External Feature Research

Research notes from current public documentation:

| Area | Finding | Product implication |
| --- | --- | --- |
| Quran content | Quran.com API supports verses with translations, tafsir, audio, word metadata, scripts, page, juz, hizb, and verse keys. | Good remote source for rich features and validation. For MVP, bundle base Quran text locally and use remote content later for optional resources. |
| Quran database | AlQuranDB provides Quran translations in JSON, CSV, SQLite, XML, XLSX, and SQL formats. The fawazahmed0 Quran API repository provides static JSON/CDN Quran editions with 90+ languages and 400+ translations. Tanzil provides verified Quran text and translation downloads with terms that must be respected. | Prefer a bundled local SQLite/JSON dataset for Quran text and selected translations instead of hand-writing content. Keep Quran.com as a rich remote enhancement/validation source. |
| Quran MVP package | `quran_with_tafsir` v1.0.1 provides offline Arabic text, English translation, Arabic Tafsir Al-Muyassar, metadata, local search, page/juz navigation, and audio URLs. | Selected for initial MVP behind `QuranRepository` so the UI stays independent of the package API. |
| Prayer times | AlAdhan documents many calculation methods and explains method differences by authority and location. | Settings must expose calculation method, Asr method, time adjustments, and location override. |
| Prayer calculation package | `adhan_dart` is a Dart package for local prayer calculations, based on the Adhan calculation approach and available across Flutter platforms. | Prefer local calculation for reliability, with AlAdhan as validation/reference if needed. |
| Qibla compass | `flutter_compass` provides heading from 0 to 360 and notes Android may return null when no sensor is available. | Qibla UI needs unavailable-sensor, permission, and calibration states. |
| Islamic calendar | Hijri packages vary. `hijri_date` offers Umm al-Qura calendar, events, localization, and moon phase utilities. | Use a package or internal service with user-adjustable Hijri offset. |
| Hadith database | Sunnah.com provides an API, but it requires an API key and currently exposes a portion of data. fawazahmed0/hadith-api provides static JSON endpoints via CDN with multiple languages and grades. AhmedBaset/hadith-json provides a large JSON database of 17 books, including the nine books. | MVP should avoid hard dependency on a key. Prefer bundled/downloadable JSON or SQLite subsets with repository interfaces for later online refresh. |
| Azkar database | Azkar content should be bundled from a credited Hisnul Muslim/adhkar JSON source after license verification. | Keep Azkar fully offline, grouped by morning, evening, sleep, prayer, and general categories. |
| Mosque locations | OpenStreetMap maps mosques as `amenity=place_of_worship` + `religion=muslim`; Overpass can query nearby nodes/ways/relations. | Prefer OpenStreetMap/Overpass for a no-key MVP, with Apple/Google Maps deep links for directions. Add provider abstraction in case Google Places is selected later. |

Database-first source strategy:

| Feature | Source type | Recommended first source | Storage approach |
| --- | --- | --- | --- |
| Quran Arabic text | Bundled local database | Tanzil or AlQuranDB after license review | SQLite or generated compact JSON asset, indexed by `surahNumber`, `ayahNumber`, `verseKey`. |
| Quran translations | Bundled local database | AlQuranDB or fawazahmed0/quran-api selected editions | Start with English, Urdu, and Arabic-related resources only; add downloadable language packs later. |
| Tafsir | Bundled local database | `quran_with_tafsir` Al-Muyassar for MVP; evaluate AlQuranDB/Tanzil tafsir editions for expansion | Store by `verseKey`; support one bundled tafsir first. |
| Hadith | Bundled/downloadable database | fawazahmed0/hadith-api static JSON or AhmedBaset/hadith-json after license review | Start with one or two collections and search; keep full library downloadable later. |
| Azkar | Bundled local JSON | Hisnul Muslim/adhkar JSON source after license review | JSON asset is enough; no remote dependency. |
| Prayer times | Local calculation plus optional API validation | `adhan_dart`, AlAdhan for reference | No static database; cache calculated monthly timetable. |
| Islamic calendar | Local calculation/API-backed conversion | Hijri/Umm al-Qura package or AlAdhan calendar endpoint | Cache month results; allow manual Hijri offset. |
| Qibla | Device/location calculation | Device location + Kaaba bearing formula + compass | No content database. |
| Mosque locations | Remote location query | OpenStreetMap Overpass | Cache recent nearby results with timestamp and radius. |

Reference links:

- Quran.com Verses API: https://api-docs.quran.com/docs/sdk/verses
- AlQuranDB: https://alqurandb.com/
- Tanzil translations: https://tanzil.net/trans
- fawazahmed0 Quran API: https://github.com/fawazahmed0/quran-api
- `quran_with_tafsir`: https://pub.dev/packages/quran_with_tafsir
- AlAdhan calculation methods: https://aladhan.com/calculation-methods
- `adhan_dart`: https://pub.dev/packages/adhan_dart/versions/1.2.0
- `flutter_compass`: https://pub.dev/packages/flutter_compass
- `hijri_date`: https://pub.dev/packages/hijri_date
- Sunnah.com developers page: https://sunnah.com/developers
- fawazahmed0 Hadith API: https://github.com/fawazahmed0/hadith-api
- AhmedBaset Hadith JSON: https://github.com/AhmedBaset/hadith-json
- OpenStreetMap place of worship tagging: https://wiki.openstreetmap.org/wiki/Tag:amenity%3Dplace_of_worship
- OpenStreetMap mosque tagging: https://wiki.openstreetmap.org/wiki/Mosque

## 6. Product Navigation Plan

Initial bottom navigation:

| Tab | Purpose | Primary content |
| --- | --- | --- |
| Home | Daily overview | Next prayer, last read, daily ayah, daily hadith, quick azkar, Hijri date. |
| Quran | Quran reading | Surah list, juz list, bookmarks, search, reader. |
| Prayer | Worship utilities | Prayer times, Qibla, Islamic calendar, mosque locator entry. |
| Library | Learning and remembrance | Tafsir, hadith, azkar collections, favorites. |
| Settings | Personalization | Theme, language, font, prayer method, notifications, downloads. |

Home screen first version:

- Greeting and Hijri date
- Next prayer card with countdown
- Continue reading card
- Daily ayah card
- Quick actions: Quran, Qibla, Azkar, Mosque
- Daily hadith card
- Bottom nav visible and stable

Reader first version:

- Surah list
- Verse list
- Arabic Quran text
- Translation toggle
- Font size control
- Last read save
- Bookmark verse
- Search by surah name and verse text

## 7. Feature Registry

Status values: `Planned`, `Research`, `In Progress`, `Blocked`, `Done`.

| Feature | Status | Logic files | UI files | Notes |
| --- | --- | --- | --- | --- |
| Project tracker | Done | `PROJECT_TRACKER.md` | N/A | Living planning and tracking document. |
| Data source strategy | Done | `DATA_SOURCE_PLAN.md`, `PROJECT_TRACKER.md` | N/A | Database-first source plan added. Static Islamic content should come from credited datasets, not hand-written app content. |
| App foundation | Done | `lib/app/*`, `lib/core/*`, `lib/main.dart` | `lib/app/app.dart` | Counter app replaced with BLoC-ready bootstrap, DI, router, settings store, and app root. |
| Theme system | Done | `lib/core/theme/*`, `lib/features/settings/*` | Shared app widgets, `settings_page.dart` | Light, dark, black presets, font scale, font weight, semantic colors, and system UI overlay implemented. |
| Localization | Done | `lib/l10n/*.arb`, `lib/l10n/gen/*`, `lib/core/localization/*` | All current screens | English, Urdu, Arabic ARB files and locale cubit implemented. |
| Shell and bottom nav | Done | `lib/features/shell/presentation/bloc/*` | `lib/features/shell/presentation/pages/shell_page.dart`, `widgets/app_bottom_nav.dart` | BLoC/Cubit shell, persistent tabs, and docked bottom nav implemented. |
| Home dashboard | In Progress | `lib/features/home/domain/*`, `lib/features/home/presentation/cubit/*`, Quran repository, Prayer times repository | `lib/features/home/presentation/pages/home_page.dart` | Live next prayer and location, continue reading, deterministic Verse of the Day, independent section errors, pull-to-refresh, and return-to-home refresh are implemented. Daily hadith and first-run prayer-location setup remain. |
| Quran | In Progress | `lib/core/content/content_source.dart`, `lib/features/quran/data/*`, `domain/*`, `presentation/bloc/*`, `lib/features/quran_audio/*`, `lib/app/router/*` | `quran_page.dart`, `quran_reader_page.dart`, `quran_search_page.dart`, `surah_tile.dart`, floating audio player | Offline package source integrated. Surah list, reader, translation toggle, bookmarks, last-read persistence, Home last-read card, Quran text search UI, tafsir sheet, source attribution, bookmark/search-to-ayah navigation, scroll-based last-read tracking, ayah audio playback with 90+ reciter/audio editions, persisted reciter selection, continuous Surah playback, background audio service wiring, floating bottom mini-player, expanded controls, in-player reciter switching, repeat count controls, memorization range playback, preset range chips, and localized audio labels are working. |
| Tafsir | Planned | `lib/features/tafsir/*` | Tafsir panel/page | Start with verse-level tafsir viewer. |
| Prayer times | In Progress | `lib/features/prayer_times/*`, `lib/app/di/injection.dart`, `lib/core/storage/settings_store.dart`, `pubspec.yaml` | `lib/features/prayer/presentation/pages/prayer_page.dart` | `adhan_dart` local calculation, prayer entities/settings, repository, Cubit, live Prayer tab timetable, saved method/madhab/manual location controls, and tests are implemented. Device location and notifications still pending. |
| Qibla | In Progress | `lib/features/qibla/*`, `lib/app/di/injection.dart`, `SettingsStore` prayer location | `lib/features/prayer/presentation/pages/prayer_page.dart` | Static Qibla bearing calculation from saved/manual prayer location, repository, Cubit, Prayer tab card, and tests are implemented. Live compass sensor state still pending. |
| Islamic calendar | Planned | `lib/features/islamic_calendar/*` | Calendar page/card | Hijri offset and Islamic events. |
| Azkar | In Progress | `lib/features/azkar/domain/*`, `lib/features/azkar/data/*`, `lib/features/azkar/presentation/bloc/*`, `lib/app/di/injection.dart` | `lib/features/library/presentation/pages/library_page.dart` | Repository, local data-source scaffold, source attribution, category/search Cubit, Library UI section, and tests are implemented. Real source/license selection still pending before importing release content. |
| Mosque locator | Planned | `lib/features/mosque_locator/*` | Mosque list/map/directions | Provider decision needed. |
| Hadith | In Progress | `lib/features/hadith/domain/*`, `lib/features/hadith/data/*`, `lib/features/hadith/presentation/bloc/*`, `lib/app/di/injection.dart` | `lib/features/library/presentation/pages/library_page.dart` | Repository, local data-source scaffold, source attribution, collection/search Cubit, Library UI section, and tests are implemented. Real source/license selection still pending before importing release content. |
| Settings | In Progress | `lib/features/settings/*`, `core/theme`, `core/localization` | `lib/features/settings/presentation/pages/settings_page.dart` | Theme, language, and font controls implemented. Prayer method and notification settings still pending. |

## 8. Developed Features

| Feature | Date | Files | Summary |
| --- | --- | --- | --- |
| Project tracker | 2026-04-25 | `PROJECT_TRACKER.md` | Created the master planning and tracking file. |
| Data source plan | 2026-04-25 | `DATA_SOURCE_PLAN.md`, `PROJECT_TRACKER.md` | Added database/API source strategy for Quran, tafsir, hadith, azkar, prayer times, Islamic calendar, qibla, and mosque locations. Recommended local-first datasets for static Islamic content and calculation/location providers for dynamic features. |
| App foundation | 2026-04-25 | `pubspec.yaml`, `l10n.yaml`, `analysis_options.yaml`, `lib/main.dart`, `lib/app/*`, `lib/core/*`, `lib/l10n/*`, `test/widget_test.dart` | Added BLoC dependencies, generated localization setup, DI, router, settings store, app root, theme cubit, locale cubit, startup test, and analyzer demo exclusion. |
| Shell and first dashboard | 2026-04-25 | `lib/features/shell/*`, `lib/features/home/*`, `lib/features/quran/*`, `lib/features/prayer/*`, `lib/features/library/*`, `lib/features/settings/*` | Added five-tab shell, docked bottom navigation, home dashboard placeholders, feature placeholders, and first settings controls. |
| Quran data foundation | 2026-04-25 | `pubspec.yaml`, `lib/app/di/injection.dart`, `lib/features/quran/domain/*`, `lib/features/quran/data/*`, `lib/features/quran/presentation/bloc/*`, `test/features/quran/*` | Added `quran_with_tafsir`, repository boundary, local source adapter, Surah/Ayah entities, list/reader BLoCs, and tests. |
| Quran Surah list and reader | 2026-04-25 | `lib/app/router/*`, `lib/features/quran/presentation/pages/quran_page.dart`, `lib/features/quran/presentation/pages/quran_reader_page.dart`, `lib/features/quran/presentation/widgets/surah_tile.dart`, `lib/l10n/*.arb` | Replaced Quran placeholder with real 114-Surah list, search-by-surah filter, reader route, Arabic ayah display, English translation, and translation toggle. |
| Quran progress and bookmarks | 2026-04-25 | `lib/features/quran/data/stores/quran_user_data_store.dart`, `lib/features/quran/domain/entities/quran_last_read.dart`, `lib/features/quran/domain/entities/quran_bookmark.dart`, `lib/features/quran/domain/repositories/quran_repository.dart`, `lib/features/quran/data/repositories/quran_repository_impl.dart`, `lib/features/quran/presentation/bloc/quran_reader_*`, `lib/features/quran/presentation/pages/quran_reader_page.dart`, `test/features/quran/data/quran_user_data_store_test.dart`, `test/features/quran/presentation/quran_list_bloc_test.dart` | Added persistent last-read storage, bookmark storage, repository methods, reader BLoC bookmark events, ayah bookmark button, and tests. |
| Quran Home progress and search | 2026-04-25 | `lib/features/home/presentation/cubit/*`, `lib/features/home/presentation/pages/home_page.dart`, `lib/features/quran/presentation/bloc/search/*`, `lib/features/quran/presentation/pages/search/quran_search_page.dart`, `lib/features/quran/presentation/pages/quran_page.dart`, `lib/app/router/*`, `lib/l10n/*.arb`, `test/features/home/presentation/home_cubit_test.dart`, `test/features/quran/presentation/quran_search_bloc_test.dart` | Wired Home continue-reading card to saved Quran progress and added full Quran text search route/page/BLoC. |
| Quran source attribution | 2026-04-25 | `lib/core/content/content_source.dart`, `lib/features/quran/domain/repositories/quran_repository.dart`, `lib/features/quran/data/datasources/local_quran_data_source.dart`, `lib/features/quran/data/repositories/quran_repository_impl.dart`, `lib/features/quran/presentation/bloc/quran_reader_*`, `lib/l10n/*.arb`, `test/features/quran/presentation/quran_list_bloc_test.dart` | Added shared content source metadata, exposed Quran package attribution through the repository, loaded it in reader state, and displayed source information in the reader header and tafsir sheet. |
| Quran bookmark target navigation | 2026-04-26 | `lib/app/router/*`, `lib/features/quran/presentation/bloc/quran_reader_*`, `lib/features/quran/presentation/pages/quran_page.dart`, `lib/features/quran/presentation/pages/quran_reader_page.dart`, `test/features/quran/presentation/quran_list_bloc_test.dart` | Bookmark cards now open the reader with an ayah query parameter, reader BLoC starts at that ayah, saves it as current last-read, highlights it, and scrolls to it after load. |
| Quran scroll last-read tracking | 2026-04-26 | `lib/features/quran/presentation/pages/quran_reader_page.dart` | Reader now observes scroll activity, debounces updates, detects the ayah with the largest visible area, and saves it through the existing last-read BLoC event. |
| Quran search target navigation | 2026-04-28 | `lib/features/quran/presentation/pages/search/quran_search_page.dart`, `test/app/router/app_routes_test.dart` | Quran text search results now open the reader at the exact ayah instead of only the containing Surah, with route coverage for ayah query links. |
| Quran ayah audio | 2026-04-28 | `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`, `lib/features/quran/domain/entities/quran_audio_reciter.dart`, `lib/features/quran/domain/entities/quran_ayah.dart`, `lib/features/quran/data/datasources/local_quran_data_source.dart`, `lib/features/quran/domain/repositories/quran_repository.dart`, `lib/features/quran/data/repositories/quran_repository_impl.dart`, `lib/features/quran/presentation/bloc/quran_reader_*`, `lib/features/quran/presentation/pages/quran_reader_page.dart`, `lib/l10n/*.arb`, `test/features/quran/data/local_quran_data_source_test.dart` | Added `just_audio`, Android internet permission, a broad static 94-entry reciter/audio-edition catalog from EveryAyah-compatible identifiers and AlQuran Cloud audio editions, ayah global-number metadata, reciter selection in the reader header, per-ayah play/pause buttons, and URL generation tests. |
| Quran continuous audio | 2026-04-28 | `lib/features/quran/data/stores/quran_user_data_store.dart`, `lib/features/quran/domain/repositories/quran_repository.dart`, `lib/features/quran/data/repositories/quran_repository_impl.dart`, `lib/features/quran/presentation/bloc/quran_reader_*`, `lib/features/quran/presentation/pages/quran_reader_page.dart`, `lib/l10n/*.arb`, `test/features/quran/*` | Persisted selected Quran reciter, restored it on reader load, added Play Surah/Stop controls, advanced to the next ayah when audio completes, saved currently playing ayah as last-read, and added storage/BLoC tests. |
| Quran background floating player | 2026-04-28 | `pubspec.yaml`, `pubspec.lock`, `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/kotlin/com/coreinfinite/quran/MainActivity.kt`, `ios/Runner/Info.plist`, `lib/app/di/injection.dart`, `lib/app/app.dart`, `lib/features/shell/presentation/pages/shell_page.dart`, `lib/features/quran_audio/*`, `lib/features/quran/presentation/pages/quran_reader_page.dart`, `test/widget_test.dart` | Added `audio_service` and `audio_session`, configured Android/iOS background audio, moved playback ownership from reader-local `AudioPlayer` to app-level `QuranAudioHandler`/`QuranAudioCubit`, added floating bottom mini-player above the dock, added expanded sheet controls for seek/speed/repeat/skip/open/stop, and refactored the reader to act as a playback client. Verified with analyzer, full tests, and Android debug build. |
| Quran expanded audio controls | 2026-04-28 | `lib/app/app.dart`, `lib/features/quran_audio/domain/entities/quran_audio_state.dart`, `lib/features/quran_audio/presentation/cubit/quran_audio_cubit.dart`, `lib/features/quran_audio/presentation/widgets/quran_floating_audio_player.dart` | Added reciter switching inside the expanded audio sheet, queue rebuild when reciter changes, selected-reciter persistence from the player, repeat-count state/control, and repeat-count replay behavior for the current ayah before advancing. Verified with analyzer, full tests, and Android debug build. |
| Quran memorization range playback | 2026-04-28 | `lib/features/quran_audio/domain/entities/quran_audio_state.dart`, `lib/features/quran_audio/presentation/cubit/quran_audio_cubit.dart`, `lib/features/quran_audio/presentation/widgets/quran_floating_audio_player.dart`, `test/features/quran_audio/domain/quran_audio_state_test.dart` | Added range start/end state, expanded-player From/To selectors, Play Range action, range queue building through the active Surah and reciter, range preservation during reciter switching, and state tests for range metadata. Verified with analyzer, full tests, and Android debug build. |
| Quran audio range presets and localization | 2026-05-05 | `lib/features/quran_audio/domain/entities/quran_audio_queue_item.dart`, `lib/features/quran_audio/presentation/cubit/quran_audio_cubit.dart`, `lib/features/quran_audio/presentation/widgets/quran_floating_audio_player.dart`, `lib/l10n/*.arb`, `lib/l10n/gen/*` | Added active audio item page metadata, range presets for current ayah, current page, current-to-end, and full Surah, and replaced hardcoded expanded-player labels with localized strings in English, Urdu, and Arabic. Verified with analyzer and Android debug build. Tests intentionally skipped by user request. |
| Hadith foundation | 2026-04-26 | `lib/features/hadith/domain/*`, `lib/features/hadith/data/*`, `lib/features/hadith/presentation/bloc/*`, `lib/app/di/injection.dart`, `test/features/hadith/*` | Added Hadith book/chapter/item entities, repository interface, local data-source scaffold with source attribution, repository implementation, collection/search Cubit, DI registration, and tests. |
| Azkar foundation | 2026-04-26 | `lib/features/azkar/domain/*`, `lib/features/azkar/data/*`, `lib/features/azkar/presentation/bloc/*`, `lib/app/di/injection.dart`, `test/features/azkar/*` | Added Azkar category and dhikr entities, repository interface, local data-source scaffold with source attribution, repository implementation, category/search Cubit, DI registration, and tests. |
| Library Hadith and Azkar UI | 2026-04-26 | `lib/features/library/presentation/pages/library_page.dart`, `test/widget_test.dart` | Replaced Library placeholder cards with section switching, Hadith search/list UI, Azkar category/search/list UI, source notes, loading/error/empty states, and widget coverage. |
| Prayer times foundation | 2026-04-26 | `pubspec.yaml`, `lib/app/di/injection.dart`, `lib/features/prayer_times/*`, `lib/features/prayer/presentation/pages/prayer_page.dart`, `test/features/prayer_times/*` | Added `adhan_dart`, prayer location/settings/time entities, local calculation service, repository, Cubit, live Prayer tab timetable, default Karachi calculation, and tests. |
| Prayer settings and location override | 2026-04-26 | `lib/core/storage/settings_store.dart`, `lib/features/prayer_times/domain/repositories/prayer_times_repository.dart`, `lib/features/prayer_times/data/repositories/prayer_times_repository_impl.dart`, `lib/features/prayer_times/presentation/bloc/prayer_times_cubit.dart`, `lib/features/prayer/presentation/pages/prayer_page.dart`, `test/features/prayer_times/*` | Added saved prayer method, Asr madhab, manual location fields, repository persistence, Cubit update methods, Prayer page controls, and tests for saved settings/location. |
| Home live prayer integration | 2026-04-26 | `lib/features/home/presentation/cubit/*`, `lib/features/home/presentation/pages/home_page.dart`, `test/features/home/presentation/home_cubit_test.dart` | Home now loads daily prayer times through `PrayerTimesRepository` and renders the next prayer name/time from live calculation data instead of static placeholders. |
| Friday Jummah, prayer arc, and card-shadow polish | 2026-07-10 | `lib/features/prayer_times/domain/entities/prayer_time_entry.dart`, `lib/features/prayer_times/domain/entities/prayer_day_progress.dart`, `lib/core/theme/quran_theme.dart`, `lib/core/widgets/premium_surface.dart`, `lib/features/home/presentation/pages/home_page.dart`, `lib/features/prayer/presentation/pages/prayer_page.dart` | Friday Dhuhr is automatically presented as Jummah across Home, Prayer schedules, alerts, and notifications. Schedule emphasis follows the current valid prayer period rather than the next prayer, including no false highlight between sunrise and Dhuhr. The prayer arc now interpolates inside evenly positioned prayer-to-prayer segments, so its marker reaches each visual prayer slot exactly at that prayer's calculated time. Home and Prayer use compact, negative-spread shadows that avoid clipped edges and dark overlap between dense cards. |
| Sunrise, Sunset, Maghrib, and prayer-image normalization | 2026-07-10 | `assets/images/prayers/sunrise_v2.png`, `assets/images/prayers/sunrise_v2_bw.png`, `assets/images/prayers/sunset.png`, `assets/images/prayers/sunset_bw.png`, `assets/images/prayers/maghrib_twilight.png`, `assets/images/prayers/maghrib_twilight_bw.png`, `lib/features/prayer_times/presentation/widgets/prayer_time_image.dart`, `lib/features/prayer/presentation/pages/prayer_page.dart` | Added distinct generated color and inactive black-and-white imagery: Fajr remains pre-dawn, Sunrise uses a full elevated morning sun, Sunset keeps the sun at the horizon, Maghrib is post-sunset twilight with no sun, and Isha remains night. Separate asset routing prevents Sunrise/Fajr and Sunset/Maghrib reuse. Prayer imagery also uses per-asset scale normalization, true alpha, accessible metric labels, and a keyed animated next-prayer image without checkerboard margins or inconsistent cropping. |
| Dynamic Verse of the Day and Home reliability | 2026-07-10 | `lib/features/home/domain/*`, `lib/features/home/presentation/cubit/*`, `lib/features/home/presentation/pages/home_page.dart` | Replaced the hardcoded verse with a deterministic local-calendar ayah from the offline Quran repository, selected downloaded translation fallback, translator attribution, exact reader deep-link, copy/share action, independent section loading/errors, honest prayer states, pull-to-refresh, and refresh when returning Home. |
| Translation reader correctness and edition access | 2026-07-10 | `lib/core/storage/settings_store.dart`, `lib/features/quran/domain/entities/quran_translation.dart`, `lib/features/quran/data/repositories/quran_translation_repository_impl.dart`, `lib/features/quran/presentation/*`, `lib/features/quran_audio/presentation/*` | Bundled English is visible by default, hiding translation preserves the selected edition, visibility is persisted separately, cross-surah translation maps reload, combined reading falls back to verse translations, bookmarks follow the selected cached edition, and pickers expose every available translator instead of only the first per language. |
| Accessibility and navigation polish | 2026-07-10 | `lib/app/app.dart`, `lib/core/widgets/shell_screen_header.dart`, `lib/features/shell/presentation/widgets/app_bottom_nav.dart`, `lib/app/router/*` | Preserved OS text scaling, added header and bottom-navigation semantics/tooltips, added reader retry, and added a direct translation-management route from Home. |
| Qibla foundation | 2026-04-26 | `lib/features/qibla/*`, `lib/app/di/injection.dart`, `lib/features/prayer/presentation/pages/prayer_page.dart`, `test/features/qibla/*` | Added Qibla direction entity, `adhan_dart` Qibla wrapper, repository using saved prayer location, Cubit, live Prayer tab Qibla bearing card, and tests. |

Existing Flutter counter app:

- File: `lib/main.dart`
- Status: Replaced
- Action: No action needed.

## 9. Currently Developing

Current focus:

- Quran feature polish before moving deeper into other modules.

Active files:

- `PROJECT_TRACKER.md`
- `lib/features/quran/*`
- `lib/app/router/*`
- `test/features/quran/*`
- `test/app/router/*`

Completion criteria:

- Quran search/bookmark/deep-link navigation opens the exact ayah.
- Quran reader can play ayah-level audio from a broad reciter catalog.
- Quran reader can play a Surah continuously and restore the selected reciter.
- Quran audio uses an app-level background service and floating mini-player.
- Quran reader, search, bookmarks, tafsir/source display, and last-read behavior have focused tests.
- Choose exact Quran source/database strategy before replacing `quran_with_tafsir`.
- Add tests for tafsir/source display.

## 10. Next To Develop

Immediate next implementation milestone: Quran feature polish and source hardening.

Small steps:

1. Add widget coverage for Quran reader source, tafsir display, and audio controls.
2. Add widget coverage for the floating player and expanded sheet controls.
3. Add widget coverage for reciter switching, range playback, and repeat-count controls.
4. Add selected bookmark span preset once bookmark-range UX is clear.
5. Review Quran bookmark refresh behavior when returning from the reader.
6. Decide whether the next Quran source step is `quran_with_tafsir` hardening or a bundled database import spike.
7. Document exact source/license notes for the chosen Quran text, translation, tafsir, and audio path.
8. Run `dart format`.
9. Run `flutter analyze`.
10. Run `flutter test`.

## 11. Detailed Implementation Roadmap

### Milestone 0: Planning

Status: Done

Tasks:

1. Inspect root Flutter app.
2. Inspect demo folder structure.
3. Identify reusable demo concepts.
4. Research Quran, prayer, Qibla, calendar, and hadith data sources.
5. Create tracker document.

### Milestone 1: Foundation

Status: Done

Goal: Replace default app with a clean BLoC-ready app shell.

Tasks:

1. Add core dependencies.
2. Add `flutter_localizations` and `intl`.
3. Add initial `l10n` files.
4. Build app bootstrap.
5. Add BLoC observer for debug logging.
6. Add dependency injection.
7. Add app router.
8. Add theme cubit.
9. Add locale cubit.
10. Add settings store.
11. Add root `QuranApp`.
12. Add placeholder home page.
13. Add placeholder settings page.
14. Add basic tests for app startup.
15. Run analyze.

Relevant files:

- `pubspec.yaml`
- `lib/main.dart`
- `lib/app/app.dart`
- `lib/app/bootstrap.dart`
- `lib/app/di/injection.dart`
- `lib/core/theme/*`
- `lib/core/localization/*`
- `lib/core/storage/*`
- `lib/l10n/*.arb`

### Milestone 2: Shell, Dashboard, and Visual System

Status: Mostly Done

Goal: Create the real first screen and bottom navigation.

Completed:

- `ShellCubit`
- Docked bottom nav
- Five persistent tabs
- Home dashboard placeholder
- Feature card and section header shared widgets
- Light/dark/black presets
- Font size and font weight controls
- Language selector
- Startup widget test

Still pending:

- Bottom nav tab-switching widget test
- Deeper RTL visual audit on real devices
- Live dashboard data from feature blocs

Tasks:

1. Implement `ShellCubit`.
2. Implement bottom nav with stable dimensions.
3. Create five tabs: Home, Quran, Prayer, Library, Settings.
4. Build dashboard layout.
5. Add feature cards.
6. Add daily overview placeholders.
7. Add responsive spacing.
8. Add RTL-safe layout.
9. Add light/dark/black theme presets.
10. Add font scale setting.
11. Add language selector placeholder.
12. Add widget tests for bottom nav tab switching.
13. Run analyze.

Relevant files:

- `lib/features/shell/presentation/bloc/*`
- `lib/features/shell/presentation/pages/shell_page.dart`
- `lib/features/shell/presentation/widgets/app_bottom_nav.dart`
- `lib/features/home/presentation/*`
- `lib/core/widgets/*`

### Milestone 3: Quran MVP

Status: In Progress

Goal: Make the app useful as a Quran reader.

Completed:

- Source decision: `quran_with_tafsir` v1.0.1 for offline Arabic text, English translation, Arabic Tafsir Al-Muyassar, metadata, search, page/juz, and audio URL support.
- Repository boundary: `QuranRepository`.
- Local data source adapter: `LocalQuranDataSource`.
- Domain entities: `QuranSurah`, `QuranAyah`, `QuranBookmark`.
- BLoCs: `QuranListBloc`, `QuranReaderBloc`.
- Surah list page with 114 Surahs.
- Reader route and reader page.
- Translation toggle.
- Dedicated Quran user data store.
- Basic last-read persistence when a Surah opens.
- Bookmark storage and ayah bookmark toggle UI.
- Home continue-reading card uses saved last-read data.
- Quran full-text search BLoC and page.
- Repository and BLoC tests.
- `flutter analyze` and `flutter test` pass.

Still pending:

- More precise last-read update while scrolling.
- Bookmarks list/section in Quran tab.
- Tafsir entry point from reader.
- Reader font controls specific to Quran Arabic text.

Tasks:

1. Choose and document Quran text source.
2. Add Quran data asset or local database import.
3. Create Quran entities: `Surah`, `Ayah`, `Juz`, `QuranBookmark`, `LastRead`.
4. Create Quran repository interface.
5. Create local Quran data source.
6. Create use cases: get surahs, get surah ayahs, search, save bookmark, remove bookmark, save last read.
7. Create `QuranListBloc`.
8. Create `QuranReaderBloc`.
9. Create `QuranSearchBloc`.
10. Build Surah list page.
11. Build reader page.
12. Add font size controls.
13. Add translation toggle placeholder.
14. Add bookmark action.
15. Add last read card integration on Home.
16. Add Quran search.
17. Add tests for repository parsing.
18. Add BLoC tests for reader loading.
19. Run analyze.

Relevant files:

- `lib/features/quran/data/*`
- `lib/features/quran/domain/*`
- `lib/features/quran/presentation/*`
- `assets/quran/*`

### Milestone 4: Prayer Times, Location, and Notifications

Goal: Accurate daily prayer times with user control.

Tasks:

1. Add location permission service.
2. Add location repository.
3. Add prayer calculation service.
4. Add prayer settings entity.
5. Add prayer method setting.
6. Add Asr madhab setting.
7. Add manual time adjustments.
8. Add location override.
9. Create `PrayerTimesBloc`.
10. Build prayer times page.
11. Add next prayer card on Home.
12. Add notification scheduling service.
13. Add prayer notification settings.
14. Add tests for calculation service.
15. Validate sample locations against AlAdhan.
16. Run analyze.

Relevant files:

- `lib/core/permissions/*`
- `lib/core/location/*`
- `lib/features/prayer_times/*`
- `lib/features/settings/*`

### Milestone 5: Qibla

Goal: Compass-based Qibla with clear permission and sensor states.

Tasks:

1. Add Qibla calculation utility.
2. Add compass heading data source.
3. Add location dependency.
4. Create `QiblaBloc`.
5. Add states: loading, ready, permissionDenied, sensorUnavailable, locationUnavailable.
6. Build compass UI.
7. Add calibration hint.
8. Add direction degrees.
9. Add Home quick action.
10. Test Qibla bearing calculation.
11. Run analyze.

Relevant files:

- `lib/features/qibla/*`
- `lib/core/utils/geo_utils.dart`
- `lib/core/permissions/*`

### Milestone 6: Islamic Calendar

Goal: Hijri date, month view, and Islamic event awareness.

Tasks:

1. Choose Hijri date strategy/package.
2. Add calendar service.
3. Add Hijri offset setting.
4. Create event entity.
5. Create calendar repository.
6. Create `IslamicCalendarBloc`.
7. Build month view.
8. Add event list.
9. Add Home Hijri date card.
10. Add tests for date conversion and offset.
11. Run analyze.

Relevant files:

- `lib/features/islamic_calendar/*`
- `lib/features/settings/*`

### Milestone 7: Azkar

Goal: Practical remembrance feature with counters and reminders.

Tasks:

1. Choose azkar source and document attribution.
2. Add azkar data asset.
3. Create entities: `AzkarCategory`, `Zikr`, `ZikrProgress`.
4. Create repository.
5. Create `AzkarBloc`.
6. Create `ZikrCounterCubit`.
7. Build category list.
8. Build zikr detail/counter.
9. Add favorites.
10. Add morning/evening reminders.
11. Add Home quick azkar card.
12. Add tests for counter behavior.
13. Run analyze.

Relevant files:

- `lib/features/azkar/*`
- `assets/azkar/*`

### Milestone 8: Tafsir

Goal: Verse-level tafsir from a documented source.

Tasks:

1. Choose tafsir source and license.
2. Decide offline bundle vs remote fetch.
3. Create tafsir entity.
4. Create tafsir repository.
5. Create `TafsirBloc`.
6. Add tafsir entry point from Quran reader.
7. Build tafsir panel/page.
8. Add loading/error/empty states.
9. Add caching if remote.
10. Add tests for repository.
11. Run analyze.

Relevant files:

- `lib/features/tafsir/*`
- `lib/features/quran/presentation/*`
- `assets/tafsir/*`

### Milestone 9: Hadith

Goal: Hadith browsing/search with authentic source tracking.

Tasks:

1. Choose data source.
2. Document source, language, license, and update path.
3. Create entities: `HadithCollection`, `HadithBook`, `Hadith`, `HadithGrade`.
4. Create repository interface.
5. Create local or remote data source.
6. Create `HadithCollectionsBloc`.
7. Create `HadithSearchBloc`.
8. Build collections page.
9. Build hadith detail page.
10. Add daily hadith on Home.
11. Add bookmarks.
12. Add source attribution in UI.
13. Add tests for parsing/search.
14. Run analyze.

Relevant files:

- `lib/features/hadith/*`
- `assets/hadith/*`

### Milestone 10: Mosque Locator

Goal: Find nearby mosques and open directions.

Tasks:

1. Choose provider: Google Places, Apple/Google Maps query links, or OpenStreetMap Overpass.
2. Document API key/cost/privacy tradeoffs.
3. Add mosque entity.
4. Create location-based repository.
5. Create `MosqueLocatorBloc`.
6. Build permission-first screen.
7. Build nearby mosque list.
8. Add distance and directions.
9. Add map deep link.
10. Add fallback manual search.
11. Add tests for distance sorting.
12. Run analyze.

Relevant files:

- `lib/features/mosque_locator/*`
- `lib/core/location/*`

### Milestone 11: Polish, QA, and Release Readiness

Goal: Stable, pleasant app ready for broader testing.

Tasks:

1. Audit all empty/loading/error states.
2. Audit RTL in Arabic and Urdu.
3. Audit font scaling.
4. Audit dark/black/light themes.
5. Audit permissions flows.
6. Audit offline behavior.
7. Add widget tests for core screens.
8. Add BLoC tests for critical flows.
9. Add integration smoke test.
10. Add app icon and splash.
11. Review Android permissions.
12. Review iOS permissions.
13. Run analyze.
14. Run tests.
15. Build Android debug.
16. Build iOS simulator if needed.

## 12. Bug Tracker

Use this table for every bug.

| ID | Status | Feature | Symptom | Root cause | Fix | Technique used | Files | Date |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BUG-001 | Open | Project setup | Root folder is not a git repository. | No `.git` folder found. | Decide whether to initialize git before implementation. | `git status --short` check. | Repo root | 2026-04-25 |
| BUG-002 | Fixed | Shared UI | `FeatureCard` crashed in `ListView` during widget test with unbounded height constraints. | `Spacer` was used inside a `Column` that can be laid out with unbounded vertical constraints. | Replaced `Spacer` with fixed spacing and set `mainAxisSize: MainAxisSize.min`. | Widget test failure analysis; Flutter render exception pointed to `feature_card.dart`. | `lib/core/widgets/feature_card.dart`, `test/widget_test.dart` | 2026-04-25 |
| BUG-003 | Fixed | Quran tests | Data source test failed expecting ASCII `Al-Fatihah`; package returns transliterated `Al-Fātiḥah`. | Test assumed ASCII transliteration instead of accepting source metadata spelling. | Changed assertion to validate a stable prefix and keep exact source data unchanged. | Repository test failure analysis; preserve source text instead of normalizing display names. | `test/features/quran/data/local_quran_data_source_test.dart` | 2026-04-25 |

Bug status values:

- `Open`
- `Investigating`
- `Fixed`
- `Verified`
- `Won't Fix`

Bug-fix technique log:

| Technique | Use when |
| --- | --- |
| `flutter analyze` | Static errors, unused imports, bad APIs. |
| `dart format` | Formatting drift after edits. |
| BLoC tests | State transitions, loading/error/success behavior. |
| Repository tests | Data parsing, cache behavior, source errors. |
| Widget tests | Navigation, settings toggles, empty/error UI. |
| Manual smoke test | Visual review and permission flows. |
| Source comparison | Prayer time and content validation against documented sources. |

## 13. Architecture Decision Log

| ID | Decision | Reason | Date |
| --- | --- | --- | --- |
| ADR-001 | Use BLoC/Cubit instead of GetX. | User requested BLoC architecture and it creates clear feature boundaries. | 2026-04-25 |
| ADR-002 | Reuse demo visual ideas, not demo state-management code. | Demo app is useful visually but GetX-heavy and finance-specific. | 2026-04-25 |
| ADR-003 | Use local-first Quran and prayer experiences. | Core worship features should work without network. | 2026-04-25 |
| ADR-004 | Keep heavy content in indexed storage, not simple preferences. | Quran, tafsir, and hadith search need better query performance. | 2026-04-25 |
| ADR-005 | Add source attribution for Islamic content. | Quran, tafsir, azkar, and hadith must be traceable and trustworthy. | 2026-04-25 |
| ADR-006 | Use `quran_with_tafsir` for initial Quran MVP data. | It is offline, pure Dart, and provides Arabic text, English translation, Arabic tafsir, metadata, search, page/juz navigation, and audio URL support behind our own repository boundary. | 2026-04-25 |
| ADR-007 | Move to database-first Islamic content. | Quran, tafsir, hadith, and azkar should come from credited bundled/downloadable datasets rather than hand-written app content. Dynamic features use calculation, sensors, or location APIs. | 2026-04-25 |

## 14. Quality Checklist

Before marking a feature `Done`:

- UI has loading, empty, error, and success states.
- UI works in light, dark, and black theme.
- Text does not overflow on small screens.
- Screen supports increased font scale.
- Screen is usable in RTL.
- BLoC/Cubit state is tested for critical paths.
- Repository parsing or calculation is tested.
- Feature files are listed in this tracker.
- Bugs found during work are added to the bug tracker.
- Bug fixes include the technique used.
- Islamic content source is recorded.

## 15. Open Questions

These need decisions before or during implementation:

1. Which exact Quran database should ship first: AlQuranDB, Tanzil-derived assets, fawazahmed0 Quran JSON, or current `quran_with_tafsir` package while we build import tooling?
2. Which languages should be fully supported in v1? Recommended start: English, Urdu, Arabic.
3. Should mosque locator use Google Places, OpenStreetMap, or only map deep links?
4. Which Hadith source should ship first after license review: fawazahmed0/hadith-api static JSON, AhmedBaset/hadith-json, Sunnah.com API, or a smaller curated collection?
5. Which prayer calculation method should be the default for the first launch? Suggested default can be based on user location, with manual override.
6. Should the app include audio recitation in v1 or after Quran text MVP?
7. Should user accounts/sync be deferred until after core offline features?

## 16. Recommended Roadmap Execution

Detailed sequence: `RECOMMENDED_NEXT_STEPS.md`

### Step 1: Content provenance and cache policy

Status: production implementation complete; source-owner release approvals remain external release gates.

Implemented:

- Added structured content kind, provider, edition, language, direction, publisher, retrieval mode, cache policy, and review status fields to `ContentSource`.
- Added `assets/data/content_sources/quran_sources.json` for bundled Quran text, Saheeh International, Al-Muyassar, Quran Foundation translations, word data, and timings.
- Added a reusable seven-day Quran Foundation cache policy.
- Timestamped translation catalog/verses, interlinear pages, and word timings.
- Expired cached responses and full-download markers are rejected and purged.
- Added cache expiry metadata interfaces without breaking repository fakes.
- Added Quran source, edition, license, review, and cache-policy display in Reader settings.
- Added translation download source and refresh-due messaging.
- No API secrets were added to the app.

External release gates:

- Obtain or document redistribution approval for bundled Quran, Saheeh International, and Al-Muyassar content.
- Use an approved Quran Foundation backend/authentication arrangement before production release.

Verification:

- `flutter analyze lib`: clean.
- Existing translation, interlinear, and timing repository checks: 19 passed.
- No tests authored or changed.

### Step 2: Independent content languages

Status: implemented.

- Added System UI language support without changing religious-content choices.
- Separated tafsir edition, word-meaning language, audio-meaning language, Hadith language, and Azkar language settings.
- Added a Settings management card for every independent language preference.
- Hadith and Azkar pickers now download their own content packs and never replace the Quran translation.
- Audio meaning preserves the prior Quran-linked choice once, then remains independent after an explicit selection.
- Tafsir uses its saved resource ID instead of following Quran translation.

### Step 3: First-run setup

Status: implemented.

- Added a six-step resumable onboarding route for UI language, Quran translation, prayer location, calculation method, Asr madhab, reading intent, notifications, and preview.
- Fresh installs enter setup; existing installs are not forced through it.
- Location permission has a rationale and denied users can search the bundled offline city database.
- Prayer times are previewed from the selected location and calculation settings before completion.
- Notification permission is requested only after its explanation.
- Settings provides an edit-mode setup route.

### Step 4: Reliability baseline

Status: production safeguards implemented; test-file changes deferred because the user instructed not to write or edit tests.

- Added a startup failure screen with safe retry and no local-data deletion.
- Added `QUALITY_SMOKE_CHECKLIST.md` covering startup, Home, reader, downloads, prayer, library, and user data.
- Critical repositories reject expired provider data and reader/download screens expose recovery information.
- `flutter analyze lib`: clean.
- `flutter build bundle --debug`: passed.
- Existing reader checks: 17 passed.
- Existing Quran audio checks: 11 passed.
- Existing audio download checks: 5 passed.
- Existing tafsir checks: 4 passed.
- No tests authored or changed.

### Step 5: Reading goals and plans

Status: implemented.

- Added verse, page, and minute goals based on real reader movement.
- Added forgiving streaks, one grace day, Home progress, Khatma pacing, catch-up, pause, and custom page plans.
- Initial reader load does not create false progress.

### Step 6: Hifz learning system

Status: implemented.

- Added Surah and ayah-range collections, due reviews, weak-Surah insight, reveal and first-word recall tools, and three-times audio playback.
- Added deterministic Again, Hard, Good, and Easy scheduling with local-only progress.

### Step 7: Collections, notes, and sharing

Status: implemented.

- Added colored bookmark collections, migration to a default collection, move and safe collection deletion.
- Added verse-linked private notes, note search, and exact verse deep links.
- Added attributed text sharing and locally rendered image cards with Arabic and translation choices.

### Step 8: Backup and privacy

Status: implemented.

- Added a versioned local backup envelope encrypted with AES-256-GCM and a PBKDF2-derived key.
- Added file export, import preview, deterministic merge or replace, malformed/newer-schema rejection, per-category erase, and typed full reset.
- Downloads and public content caches are excluded. Settings, Quran user data, reading, Hifz, prayer/fasting journal, and library activity are included.

### Step 9: Prayer and fasting journal

Status: implemented.

- Added daily on-time, late, missed, Qada, congregation, and exempt prayer states.
- Added adjustable Qada balance and daily plan without assigning a religious ruling.
- Added private cycle-pause ranges with exempt tracking and real prayer-reminder suppression.
- Added Ramadan, voluntary, and make-up fast logs plus weekly and monthly reflection summaries.
- Exempt pause dates are excluded from missed and Qada calculations, and all data is covered by backup and erase controls.

Verification for Steps 5 to 9:

- `flutter analyze lib`: clean.
- `flutter build bundle --debug`: passed.
- No tests authored or changed.

### Step 10: Quran structural navigation

Status: implemented.

- Added offline Surah, Juz, Hizb, Rub al-Hizb, pages 1 to 604, Sajdah, and traditional seven-Manzil indexes.
- Juz, page, Rub, Hizb, and Sajdah boundaries come from the bundled Quran package navigation metadata.
- Added browse chips, exact page jump, focused verse deep links, and compact structural markers in separated and continuous reader modes.
- Last read now retains the exact page, navigation context, focused verse, and saved reader layout. Backup merge preserves these fields.

Verification:

- `flutter analyze lib`: clean.
- Existing local Quran source and reader checks: 22 passed.
- Existing floating reader controls checks: 12 passed.
- `flutter build bundle --debug`: passed.
- No tests authored or changed.

### Step 11: Additional worship utilities

Status: implemented with one content-enrichment release gate.

- Added a dedicated offline Dua journey over the sourced Azkar corpus with categories, references, search, daily selection, and favorites.
- Added all 99 Names from `my-prayers/muslim-data` with Apache-2.0 attribution, transliteration, meanings, learned progress, and daily selection.
- Added an offline Zakat calculator with gold or silver Nisab, visible weights and price date, monetary asset categories, liabilities, and explicit scope disclaimer.
- Added a Ramadan dashboard with offline Suhoor and Iftar times, fasting status, Quran-goal progress, and a private last-ten-nights checklist.
- Added optional achievements derived locally from reading, prayer, Hifz, Names, and bookmark data. There are no accounts, leaderboards, analytics, or exemption penalties.
- Added OpenStreetMap mosque search using the saved prayer city, a 1 to 15 km radius, 50-result cap, 24-hour local cache, map handoff, offline/manual-city fallback, ODbL attribution, and non-exhaustive-results warning.
- Public mosque cache data is excluded from encrypted backup while private tool settings remain included through library user data.

Release gate:

- The Names source edition has no per-name verse references or licensed audio. Do not invent them. Add reviewed references and audio only from an approved licensed source, and complete scholarly review of English meaning wording before release.

Verification:

- Bundled Names dataset contains exactly 99 entries.
- `flutter analyze lib`: clean.
- `flutter build bundle --debug`: passed.
- No tests authored or changed.

### Step 12: Localization and translation platform

Status: platform implementation complete; native-language and content-license review remain release gates.

- Expanded matching English, Urdu, and Arabic ARB catalogs and localized the primary Settings, search, learning, backup, translation, and worship-tool entry points.
- Added System language and one-time locale-matched translation suggestion without overwriting an explicit content choice.
- Added ISO language, endonym, script, direction, translator, publisher, license, revision, source URL, checksum, and footnote-capability fields to translation editions.
- Added a searchable translation manager with up to three selected editions, primary-edition ordering, visible attribution, source metadata, cached size, download date, expiry, refresh, and delete controls.
- Added per-Surah translation packs and resumable full-pack orchestration. Fresh completed Surahs are skipped during retry.
- Verse mode renders multiple independently attributed translations. Continuous mode retains the selected primary edition.
- Downloaded-translation search is resource-aware, opens the matched edition, and rebuilds its local index when packs change.
- Translation pickers show endonym, edition, translator, direction, source host, and license terms.
- Added `LOCALIZATION_REVIEW_CHECKLIST.md` for native-speaker ARB review, mixed-direction UI, large text, edition licensing, Urdu source approval, and Nastaliq font review.

Release gates:

- Arabic and Urdu interface catalogs are drafts and require native-speaker review.
- Remaining hardcoded interface strings must be inventoried and migrated before claiming complete locale coverage.
- No approved redistributable Nastaliq font is bundled yet. Add one only after exact version, license, and UI review are recorded.
- Provider catalog data does not supply complete edition-specific publisher, license, revision, checksum, or footnote metadata for every resource. Do not imply stronger rights than the available source proves.
- Curated Urdu Quran editions and their wording require source-owner and scholarly approval.

Verification:

- ARB catalogs: 153 matching keys each; valid JSON.
- `flutter gen-l10n`: passed.
- `flutter analyze lib`: clean.
- Existing translation repository checks: 9 passed.
- Existing Quran reader checks: 17 passed.
- `flutter build bundle --debug`: passed.
- The older deep-search test fake no longer implements the current Hadith and Azkar repository interfaces. It was not edited because test changes were explicitly deferred.
- No tests authored or changed.
