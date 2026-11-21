import 'dart:async';
import 'dart:convert';

import '../../../../app/router/app_routes.dart';
import '../../../../core/search/local_search_revision.dart';
import '../../../../core/search/search_text_normalizer.dart';
import '../../../../core/storage/settings_store.dart';
import '../../../azkar/domain/repositories/azkar_repository.dart';
import '../../../hadith/data/stores/hadeeth_enc_store.dart';
import '../../../hadith/data/stores/hadith_translation_store.dart';
import '../../../hadith/domain/entities/hadith_item.dart';
import '../../../hadith/domain/repositories/hadith_repository.dart';
import '../../../hadith/domain/services/hadith_authenticity_policy.dart';
import '../../../hifz/data/stores/hifz_store.dart';
import '../../../home/domain/entities/home_tile.dart';
import '../../../home/domain/services/daily_ayah_service.dart';
import '../../../library/data/stores/library_user_data_store.dart';
import '../../../prayer_tracking/data/stores/prayer_tracking_store.dart';
import '../../../quran/data/stores/quran_tafsir_store.dart';
import '../../../quran/data/stores/quran_interlinear_words_store.dart';
import '../../../quran/domain/entities/quran_word.dart';
import '../../../quran/domain/entities/quran_translation.dart';
import '../../../quran/data/stores/quran_translation_store.dart';
import '../../../quran/data/stores/quran_user_data_store.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../../quran_audio/data/stores/quran_audio_download_store.dart';
import '../../../reading_goals/data/stores/reading_progress_store.dart';
import '../../../worship_tools/domain/repositories/divine_names_repository.dart';
import '../../domain/entities/offline_search_result.dart';
import '../../domain/entities/search_document.dart';

/// Register new local features here or through [register]. Each source owns its
/// IDs and emits a complete snapshot; removing an item removes its search copy.
class AppSearchSourceRegistry {
  AppSearchSourceRegistry([Iterable<SearchContentSource> sources = const []]) {
    for (final source in sources) {
      register(source);
    }
  }

  final _sources = <String, SearchContentSource>{};
  final _retired = <String>{};
  Iterable<SearchContentSource> get sources =>
      List.unmodifiable(_sources.values);

  void register(SearchContentSource source) {
    if (_sources.containsKey(source.id) && !_retired.remove(source.id)) {
      throw StateError('Search source already registered: ${source.id}');
    }
    _sources[source.id] = source;
    LocalSearchRevision.changed(source: source.id);
  }

  /// Keep an empty source snapshot until the engine has removed its documents.
  void unregister(String id) {
    if (!_sources.containsKey(id)) return;
    _retired.add(id);
    _sources[id] = LocalStoreSearchSource(
      id: id,
      read: () => const Stream.empty(),
      snapshot: () => const [],
    );
    LocalSearchRevision.changed(source: id);
  }
}

/// A reusable adapter for features that already own a local content store.
class LocalStoreSearchSource implements SearchContentSource {
  LocalStoreSearchSource({
    required this.id,
    required Stream<SearchDocument> Function() read,
    String Function()? revision,
    Object? Function()? snapshot,
    DateTime? Function()? nextExpiry,
  }) : _read = read,
       _revision = revision,
       _snapshot = snapshot,
       _nextExpiry = nextExpiry;

  @override
  final String id;
  final Stream<SearchDocument> Function() _read;
  final String Function()? _revision;
  final Object? Function()? _snapshot;
  final DateTime? Function()? _nextExpiry;
  DateTime? _expiresAt;
  int _expiryRevision = 0;
  String? _snapshotMutation;
  String? _snapshotRevision;

  @override
  String get revision {
    var expired = false;
    if (_expiresAt case final expiry?) {
      if (!DateTime.now().isBefore(expiry)) {
        expired = true;
        _expiryRevision++;
        _expiresAt = null;
      }
    }
    if (_snapshot case final snapshot?) {
      final mutation = LocalSearchRevision.forSource(id);
      if (_snapshotRevision == null ||
          _snapshotMutation != mutation ||
          expired) {
        _snapshotRevision =
            'store-v4:${LocalSearchRevision.fingerprint(snapshot())}';
        _snapshotMutation = mutation;
        // Required even when a persisted completed revision skips documents().
        _expiresAt = _nextExpiry?.call();
      }
      return _snapshotRevision!;
    }
    return '${_revision?.call() ?? LocalSearchRevision.forSource(id)}:$_expiryRevision';
  }

  @override
  Stream<List<SearchDocument>> documents() async* {
    var batch = <SearchDocument>[];
    await for (final document in _read()) {
      batch.add(document);
      if (batch.length >= 64) {
        yield batch;
        batch = [];
        await Future<void>.delayed(Duration.zero);
      }
    }
    if (batch.isNotEmpty) yield batch;
    // A persisted snapshot records its deadline before enumeration. Retain an
    // expiry that passed during a long sync so the coordinator immediately
    // removes those records instead of postponing until the next deadline.
    if (_snapshot == null) _expiresAt = _nextExpiry?.call();
  }
}

