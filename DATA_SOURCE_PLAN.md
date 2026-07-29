# Quran App Data Source Plan

Last updated: 2026-04-25

This file tracks the database/API choices for Islamic content. The goal is to avoid hand-writing religious content in the app and instead use credited, reusable, verifiable sources behind repository interfaces.

## Decision Summary

Use a local-first data strategy:

- Static Islamic content should come from bundled or downloadable databases.
- User-specific data should stay in app storage.
- Location/date/sensor features should use calculation services or APIs.
- Every Islamic content source must keep attribution and license notes.

## Recommended MVP Sources

| Feature | MVP source | Why | Storage |
| --- | --- | --- | --- |
| Quran Arabic text | Current `quran_with_tafsir` package first, then migrate/import from Tanzil or AlQuranDB after license review | Already integrated, offline, and avoids manual content entry now | Repository adapter now; SQLite/asset import later |
| Quran translation | Current `quran_with_tafsir` English first; add Urdu from AlQuranDB or fawazahmed0/quran-api after review | Keeps MVP stable while allowing language expansion | Same Quran repository boundary |
| Tafsir | `quran_with_tafsir` Al-Muyassar first | Already available offline through the package | Verse-key lookup |
| Hadith | fawazahmed0/hadith-api static JSON or AhmedBaset/hadith-json after license/source review | Avoids API keys and supports offline/downloadable content | Start as JSON asset or generated SQLite |
| Azkar | Hisnul Muslim/adhkar JSON source after license/source review | Azkar should work fully offline | JSON asset grouped by category |
| Prayer times | Local calculation package, with AlAdhan as reference/validation | Prayer times should work offline once location/settings are known | Cache monthly timetable |
| Islamic calendar | Local Hijri/Umm al-Qura package or AlAdhan calendar endpoint | Date changes over time and region settings matter | Cache monthly result, allow Hijri offset |
| Qibla | Device location + Kaaba bearing formula + compass sensor | No external content database needed | Cache last location only |
| Mosque locations | OpenStreetMap Overpass query for `amenity=place_of_worship` and `religion=muslim` | No key/cost for MVP; open data | Cache recent nearby search results |

## Source Candidates

### Quran

| Source | What it provides | Pros | Risks / checks |
| --- | --- | --- | --- |
| `quran_with_tafsir` | Offline Arabic text, English translation, Al-Muyassar tafsir, metadata, search, page/juz helpers | Already installed and wrapped by `QuranRepository`; fastest MVP route | Package content/license should be documented clearly before release |
| Tanzil | Verified Quran text and translations | Strong source for Arabic text; widely used | Translation terms vary; must respect attribution and non-commercial limits where applicable |
| AlQuranDB | Quran translations in JSON, CSV, SQLite, XML, XLSX, SQL | Good fit for database import pipeline | Need confirm exact repository/license and choose trusted editions |
| fawazahmed0/quran-api | Static JSON/CDN editions, many languages/translations | Easy to fetch or bundle selected editions; no app API key | Translation quality/source varies by edition; select only reviewed editions |
| Quran.com API | Verses, translations, tafsir, audio, word data | Excellent for rich online features and validation | Remote dependency and API access policy; not ideal as only MVP source |

Recommendation:

1. Keep `quran_with_tafsir` as the immediate MVP data source because it is already working locally.
2. Add a `ContentSource` attribution model before shipping Quran screens.
3. Build a database-import path later so Quran text, translations, and tafsir can be switched without touching UI/BLoC.

### Hadith

| Source | What it provides | Pros | Risks / checks |
| --- | --- | --- | --- |
| fawazahmed0/hadith-api | Static JSON endpoints, multiple languages, grades | No API key; can bundle selected files; good MVP source | Need verify references and decide which books/languages to expose first |
| AhmedBaset/hadith-json | Large JSON database, 17 books including the nine books | Broad coverage, Arabic and English | Scraped origin and license/source review required |
| Sunnah.com API | Known hadith source/API | Familiar content and references | Requires API key and may not expose everything needed |

Recommendation:

1. Start with a small bundled Hadith dataset, not live API-only.
2. MVP collections: Sahih al-Bukhari and Sahih Muslim, or a smaller daily hadith curated set if app size matters.
3. Store hadith with book, chapter, number, Arabic, translation, grade, and source URL/reference.

