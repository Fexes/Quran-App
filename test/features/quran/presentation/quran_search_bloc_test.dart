import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/quran/presentation/bloc/search/quran_search_bloc.dart';
import 'package:quran/features/quran/presentation/bloc/search/quran_search_event.dart';
import 'package:quran/features/quran/presentation/bloc/search/quran_search_state.dart';
import 'package:quran/features/search/domain/entities/deep_search_result.dart';
import 'package:quran/features/search/domain/repositories/deep_search_repository.dart';

void main() {
  group('QuranSearchBloc', () {
    test('returns grouped sections for a submitted query', () async {
      final bloc = QuranSearchBloc(repository: _FakeDeepSearchRepository());

      bloc.add(const QuranSearchSubmitted('الحمد'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<QuranSearchState>().having(
            (state) => state.status,
            'status',
            QuranSearchStatus.loading,
          ),
          isA<QuranSearchState>()
              .having(
                (state) => state.status,
                'status',
                QuranSearchStatus.success,
              )
              .having((state) => state.sections, 'sections', hasLength(1))
              .having(
                (state) => state.sections.single.results.single.target.verseKey,
                'verseKey',
                '1:2',
              ),
        ]),
      );

      await bloc.close();
    });

    test('emits empty for no results', () async {
      final bloc = QuranSearchBloc(repository: _FakeDeepSearchRepository());

      bloc.add(const QuranSearchSubmitted('missing'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<QuranSearchState>().having(
            (state) => state.status,
            'status',
            QuranSearchStatus.loading,
          ),
          isA<QuranSearchState>().having(
            (state) => state.status,
            'status',
            QuranSearchStatus.empty,
          ),
        ]),
      );

      await bloc.close();
    });

    test('filters visible sections by selected category', () async {
      final bloc = QuranSearchBloc(repository: _FakeDeepSearchRepository());

      bloc.add(const QuranSearchSubmitted('all'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const QuranSearchCategorySelected(DeepSearchCategory.notes));

      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<QuranSearchState>()
              .having(
                (state) => state.selectedCategory,
                'selectedCategory',
                DeepSearchCategory.notes,
              )
              .having(
                (state) => state.visibleSections.single.category,
                'visible category',
                DeepSearchCategory.notes,
              ),
        ),
      );

      await bloc.close();
    });

    test('starts repository warm up without emitting UI state', () async {
      final repository = _FakeDeepSearchRepository();
      final bloc = QuranSearchBloc(repository: repository);

      bloc.add(const QuranSearchWarmUpRequested());
      await Future<void>.delayed(Duration.zero);

      expect(repository.warmUpCalls, 1);
      expect(bloc.state.status, QuranSearchStatus.initial);

      await bloc.close();
    });
  });
}

class _FakeDeepSearchRepository implements DeepSearchRepository {
  int warmUpCalls = 0;

  @override
  Future<void> warmUp() async {
    warmUpCalls += 1;
  }

  @override
  Future<List<DeepSearchSection>> search(
    String query, {
    int limitPerCategory = 20,
  }) async {
    if (query == 'missing') {
      return const [];
    }
    if (query == 'all') {
      return const [
        DeepSearchSection(
          category: DeepSearchCategory.quran,
          totalCount: 1,
          results: [_quranResult],
        ),
        DeepSearchSection(
          category: DeepSearchCategory.notes,
          totalCount: 1,
          results: [_noteResult],
        ),
      ];
    }
    return const [
      DeepSearchSection(
        category: DeepSearchCategory.quran,
        totalCount: 1,
        results: [_quranResult],
      ),
    ];
  }
}

const _quranResult = DeepSearchResult(
  id: 'quran:1:2',
  category: DeepSearchCategory.quran,
  title: 'Al-Fatihah 1:2',
  subtitle: 'Juz 1 • Page 1',
  primaryText: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ',
  secondaryText: 'All praise is for Allah.',
  matchedField: 'quran text',
  score: 700,
  target: DeepSearchTarget(
    type: DeepSearchTargetType.quranAyah,
    surahNumber: 1,
    ayahNumber: 2,
  ),
);

const _noteResult = DeepSearchResult(
  id: 'note:1',
  category: DeepSearchCategory.notes,
  title: 'Note',
  subtitle: 'Saved note',
  primaryText: 'Remember this ayah',
  secondaryText: '',
  matchedField: 'note',
  score: 600,
  target: DeepSearchTarget(type: DeepSearchTargetType.note, noteId: '1'),
);
