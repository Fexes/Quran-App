import '../../../azkar/domain/repositories/azkar_repository.dart';
import '../../../hadith/domain/repositories/hadith_repository.dart';
import '../../../../core/search/deep_search_index_record.dart';
import '../../../quran/data/stores/quran_tafsir_store.dart';
import '../../../quran/data/stores/quran_translation_store.dart';
import '../../../quran/data/stores/quran_user_data_store.dart';
import '../../../quran/domain/entities/quran_ayah.dart';
import '../../../quran/domain/entities/quran_surah.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../domain/entities/deep_search_result.dart';
import '../../domain/repositories/deep_search_repository.dart';
import '../utils/search_text_normalizer.dart';

class LocalDeepSearchRepository implements DeepSearchRepository {
  LocalDeepSearchRepository({
    required QuranRepository quranRepository,
    required QuranTranslationStore translationStore,
    required QuranTafsirStore tafsirStore,
    required QuranUserDataStore userDataStore,
    required HadithRepository hadithRepository,
    required AzkarRepository azkarRepository,
  }) : _quranRepository = quranRepository,
       _translationStore = translationStore,
       _tafsirStore = tafsirStore,
       _userDataStore = userDataStore,
       _hadithRepository = hadithRepository,
       _azkarRepository = azkarRepository;

  final QuranRepository _quranRepository;
  final QuranTranslationStore _translationStore;
  final QuranTafsirStore _tafsirStore;
  final QuranUserDataStore _userDataStore;
  final HadithRepository _hadithRepository;
  final AzkarRepository _azkarRepository;

  static const _indexYieldInterval = 64;
  static const _searchYieldInterval = 512;

  Future<List<_SearchEntry>>? _indexFuture;
  int _indexedTranslationRevision = -1;

  @override
  Future<void> warmUp() async {
    await _currentIndex();
  }

  @override
  Future<List<DeepSearchSection>> search(
    String query, {
    int limitPerCategory = 20,
  }) async {
    final visibleQuery = SearchTextNormalizer.cleanVisibleText(query);
    final normalizedQuery = SearchTextNormalizer.normalize(visibleQuery);
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    final entries = await _currentIndex();
    final matches = <DeepSearchCategory, List<DeepSearchResult>>{};
    var scanned = 0;
    for (final entry in entries) {
      final scored = entry.score(normalizedQuery);
      if (scored == null) {
        scanned += 1;
        if (scanned % _searchYieldInterval == 0) {
          await _yieldToEventLoop();
        }
        continue;
      }
      if (entry.category == DeepSearchCategory.hadith &&
          !await _isVisibleHadithResult(entry)) {
        scanned += 1;
        if (scanned % _searchYieldInterval == 0) {
          await _yieldToEventLoop();
        }
        continue;
      }
      matches.putIfAbsent(entry.category, () => []).add(entry.toResult(scored));
      scanned += 1;
      if (scanned % _searchYieldInterval == 0) {
        await _yieldToEventLoop();
      }
    }

    return [
      for (final category in DeepSearchCategory.values)
        if (matches[category]?.isNotEmpty == true)
          _sectionFor(category, matches[category]!, limitPerCategory),
    ];
  }

  Future<List<_SearchEntry>> _currentIndex() {
    final revision = _translationStore.contentRevision;
    if (_indexFuture == null || revision != _indexedTranslationRevision) {
      _indexedTranslationRevision = revision;
      _indexFuture = _buildIndex();
    }
    return _indexFuture!;
  }