AppSearchSourceRegistry createAppSearchSources({
  required QuranRepository quran,
  required QuranTranslationStore translations,
  required QuranTafsirStore tafsirs,
  required QuranInterlinearWordsStore interlinear,
  required QuranUserDataStore quranUser,
  required HadithRepository hadith,
  required HadithTranslationStore hadithTranslations,
  required HadeethEncStore hadeethEnc,
  required AzkarRepository azkar,
  required LibraryUserDataStore libraryUser,
  required HifzStore hifz,
  required ReadingProgressStore reading,
  required PrayerTrackingStore journal,
  required QuranAudioDownloadStore audio,
  required SettingsStore settings,
  required DivineNamesRepository divineNames,
}) {
  return AppSearchSourceRegistry([
    LocalStoreSearchSource(
      id: 'quran-translations',
      snapshot: translations.searchSnapshot,
      nextExpiry: () => translations.nextSearchExpiry,
      read: () async* {
        final resources = {
          for (final resource in translations.catalog()) resource.id: resource,
        };
        final selected = translations.selectedResource();
        if (selected != null) resources[selected.id] = selected;
        for (final verse in translations.allCachedVerseTranslations()) {
          final target = _verse(verse.verseKey);
          if (target == null) continue;
          final resource = resources[verse.resourceId];
          final language = _languageCode(
            resource?.resolvedLanguageCode.isNotEmpty == true
                ? resource!.resolvedLanguageCode
                : verse.languageName,
          );
          final source =
              verse.resourceName ?? 'Translation ${verse.resourceId}';
          final passage = OfflineSearchPassage(
            canonicalId: 'quran:${verse.verseKey}',
            kind: 'quran',
            reference: 'Quran ${verse.verseKey}',
            title: 'Quran ${verse.verseKey}',
            arabic: '',
            translations: [
              OfflineSearchTranslation(
                language: language,
                text: verse.text,
                source: source,
              ),
            ],
            grades: const [],
            surahNumber: target.$1,
            ayahNumber: target.$2,
            language: language,
            sourceLabel: source,
            route: AppRoutes.quranReaderPath(
              target.$1,
              ayahNumber: target.$2,
              translationResourceId: verse.resourceId,
            ),
            metadata: {'translationResourceId': '${verse.resourceId}'},
          );
          yield SearchDocument(
            id: 'translation:${verse.resourceId}:${verse.verseKey}',
            passage: passage,
            text: SearchTextNormalizer.cleanVisibleText(verse.text),
            language: language,
          );
        }
      },
    ),
    LocalStoreSearchSource(
      id: 'interlinear',
      snapshot: interlinear.searchSnapshot,
      nextExpiry: () => interlinear.nextSearchExpiry,
      read: () async* {
        for (final page in interlinear.cachedSearchPages()) {
          final verses = <String, List<QuranWord>>{};
          for (final word in page.words) {
            (verses[word.verseKey] ??= []).add(word);
          }
          for (final entry in verses.entries) {
            final target = _verse(entry.key);
            if (target == null) continue;
            final words = entry.value
              ..sort((a, b) => a.wordIndex.compareTo(b.wordIndex));
            final body = words
                .where((word) => word.translation.trim().isNotEmpty)
                .map((word) => '${word.arabicText}: ${word.translation}')
                .join('\n');
            if (body.isEmpty) continue;
            yield _document(
              'interlinear:${page.language}:${page.page}:${entry.key}',
              'quran',
              'Word meanings • Quran ${entry.key}',
              body,
              AppRoutes.quranReaderPath(target.$1, ayahNumber: target.$2),
              reference: 'Quran ${entry.key}',
              language: page.language,
              source: 'Quran word meanings',
              metadata: {'page': '${page.page}', 'verseKey': entry.key},
            );
          }
        }
      },
    ),
    LocalStoreSearchSource(
      id: 'tafsir',
      snapshot: tafsirs.searchSnapshot,
      nextExpiry: () => tafsirs.nextSearchExpiry,
      read: () async* {
        for (final verse in tafsirs.allCachedVerseTafsirs()) {
          final target = _verse(verse.verseKey);
          if (target == null) continue;
          final source = verse.resourceName ?? 'Tafsir ${verse.resourceId}';
          yield _document(
            'tafsir:${verse.resourceId}:${verse.verseKey}',
            'tafsir',
            '$source • ${verse.verseKey}',
            verse.text,
            '${AppRoutes.quranReaderPath(target.$1, ayahNumber: target.$2)}&tafsir=${verse.resourceId}',
            reference: 'Quran ${verse.verseKey}',
            source: source,
            language: _languageCode(verse.languageName),
            metadata: {
              'tafsirResourceId': '${verse.resourceId}',
              'verseKey': verse.verseKey,
            },
          );
        }
      },
    ),
    LocalStoreSearchSource(
      id: 'hadith-translations',
      snapshot: () => {
        'gradingVersion': 1,
        'content': hadithTranslations.searchSnapshot(),
      },
      read: () async* {
        for (final pack in hadithTranslations.cachedPackKeys) {
          final translated = hadithTranslations.translationsForBook(
            bookId: pack.bookId,
            languageCode: pack.languageCode,
          );
          // Repository enumeration enforces the reader's visibility policy.
          for (var offset = 0; ; offset += 128) {
            final items = await hadith.getHadiths(
              bookId: pack.bookId,
              offset: offset,
              limit: 128,
            );
            for (final item in items) {
              final text = translated[item.hadithNumber];
              if (text == null ||
                  text.trim().isEmpty ||
                  !HadithAuthenticityPolicy.shouldShow(item)) {
                continue;
              }
              yield SearchDocument(
                id: '${item.id}:translation:${pack.languageCode}',
                passage: _hadithPassage(item, text, pack.languageCode),
                text: '${item.reference}\n$text',
                language: pack.languageCode,
              );
            }
            if (items.length < 128) break;
          }
        }
      },
    ),
    LocalStoreSearchSource(
      id: 'hadeethenc',
      snapshot: () => {
        'gradingVersion': 1,
        'content': hadeethEnc.searchSnapshot(),
      },
      read: () async* {
        for (final language in hadeethEnc.downloadedLanguageCodes()) {
          for (final item in hadeethEnc.cachedSearchItems(language)) {
            final base = item.toHadithItem();
            if (!HadithAuthenticityPolicy.shouldShow(base)) continue;
            final body = [
              item.explanation,
              ...item.benefits,
            ].where((text) => text.trim().isNotEmpty).join('\n\n');
            final passage = OfflineSearchPassage(
              canonicalId: 'hadeethenc:${item.id}',
              kind: 'hadith',
              title: item.title,
              reference: base.reference,
              arabic: item.hadithTextArabic,
              translations: [
                OfflineSearchTranslation(
                  language: language,
                  text: item.hadithText,
                  source: 'HadeethEnc',
                ),
              ],
              grades: _grades(base),
              body: body,
              language: language,
              sourceLabel: 'HadeethEnc',
              itemId: base.id,
              route: '',
              metadata: {
                'sourceUrl': item.link,
                'attribution': item.attribution,
                'bookId': base.bookId,
                'sourceId': base.sourceId,
              },
            );
            yield SearchDocument(
              id: 'hadeethenc:$language:${item.id}',
              passage: passage,
              text:
                  '${item.title}\n${item.hadithText}\n$body\n${item.hadithTextArabic}\n${item.explanationArabic}\n${item.benefitsArabic.join('\n')}',
              language: language,
            );
          }
        }
      },
    ),
    LocalStoreSearchSource(
      id: 'azkar',
      revision: () => 'bundled-azkar-v4',
      read: () async* {
        for (final language in await azkar.availableTranslationLanguages()) {
          if (language == 'en') continue;
          for (final category in await azkar.getCategories()) {
            for (var offset = 0; ; offset += 64) {
              final items = await azkar.getDhikr(
                categoryId: category.id,
                languageCode: language,
                offset: offset,
                limit: 64,
              );
              for (final item in items) {
                if (language != 'en' && item.translation.trim().isEmpty) {
                  continue;
                }
                final passage = OfflineSearchPassage(
                  canonicalId: item.id,
                  kind: 'azkar',
                  title: item.title.isEmpty ? category.englishName : item.title,
                  reference: item.reference,
                  arabic: item.arabic,
                  translations: [
                    if (item.translation.isNotEmpty)
                      OfflineSearchTranslation(
                        language: language,
                        text: item.translation,
                        source: item.sourceId,
                      ),
                  ],
                  grades: const [],
                  body: [
                    item.notes,
                    item.benefit,
                  ].where((text) => text.isNotEmpty).join('\n'),
                  itemId: item.id,
                  sourceLabel: item.sourceId,
                  language: language,
                  route:
                      '${AppRoutes.azkarCategoryPath(category.id, itemId: item.id)}&language=${Uri.encodeQueryComponent(language)}',
                  metadata: {
                    'repeatCount': '${item.repeatCount}',
                    'transliteration': item.transliteration,
                  },
                );
                yield SearchDocument(
                  id: '${item.id}:$language',
                  passage: passage,
                  text:
                      '${category.englishName}\n${item.title}\n${item.arabic}\n${item.translation}\n${item.transliteration}\n${item.notes}\n${item.benefit}\n${item.reference}',
                  language: language,
                );
              }
              if (items.length < 64) break;
            }
          }
        }
      },
    ),
    LocalStoreSearchSource(
      id: 'quran-user',
      snapshot: quranUser.exportSnapshot,
      read: () async* {
        for (final note in quranUser.notes) {
          yield _document(
            'note:quran:${note.id}',
            'notes',
            'My Quran note${note.verseKey == null ? '' : ' • ${note.verseKey}'}',
            note.text,
            AppRoutes.quranNotesPath(noteId: note.id),
            user: true,
            reference: note.verseKey ?? '',
            metadata: {'updatedAt': note.updatedAt.toIso8601String()},
          );
        }
        final collections = {
          for (final collection in quranUser.bookmarkCollections)
            collection.id: collection,
        };
        for (final collection in collections.values) {
          yield _document(
            'collection:quran:${collection.id}',
            'saved',
            collection.name,
            collection.description,
            AppRoutes.quranBookmarksPath(),
            user: true,
            terms: 'My saved Quran bookmark collection',
          );
        }
        for (final bookmark in quranUser.bookmarkEntries) {
          final ayahs = await quran.getAyahs(bookmark.surahNumber);
          final ayah = ayahs
              .where((ayah) => ayah.number == bookmark.ayahNumber)
              .firstOrNull;
          if (ayah == null) continue;
          final collection =
              collections[bookmark.collectionId]?.name ?? 'Saved ayahs';
          yield _document(
            'saved:quran:${bookmark.collectionId}:${bookmark.verseKey}',
            'saved',
            '$collection • Quran ${bookmark.verseKey}',
            '${ayah.text}\n${ayah.translation}',
            AppRoutes.quranReaderPath(
              bookmark.surahNumber,
              ayahNumber: bookmark.ayahNumber,
            ),
            reference: 'Quran ${bookmark.verseKey}',
            user: true,
            terms: 'My bookmark saved verse',
          );
        }
        final surah = quranUser.lastReadSurah;
        final ayah = quranUser.lastReadAyah;
        if (surah != null && ayah != null) {
          yield _document(
            'reading:last',
            'saved',
            'Continue reading • Quran $surah:$ayah',
            'Last read Quran $surah:$ayah${quranUser.lastReadPage == null ? '' : ', page ${quranUser.lastReadPage}'}.',
            AppRoutes.quranReaderPath(surah, ayahNumber: ayah),
            user: true,
            terms: 'where did I stop last reading resume my Quran',
          );
        }
      },
    ),
    LocalStoreSearchSource(
      id: 'library-user',
      snapshot: libraryUser.exportSnapshot,
      read: () async* {
        for (final note in libraryUser.notes.entries) {
          final target = await _libraryTarget(
            note.key,
            hadith,
            azkar,
            divineNames,
          );
          if (target == null) continue;
          yield _document(
            'note:library:${note.key}',
            'notes',
            'My note • ${target.$1}',
            note.key == 'worship-tools:zakat-inputs'
                ? _zakatDraft(note.value)
                : note.value,
            target.$2,
            user: true,
            reference: target.$1,
          );
        }
        for (final key in libraryUser.bookmarkedItemKeys) {
          final target = await _libraryTarget(key, hadith, azkar, divineNames);
          if (target == null) continue;
          yield _document(
            'saved:library:$key',
            'saved',
            target.$1,
            target.$3,
            target.$2,
            user: true,
            terms: 'My saved bookmark favorite',
          );
        }
      },
    ),
    LocalStoreSearchSource(
      id: 'hifz',
      snapshot: hifz.exportSnapshot,
      read: () async* {
        for (final collection in hifz.collections) {
          yield _document(
            'hifz:collection:${collection.id}',
            'saved',
            collection.title,
            'Memorization collection: ${collection.verseKeys.join(', ')}',
            AppRoutes.hifzReviewPath(collection.id),
            user: true,
            terms: 'My hifz memorize memorisation revision learning Quran',
          );
        }
        for (final card in hifz.cards.values) {
          yield _document(
            'hifz:card:${card.verseKey}',
            'saved',
            'Memorization • Quran ${card.verseKey}',
            'Status: ${card.status.name}. Reviews: ${card.repetitions}. Lapses: ${card.lapses}. Review due: ${card.dueAt.toIso8601String()}.',
            AppRoutes.hifzPath(),
            user: true,
            reference: 'Quran ${card.verseKey}',
            metadata: {'verseKey': card.verseKey},
            terms: 'My hifz learning review progress',
          );
        }
      },
    ),
    LocalStoreSearchSource(
      id: 'reading',
      snapshot: reading.exportSnapshot,
      read: () async* {
        final goal = reading.goal;
        yield _document(
          'reading:goal',
          'saved',
          'My daily reading goal',
          '${goal.dailyTarget} ${goal.metric.name} each day. ${goal.enabled ? 'Enabled' : 'Paused'}.',
          AppRoutes.readingGoalsPath(),
          user: true,
          terms: 'reading target Quran progress',
        );
        final khatma = reading.khatma;
        if (khatma != null) {
          yield _document(
            'reading:khatma:${khatma.id}',
            'saved',
            'My Khatma plan',
            'Page ${khatma.currentPage} of 604. Target ${_date(khatma.targetDate)}. ${khatma.completed
                ? 'Completed'
                : khatma.paused
                ? 'Paused'
                : 'Active'}.',
            AppRoutes.readingGoalsPath(),
            user: true,
          );
        }
        for (final plan in reading.plans) {
          yield _document(
            'reading:plan:${plan.id}',
            'saved',
            plan.title,
            'Reading plan pages ${plan.startPage} to ${plan.endPage}. Current page ${plan.currentPage}. Target ${_date(plan.targetDate)}. ${plan.completed
                ? 'Completed'
                : plan.paused
                ? 'Paused'
                : 'Active'}.',
            AppRoutes.readingGoalsPath(),
            user: true,
          );
        }
        for (final day in reading.days.values) {
          yield _document(
            'reading:day:${day.dateKey}',
            'saved',
            'Reading progress • ${day.dateKey}',
            '${day.verseKeys.length} verses, ${day.pages.length} pages, ${day.minutes} minutes. Verses: ${day.verseKeys.join(', ')}.',
            AppRoutes.readingGoalsPath(),
            user: true,
          );
        }
      },
    ),
    LocalStoreSearchSource(
      id: 'journal',
      snapshot: () => {
        ...journal.exportSnapshot(),
        'searchPresentationVersion': 2,
      },
      read: () async* {
        for (final record in journal.prayerRecords) {
          yield _document(
            'journal:prayer:${record.dateKey}:${record.prayer.name}',
            'saved',
            '${record.prayer.name} • ${record.dateKey}',
            'Prayer journal: ${record.status.name}. ${record.congregation ? 'Prayed in congregation.' : ''}',
            AppRoutes.prayerTrackingPath(),
            user: true,
            terms: 'My namaz salah prayer history missed completed qada',
          );
        }
        for (final record in journal.fastingRecords) {
          yield _document(
            'journal:fast:${record.dateKey}',
            'saved',
            'Fasting • ${record.dateKey}',
            'Fasting journal: ${record.type.name}, ${record.status.name}.',
            AppRoutes.fastingJournalPath(
              date: DateTime.tryParse(record.dateKey),
            ),
            user: true,
            terms: 'My roza sawm fast Ramadan makeup history',
          );
        }
        final plan = journal.qadaPlan;
        if (plan.enabled) {
          yield _document(
            'journal:qada',
            'saved',
            'My Qada plan',
            'Baseline ${plan.baselineDue} missed prayers at ${_date(plan.baselineAt)}. Daily target ${plan.dailyTarget}.',
            AppRoutes.prayerTrackingPath(),
            user: true,
          );
        }
        for (final pause in journal.pauseRanges) {
          yield _document(
            'journal:pause:${pause.id}',
            'saved',
            'My worship tracking pause',
            '${pause.startDateKey} to ${pause.endDateKey}. ${pause.exemptTracking ? 'Exempt from tracking.' : ''} ${pause.suppressReminders ? 'Reminders paused.' : ''}',
            AppRoutes.prayerTrackingPath(),
            user: true,
          );
        }
      },
    ),
    LocalStoreSearchSource(
      id: 'audio',
      snapshot: audio.searchSnapshot,
      read: () async* {
        for (final item in audio.allItems) {
          yield _document(
            'audio:${item.id}',
            'saved',
            '${item.reciterName} • Quran ${item.verseKey}',
            'Audio recitation: ${item.status.name}. ${item.isDownloaded ? 'Available offline.' : 'Not available offline yet.'}',
            AppRoutes.quranDownloadsPath(),
            user: true,
            reference: 'Quran ${item.verseKey}',
            metadata: {'verseKey': item.verseKey},
            terms: 'My downloaded listening reciter recordings audio',
          );
        }
      },
    ),
    LocalStoreSearchSource(
      id: 'home-daily-ayah',
      revision: () =>
          'daily-ayah-v5:${_date(DateTime.now())}:${LocalSearchRevision.fingerprint(settings.homeTileIds)}',
      read: () async* {
        final daily = await const DailyAyahService().load(
          date: DateTime.now(),
          quranRepository: quran,
        );
        final verse = daily.ayah;
        yield SearchDocument(
          id: 'home:daily-ayah',
          language: 'en',
          passage: OfflineSearchPassage(
            canonicalId: 'quran:${verse.verseKey}',
            kind: 'quran',
            title: 'Today’s daily ayah • ${daily.surah.englishName}',
            reference: 'Quran ${verse.verseKey}',
            arabic: verse.text,
            translations: [
              OfflineSearchTranslation(
                language: 'en',
                text: verse.translation,
                source: 'Saheeh International',
              ),
            ],
            grades: const [],
            surahNumber: verse.surahNumber,
            ayahNumber: verse.number,
            route: AppRoutes.quranReaderPath(
              verse.surahNumber,
              ayahNumber: verse.number,
            ),
            sourceLabel: 'Daily ayah widget',
            metadata: {
              'date': _date(daily.date),
              'cardType': 'dailyAyah',
              'widgetId': HomeTile.dailyAyah.name,
              'widgetEnabled':
                  '${HomeTile.fromIds(settings.homeTileIds).contains(HomeTile.dailyAyah)}',
            },
          ),
          text:
              'Today daily ayah verse of the day home widget آیت اليوم آج کی آیت\n${verse.text}\n${verse.translation}',
        );
      },
    ),
    LocalStoreSearchSource(
      id: 'settings',
      snapshot: () => {
        'searchPresentationVersion': 4,
        'settings': settings.exportSnapshot(),
      },
      read: () async* {
        yield _document(
          'settings:tasbieh',
          'tools',
          'My Tasbieh counter',
          '${settings.tasbiehCount} of ${settings.tasbiehTarget} repetitions.',
          AppRoutes.tasbiehPath(),
          user: true,
          terms: 'dhikr zikr tasbih counter widget',
          metadata: {
            'featureId': 'tasbieh',
            'count': '${settings.tasbiehCount}',
            'target': '${settings.tasbiehTarget}',
          },
        );
        final enabled = HomeTile.fromIds(settings.homeTileIds);
        for (final feature in _features) {
          final widget = feature.widget;
          yield _document(
            'feature:${feature.id}',
            'tools',
            feature.title,
            '${feature.description}${widget == null ? '' : '\nHome widget: ${enabled.contains(widget) ? 'enabled' : 'available to add'}.'}',
            feature.route,
            terms: feature.terms,
            source: 'App feature',
            metadata: {
              'featureId': feature.id,
              if (widget != null) ...{
                'widgetId': widget.name,
                'widgetEnabled': '${enabled.contains(widget)}',
              },
            },
          );
        }
      },
    ),
  ]);
}

