# Localization and Translation Release Checklist

Last updated: 2026-07-10

This checklist separates implemented platform behavior from review work that cannot be safely automated for release.

## Automated checks

- [x] English, Urdu, and Arabic ARB catalogs have matching key counts.
- [x] `flutter gen-l10n` succeeds.
- [x] System language is available and does not overwrite content choices.
- [x] Translation resources retain language code, endonym, script, direction, translator, publisher, license, revision, source URL, checksum, and footnote capability metadata.
- [x] Verse mode supports up to three attributed translations.
- [x] Continuous mode keeps one explicit primary translation.
- [x] Per-Surah downloads resume and can be refreshed or deleted.
- [x] Translation search records the resource that matched and rebuilds after pack changes.
- [x] Expired provider packs are rejected by the repository.

## Native-speaker review required

The Arabic and Urdu interface strings are drafts. A native reviewer must approve every ARB entry before release. Religious content is never machine translated by the app.

- [ ] Review meaning, tone, grammar, punctuation, and terminology in `app_ar.arb`.
- [ ] Review meaning, tone, grammar, punctuation, and terminology in `app_ur.arb`.
- [ ] Verify consistent terms for Surah, ayah, tafsir, translation, Hifz, Qada, Nisab, Suhoor, and Iftar.
- [ ] Verify that interface wording does not imply a religious ruling.
- [ ] Review plural, count, date, and relative-time wording in all three locales.
- [ ] Complete the remaining hardcoded-interface-string inventory and migrate approved strings to ARB before the locale is declared complete.

## Bidirectional UI review

Check English, Arabic, and Urdu at normal, 1.3x, and maximum supported text scale on a narrow phone and tablet-sized viewport.

- [ ] App shell, Home, Library, Settings, and onboarding.
- [ ] Quran browse, structural navigation, reader, settings sheets, verse actions, bookmarks, notes, and share preview.
- [ ] Translation picker, comparison view, pack manager, progress, retry, expiry, update, and delete dialogs.
- [ ] Quran search with Arabic-only, Latin-only, Urdu-only, numeric, and mixed-script queries.
- [ ] Prayer setup, prayer page, Qibla, journal, Ramadan, and mosque results.
- [ ] Hadith, Azkar, Duas, Names, Tasbieh, Hifz, reading goals, Zakat, achievements, backup, restore, and erase flows.
- [ ] Mixed Arabic and Latin edition names, citations, URLs, verse keys, dates, percentages, and file names.
- [ ] Dialog action order, back affordance, dropdown alignment, horizontal chips, and progress indicators in RTL.
- [ ] Text and image share output preserve Arabic order, translation direction, citation, and attribution.
- [ ] No clipped, overlapping, ellipsized-critical, or horizontally scrolling essential text.

## Content and font release gates

- [ ] Obtain written approval for every redistributed Quran or translation edition.
- [ ] Replace generic provider-terms metadata with edition-specific license, publisher, revision, checksum, and footnote data where the provider does not supply it.
- [ ] Approve at least one reviewed Urdu edition for production.
- [ ] Select and approve a redistributable Nastaliq-capable Urdu font, such as an OFL release, record its exact version and license, bundle it, and expose the preference only after visual review.
- [ ] Scholar-review Urdu Quran wording, footnotes, and edition attribution. Do not merge editions or auto-translate missing verses.
- [ ] Verify Quran Foundation authentication and cache terms through the approved production access path.

## Manual result log

Record reviewer, locale, platform, viewport, text scale, build identifier, date, failures, and retest result here before release.