  Future<List<_SearchEntry>> _buildIndex() async {
    final entries = <_SearchEntry>[];
    final surahs = await _quranRepository.getSurahs();
    final surahByNumber = {for (final surah in surahs) surah.number: surah};
    var indexed = 0;

    for (final surah in surahs) {
      entries.add(_surahEntry(surah));
      indexed += 1;
      final ayahs = await _quranRepository.getAyahs(surah.number);
      for (final ayah in ayahs) {
        entries.add(_quranEntry(surah, ayah));
        indexed += 1;
        if (ayah.translation.trim().isNotEmpty) {
          entries.add(_translationEntry(surah, ayah, ayah.translation));
          indexed += 1;
        }
        final tafsir = ayah.tafsir?.trim();
        if (tafsir != null && tafsir.isNotEmpty) {
          entries.add(_tafsirEntry(surah, ayah, tafsir));
          indexed += 1;
        }
        if (indexed % _indexYieldInterval == 0) {
          await _yieldToEventLoop();
        }
      }
      await _yieldToEventLoop();
    }

    for (final translation in _translationStore.allCachedVerseTranslations()) {
      final target = _targetFromVerseKey(translation.verseKey);
      final surah = surahByNumber[target.$1];
      if (surah == null) {
        continue;
      }
      entries.add(
        _SearchEntry(
          id: 'translation:${translation.resourceId}:${translation.verseKey}',
          category: DeepSearchCategory.translation,
          title: '${surah.englishName} ${target.$2}',
          subtitle: [
            translation.languageName,
            translation.resourceName,
          ].whereType<String>().where((item) => item.isNotEmpty).join(' • '),
          primaryText: SearchTextNormalizer.cleanVisibleText(translation.text),
          secondaryText: translation.languageName ?? '',
          target: DeepSearchTarget(
            type: DeepSearchTargetType.quranAyah,
            surahNumber: target.$1,
            ayahNumber: target.$2,
            translationResourceId: translation.resourceId,
          ),
          fields: [
            _SearchField('verse key', translation.verseKey, boost: 980),
            _SearchField('translation', translation.text, boost: 640),
          ],
        ),
      );
      indexed += 1;
      if (indexed % _indexYieldInterval == 0) {
        await _yieldToEventLoop();
      }
    }

    for (final tafsir in _tafsirStore.allCachedVerseTafsirs()) {
      final target = _targetFromVerseKey(tafsir.verseKey);
      final surah = surahByNumber[target.$1];
      if (surah == null) {
        continue;
      }
      entries.add(
        _SearchEntry(
          id: 'tafsir:${tafsir.resourceId}:${tafsir.verseKey}',
          category: DeepSearchCategory.tafsir,
          title: '${surah.englishName} ${target.$2}',
          subtitle: tafsir.languageName ?? 'Cached tafsir',
          primaryText: SearchTextNormalizer.cleanVisibleText(tafsir.text),
          secondaryText: tafsir.languageName ?? '',
          target: DeepSearchTarget(
            type: DeepSearchTargetType.quranAyah,
            surahNumber: target.$1,
            ayahNumber: target.$2,
          ),
          fields: [
            _SearchField('verse key', tafsir.verseKey, boost: 980),
            _SearchField('tafsir', tafsir.text, boost: 630),
          ],
        ),
      );
      indexed += 1;
      if (indexed % _indexYieldInterval == 0) {
        await _yieldToEventLoop();
      }
    }

    for (final note in _userDataStore.notes) {
      entries.add(
        _SearchEntry(
          id: 'note:${note.id}',
          category: DeepSearchCategory.notes,
          title: 'Note',
          subtitle: 'Saved reflection',
          primaryText: note.text,
          secondaryText: '',
          target: DeepSearchTarget(
            type: DeepSearchTargetType.note,
            noteId: note.id,
          ),
          fields: [_SearchField('note', note.text, boost: 640)],
        ),
      );
      indexed += 1;
      if (indexed % _indexYieldInterval == 0) {
        await _yieldToEventLoop();
      }
    }

    final hadithRecords = await _hadithRepository.getSearchIndexRecords();
    for (final record in hadithRecords) {
      entries.add(_contentIndexEntry(record));
      indexed += 1;
      if (indexed % _indexYieldInterval == 0) {
        await _yieldToEventLoop();
      }
    }

    final azkarRecords = await _azkarRepository.getSearchIndexRecords();
    for (final record in azkarRecords) {
      entries.add(_contentIndexEntry(record));
      indexed += 1;
      if (indexed % _indexYieldInterval == 0) {
        await _yieldToEventLoop();
      }
    }

    return entries;
  }

  Future<bool> _isVisibleHadithResult(_SearchEntry entry) async {
    final id = entry.target.itemId;
    if (id == null || id.isEmpty) {
      return false;
    }
    return _hadithRepository.getHadithById(id).then((hadith) => hadith != null);
  }

  Future<void> _yieldToEventLoop() {
    return Future<void>.delayed(Duration.zero);
  }

  _SearchEntry _surahEntry(QuranSurah surah) {
    return _SearchEntry(
      id: 'surah:${surah.number}',
      category: DeepSearchCategory.surah,
      title: surah.englishName,
      subtitle: '${surah.revelationType} • ${surah.ayahCount} ayahs',
      primaryText: surah.arabicName,
      secondaryText: 'Surah ${surah.number}',
      target: DeepSearchTarget(
        type: DeepSearchTargetType.surah,
        surahNumber: surah.number,
      ),
      fields: [
        _SearchField('surah number', surah.number.toString(), boost: 1000),
        _SearchField('surah name', surah.englishName, boost: 880),
        _SearchField('arabic name', surah.arabicName, boost: 880),
      ],
    );
  }

  _SearchEntry _quranEntry(QuranSurah surah, QuranAyah ayah) {
    return _SearchEntry(
      id: 'quran:${ayah.verseKey}',
      category: DeepSearchCategory.quran,
      title: '${surah.englishName} ${ayah.number}',
      subtitle: 'Juz ${ayah.juz} • Page ${ayah.page}',
      primaryText: ayah.text,
      secondaryText: ayah.translation,
      target: DeepSearchTarget(
        type: DeepSearchTargetType.quranAyah,
        surahNumber: ayah.surahNumber,
        ayahNumber: ayah.number,
      ),
      fields: [
        _SearchField('verse key', ayah.verseKey, boost: 1000),
        _SearchField('quran text', ayah.text, boost: 720),
        _SearchField('surah name', surah.englishName, boost: 520),
      ],
    );
  }