SearchDocument _document(
  String id,
  String kind,
  String title,
  String body,
  String route, {
  String reference = '',
  String source = '',
  bool user = false,
  String language = 'und',
  String terms = '',
  Map<String, String> metadata = const {},
}) => SearchDocument(
  id: id,
  passage: OfflineSearchPassage(
    canonicalId: id,
    kind: kind,
    reference: reference,
    title: title,
    arabic: '',
    translations: const [],
    grades: const [],
    body: body,
    route: route,
    language: language,
    sourceLabel: user ? 'Your content' : source,
    isUserContent: user,
    metadata: metadata,
  ),
  text: SearchTextNormalizer.cleanVisibleText(
    '$title\n$body\n$reference\n$terms',
  ),
  language: language,
);

OfflineSearchPassage _hadithPassage(
  HadithItem item,
  String text,
  String language,
) => OfflineSearchPassage(
  canonicalId: item.id,
  kind: 'hadith',
  reference: item.reference,
  title:
      '${item.collectionName.isEmpty ? item.bookId : item.collectionName} ${item.hadithNumber}',
  arabic: item.arabic,
  translations: [
    OfflineSearchTranslation(
      language: language,
      text: text,
      source: '${item.bookId} $language translation',
    ),
  ],
  grades: _grades(item),
  itemId: item.id,
  sourceLabel: item.sourceId,
  language: language,
  route:
      '${AppRoutes.hadithBookPath(item.bookId, hadithNumber: item.hadithNumber)}&language=${Uri.encodeQueryComponent(language)}',
  metadata: {
    'bookId': item.bookId,
    'sourceId': item.sourceId,
    'arabicEdition': item.arabicEdition,
    'englishEdition': item.englishEdition,
  },
);