### Azkar

Recommendation:

1. Use a credited Hisnul Muslim/adhkar JSON dataset after license review.
2. Store content as JSON first; SQLite is only needed if search and filters become heavy.
3. Required fields: id, category, Arabic text, translation, transliteration, repeat count, reference, source.

### Prayer Times

Recommendation:

1. Use local calculation for daily/monthly prayer times.
2. Support method, Asr school, high-latitude adjustment, time offsets, and location override.
3. Use AlAdhan as a comparison/reference source during testing, not as the only runtime provider.

### Islamic Calendar

Recommendation:

1. Use local Hijri/Umm al-Qura calculation if accuracy is acceptable for target regions.
2. Add manual Hijri day offset in settings.
3. Cache month data for home and calendar screens.

### Mosque Locations

Recommendation:

1. Use OpenStreetMap/Overpass for MVP.
2. Query nodes, ways, and relations around the user location using `amenity=place_of_worship` and `religion=muslim`.
3. Open directions through platform map links instead of embedding a full map in the first version.

## Target Data Architecture

```text
features/
  quran/
    data/
      datasources/
        local_quran_data_source.dart
        quran_database_data_source.dart
      repositories/
        quran_repository_impl.dart
    domain/
      repositories/
        quran_repository.dart

  hadith/
    data/
      datasources/
        local_hadith_data_source.dart
      repositories/
        hadith_repository_impl.dart
    domain/
      repositories/
        hadith_repository.dart

  azkar/
    data/
      datasources/
        local_azkar_data_source.dart
      repositories/
        azkar_repository_impl.dart
    domain/
      repositories/
        azkar_repository.dart
```

Rules:

- UI never reads assets/databases directly.
- BLoC talks to repository/use case only.
- Repository hides package/API/database details.
- Every content entity should carry or be traceable to source attribution.
- Large searchable content should move to SQLite/drift or sqflite after MVP.

## Import Pipeline Plan

Small steps:

1. Choose exact source and license for one content area.
2. Download or vendor only the needed source files.
3. Write a converter script to normalize fields.
4. Generate app-ready JSON or SQLite.
5. Add source metadata alongside generated data.
6. Add repository tests for parsing and search.
7. Update `PROJECT_TRACKER.md` with files, status, bugs, and fixes.

Suggested normalized Quran schema:

```text
surahs(
  number,
  arabic_name,
  english_name,
  revelation_type,
  ayah_count
)

ayahs(
  verse_key,
  surah_number,
  ayah_number,
  juz,
  page,
  text_arabic,
  text_simple,
  source_id
)

translations(
  verse_key,
  language_code,
  translator,
  text,
  source_id
)

tafsirs(
  verse_key,
  language_code,
  tafsir_name,
  text,
  source_id
)

content_sources(
  source_id,
  name,
  url,
  license,
  attribution
)
```

Suggested normalized Hadith schema:

```text
hadith_books(
  id,
  slug,
  name_en,
  name_ar,
  source_id
)

hadith_chapters(
  id,
  book_id,
  number,
  title_en,
  title_ar
)

hadiths(
  id,
  book_id,
  chapter_id,
  hadith_number,
  arabic,
  translation,
  grade,
  reference,
  source_id
)
```

## Immediate Next Step

Keep the current Quran MVP package for now and implement the missing `ContentSource` attribution layer. In parallel, choose the exact external Quran database for the future import path.

Preferred next implementation order:

1. Add `ContentSource` entity and source metadata for Quran.
2. Add source attribution display in Quran reader/tafsir bottom sheet.
3. Create Hadith feature repository interface before adding UI.
4. Import a small Hadith JSON sample through a local data source.
5. Add Azkar JSON source and category UI.

## References

- AlQuranDB: https://alqurandb.com/
- Tanzil translations: https://tanzil.net/trans
- Quran.com Verses API: https://api-docs.quran.com/docs/sdk/verses
- fawazahmed0 Quran API: https://github.com/fawazahmed0/quran-api
- fawazahmed0 Hadith API: https://github.com/fawazahmed0/hadith-api
- AhmedBaset Hadith JSON: https://github.com/AhmedBaset/hadith-json
- AlAdhan: https://aladhan.com/
- OpenStreetMap mosque tagging: https://wiki.openstreetmap.org/wiki/Mosque