  _SearchEntry _translationEntry(
    QuranSurah surah,
    QuranAyah ayah,
    String text,
  ) {
    return _SearchEntry(
      id: 'translation:bundled:${ayah.verseKey}',
      category: DeepSearchCategory.translation,
      title: '${surah.englishName} ${ayah.number}',
      subtitle: 'Bundled English translation',
      primaryText: text,
      secondaryText: ayah.text,
      target: DeepSearchTarget(
        type: DeepSearchTargetType.quranAyah,
        surahNumber: ayah.surahNumber,
        ayahNumber: ayah.number,
      ),
      fields: [
        _SearchField('verse key', ayah.verseKey, boost: 980),
        _SearchField('translation', text, boost: 640),
      ],
    );
  }

  _SearchEntry _tafsirEntry(QuranSurah surah, QuranAyah ayah, String text) {
    return _SearchEntry(
      id: 'tafsir:bundled:${ayah.verseKey}',
      category: DeepSearchCategory.tafsir,
      title: '${surah.englishName} ${ayah.number}',
      subtitle: 'Bundled tafsir',
      primaryText: text,
      secondaryText: ayah.text,
      target: DeepSearchTarget(
        type: DeepSearchTargetType.quranAyah,
        surahNumber: ayah.surahNumber,
        ayahNumber: ayah.number,
      ),
      fields: [
        _SearchField('verse key', ayah.verseKey, boost: 980),
        _SearchField('tafsir', text, boost: 630),
      ],
    );
  }

  _SearchEntry _contentIndexEntry(DeepSearchIndexRecord record) {
    final category = record.category == 'hadith'
        ? DeepSearchCategory.hadith
        : DeepSearchCategory.azkar;
    final targetType = category == DeepSearchCategory.hadith
        ? DeepSearchTargetType.hadith
        : DeepSearchTargetType.azkar;
    return _SearchEntry(
      id: record.id,
      category: category,
      title: record.title,
      subtitle: record.subtitle,
      primaryText: record.primaryPreview,
      secondaryText: record.secondaryPreview,
      target: DeepSearchTarget(type: targetType, itemId: record.targetId),
      fields: [
        _SearchField.normalized(
          category == DeepSearchCategory.hadith ? 'hadith text' : 'azkar text',
          record.normalizedText,
          boost: 620,
        ),
      ],
    );
  }

  DeepSearchSection _sectionFor(
    DeepSearchCategory category,
    List<DeepSearchResult> results,
    int limit,
  ) {
    results.sort((a, b) {
      final score = b.score.compareTo(a.score);
      if (score != 0) {
        return score;
      }
      return a.title.compareTo(b.title);
    });
    return DeepSearchSection(
      category: category,
      totalCount: results.length,
      results: results.take(limit).toList(growable: false),
    );
  }

  (int, int) _targetFromVerseKey(String verseKey) {
    final parts = verseKey.split(':');
    if (parts.length != 2) {
      return (0, 0);
    }
    return (int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0);
  }
}

class _SearchEntry {
  const _SearchEntry({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.primaryText,
    required this.secondaryText,
    required this.target,
    required this.fields,
  });

  final String id;
  final DeepSearchCategory category;
  final String title;
  final String subtitle;
  final String primaryText;
  final String secondaryText;
  final DeepSearchTarget target;
  final List<_SearchField> fields;

  _SearchScore? score(String normalizedQuery) {
    _SearchScore? best;
    for (final field in fields) {
      final score = field.score(normalizedQuery);
      if (score == null) {
        continue;
      }
      if (best == null || score.score > best.score) {
        best = score;
      }
    }
    return best;
  }

  DeepSearchResult toResult(_SearchScore scored) {
    return DeepSearchResult(
      id: id,
      category: category,
      title: title,
      subtitle: subtitle,
      primaryText: primaryText,
      secondaryText: secondaryText,
      matchedField: scored.fieldName,
      score: scored.score,
      target: target,
    );
  }
}

class _SearchField {
  _SearchField(this.name, String text, {required this.boost})
    : normalizedText = SearchTextNormalizer.normalize(text);

  const _SearchField.normalized(
    this.name,
    this.normalizedText, {
    required this.boost,
  });

  final String name;
  final String normalizedText;
  final int boost;

  _SearchScore? score(String normalizedQuery) {
    if (normalizedText.isEmpty || !normalizedText.contains(normalizedQuery)) {
      return null;
    }
    if (normalizedText == normalizedQuery) {
      return _SearchScore(name, boost + 200);
    }
    if (normalizedText.startsWith(normalizedQuery)) {
      return _SearchScore(name, boost + 100);
    }
    return _SearchScore(name, boost);
  }
}

class _SearchScore {
  const _SearchScore(this.fieldName, this.score);

  final String fieldName;
  final int score;
}