List<OfflineHadithGrade> _grades(HadithItem item) {
  final grades = <OfflineHadithGrade>[];
  for (final entry in item.grades) {
    if (entry is Map && entry['grade'] is String) {
      final recorded = entry['grade'] as String;
      if (recorded.trim().isEmpty) continue;
      final name = entry['name'];
      grades.add(
        OfflineHadithGrade(
          grade: recorded,
          grader:
              (name is String && name.trim().isNotEmpty
                      ? name
                      : entry['grader'] ?? '')
                  .toString(),
        ),
      );
    } else if (entry is String && entry.trim().isNotEmpty) {
      // Preserve source strings such as "Scholar: Grade" without dropping
      // attribution or rewriting any scoped assessment.
      grades.add(OfflineHadithGrade(grade: entry, grader: ''));
    }
  }
  if (grades.isEmpty && item.grade.trim().isNotEmpty) {
    grades.add(OfflineHadithGrade(grade: item.grade, grader: ''));
  }
  return grades;
}

(int, int)? _verse(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final surah = int.tryParse(parts[0]);
  final ayah = int.tryParse(parts[1]);
  if (surah == null || surah < 1 || surah > 114 || ayah == null || ayah < 1) {
    return null;
  }
  return (surah, ayah);
}

String _date(DateTime value) => value.toIso8601String().split('T').first;

String _languageCode(String? value) {
  final normalized = value?.trim().toLowerCase() ?? '';
  final fromName = QuranTranslationResource(
    id: 0,
    languageName: normalized,
    name: '',
    authorName: '',
    slug: '',
  ).resolvedLanguageCode;
  if (fromName.isNotEmpty) return fromName;
  return RegExp(r'^[a-z]{2,3}(-[a-z0-9]{2,8})*$').hasMatch(normalized)
      ? normalized
      : 'und';
}

Future<(String, String, String)?> _libraryTarget(
  String key,
  HadithRepository hadith,
  AzkarRepository azkar,
  DivineNamesRepository divineNames,
) async {
  var normalized = key;
  if (normalized.startsWith('dua:')) normalized = normalized.substring(4);
  if (normalized.startsWith('hadith:') ||
      normalized.startsWith('hadeethenc:')) {
    final item = await hadith.getHadithById(normalized);
    if (item == null || !HadithAuthenticityPolicy.shouldShow(item)) return null;
    return (
      item.reference,
      item.bookId == 'hadeethenc'
          ? ''
          : AppRoutes.hadithBookPath(
              item.bookId,
              hadithNumber: item.hadithNumber,
            ),
      '${item.arabic}\n${item.translation}',
    );
  }
  if (normalized.startsWith('azkar:')) {
    final item = await azkar.getDhikrById(normalized);
    if (item == null) return null;
    return (
      item.title.isEmpty ? item.reference : item.title,
      AppRoutes.azkarCategoryPath(item.categoryId, itemId: item.id),
      '${item.arabic}\n${item.translation}',
    );
  }
  if (key.startsWith('divine-name:')) {
    final number = int.tryParse(key.split(':').last);
    final name = (await divineNames.all())
        .where((name) => name.number == number)
        .firstOrNull;
    if (name == null) return null;
    return (
      'Learned name • ${name.transliteration}',
      AppRoutes.divineNamesPath(),
      '${name.arabic}\n${name.meaning}',
    );
  }
  if (key.startsWith('ramadan-plan:')) {
    final parts = key.split(':');
    if (parts.length >= 4) {
      return (
        'Ramadan ${parts[1]} • night ${parts[2]}',
        AppRoutes.fastingPlanPath(),
        'Completed Ramadan action: ${parts.sublist(3).join(':')}',
      );
    }
  }
  if (key == 'worship-tools:zakat-inputs') {
    return ('My saved Zakat calculator values', AppRoutes.zakatPath(), '');
  }
  // Preserve explicitly user-authored notes for future local item types.
  return (key, '', '');
}

typedef _Feature = ({
  String id,
  String title,
  String description,
  String terms,
  String route,
  HomeTile? widget,
});
const _features = <_Feature>[
  (
    id: 'quran',
    title: 'Quran reader',
    description: 'Read all surahs, verses, pages, Juz, Hizb and translations.',
    terms: 'قرآن القران قران quran ayat surah',
    route: '/?tab=quran',
    widget: null,
  ),
  (
    id: 'library',
    title: 'Hadith and Azkar library',
    description:
        'Browse collections, chapters, narrations and daily supplications.',
    terms: 'حدیث حديث اذکار أذكار hadith dua',
    route: '/?tab=library',
    widget: null,
  ),
  (
    id: 'prayer',
    title: 'Prayer times',
    description:
        'Prayer schedule using your saved location and calculation settings.',
    terms: 'نماز namaz salah salat مواقيت الصلاة اوقات الصلاة timings widget',
    route: '/?tab=prayer',
    widget: null,
  ),
  (
    id: 'calendar',
    title: 'Islamic calendar',
    description: 'Open the prayer page for the Hijri calendar.',
    terms: 'date hijri ہجری تاريخ تقويم calendar widget',
    route: '/?tab=prayer',
    widget: HomeTile.islamicCalendar,
  ),
  (
    id: 'qibla',
    title: 'Qibla direction',
    description: 'Find the direction of the Kaaba from your location.',
    terms: 'قبلہ قبلة compass makkah mecca direction widget',
    route: AppRoutes.qibla,
    widget: HomeTile.qibla,
  ),
  (
    id: 'duas',
    title: 'Duas',
    description: 'Browse supplications, occasions and saved duas.',
    terms: 'دعا دعاء supplication prayers widget',
    route: AppRoutes.duas,
    widget: HomeTile.duas,
  ),
  (
    id: 'names',
    title: 'Names of Allah',
    description: 'Arabic names, meanings and source references.',
    terms: 'asma ul husna اسماء الحسنى اسماء اللہ widget',
    route: AppRoutes.divineNames,
    widget: HomeTile.divineNames,
  ),
  (
    id: 'bookmarks',
    title: 'Bookmarks and collections',
    description: 'Open saved verses and your named collections.',
    terms: 'saved favorites محفوظ bookmark widget',
    route: AppRoutes.quranBookmarks,
    widget: HomeTile.bookmarks,
  ),
  (
    id: 'notes',
    title: 'My notes',
    description: 'Find and edit your Quran notes and reflections.',
    terms: 'نوٹس ملاحظات personal writing journal widget',
    route: AppRoutes.quranNotes,
    widget: HomeTile.notes,
  ),
  (
    id: 'goals',
    title: 'Reading goals and plans',
    description: 'Daily progress, reading targets and Khatma plans.',
    terms: 'ختم ختمة goal streak daily Quran reading widget',
    route: AppRoutes.readingGoals,
    widget: HomeTile.todayReadingGoal,
  ),
  (
    id: 'hifz',
    title: 'Quran memorization',
    description: 'Memorization collections, review cards and progress.',
    terms: 'حفظ hifz memorize revision learning widget',
    route: AppRoutes.hifz,
    widget: HomeTile.hifz,
  ),
  (
    id: 'journal',
    title: 'Prayer journal',
    description: 'Track prayers, missed prayers, Qada and pauses.',
    terms: 'نماز نمازیں salah qada قضا prayer history widget',
    route: AppRoutes.prayerTracking,
    widget: HomeTile.prayerJournal,
  ),
  (
    id: 'fasts',
    title: 'Fasting journal',
    description: 'Your completed, missed and makeup fasts.',
    terms: 'روزه روزہ roza sawm fasting Ramadan قضاء صيام',
    route: AppRoutes.fastingJournal,
    widget: null,
  ),
  (
    id: 'ramadan',
    title: 'Fasting plan',
    description: 'Suhoor, Iftar, your fasting log and daily goals.',
    terms:
        'سحر افطار سحری iftar sehri suhoor Ramadan ramzan fasting plan widget روزوں کا منصوبہ خطة الصيام',
    route: AppRoutes.fastingPlan,
    widget: HomeTile.fasting,
  ),
  (
    id: 'zakat',
    title: 'Zakat calculator',
    description: 'Calculate Zakat with the values you provide.',
    terms: 'زکات زكاة charity nisab calculator',
    route: AppRoutes.zakat,
    widget: null,
  ),
  (
    id: 'mosques',
    title: 'Nearby mosques',
    description:
        'Find nearby mosques in Google Maps, Apple Maps, or your browser.',
    terms: 'مسجد masjid mosque near me widget',
    route: AppRoutes.mosques,
    widget: HomeTile.mosques,
  ),
  (
    id: 'downloads',
    title: 'Downloads',
    description: 'Manage local Quran audio and language downloads.',
    terms: 'offline downloaded recitation recordings translation languages',
    route: AppRoutes.quranDownloads,
    widget: null,
  ),
  (
    id: 'translations',
    title: 'Quran languages',
    description: 'Choose and download Quran translations.',
    terms: 'اردو urdu english Arabic language translation tafsir تفسیر ترجمہ',
    route: AppRoutes.quranTranslations,
    widget: null,
  ),
  (
    id: 'backup',
    title: 'Backup and restore',
    description: 'Back up and restore personal notes, bookmarks and progress.',
    terms: 'export import restore sync data',
    route: AppRoutes.backup,
    widget: null,
  ),
  (
    id: 'achievements',
    title: 'Achievements',
    description: 'View your reading and worship achievements.',
    terms: 'badges progress milestone streak',
    route: AppRoutes.achievements,
    widget: null,
  ),
  (
    id: 'settings',
    title: 'Settings and home widgets',
    description:
        'Language, theme, reader settings, prayer alerts and home tile preferences.',
    terms: 'customize widgets font dark mode notifications reminders reciter',
    route: '/?tab=settings',
    widget: null,
  ),
  (
    id: 'daily-ayah',
    title: 'Daily ayah widget',
    description: 'Read the daily verse on your home screen.',
    terms: 'today verse آیت اليوم widget',
    route: '/?tab=home',
    widget: HomeTile.dailyAyah,
  ),
];

String _zakatDraft(String text) {
  try {
    final values = jsonDecode(text);
    if (values is! Map) return text;
    return [
      'Saved calculator inputs (not a new calculation):',
      for (final entry in values.entries)
        if (entry.value is Map)
          for (final asset in (entry.value as Map).entries)
            '${asset.key}: ${asset.value}'
        else
          '${entry.key}: ${entry.value}',
    ].join('\n');
  } catch (_) {
    return text;
  }
}
