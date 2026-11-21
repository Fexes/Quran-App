import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quran/core/search/local_search_revision.dart';
import 'package:quran/features/quran_audio/domain/entities/quran_audio_state.dart';
import 'package:quran/features/quran_audio/presentation/cubit/quran_audio_cubit.dart';
import 'package:quran/features/search/domain/entities/offline_search_result.dart';
import 'package:quran/features/search/domain/repositories/offline_search_repository.dart';
import 'package:quran/features/search/presentation/pages/offline_search_page.dart';

void main() {
  testWidgets('typing does not search until explicitly submitted', (
    tester,
  ) async {
    final repository = _Repository();
    final audio = _IdleAudioCubit();
    addTearDown(audio.close);
    await tester.pumpWidget(_app(repository, audio));

    await tester.enterText(find.byType(TextField), 'patience in hardship');
    LocalSearchRevision.changed(source: 'notes');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 1));
    expect(repository.queries, isEmpty);

    await tester.tap(find.byKey(const Key('offline-search-submit')));
    await tester.pumpAndSettle();
    expect(repository.queries, ['patience in hardship']);
    expect(find.text(_quran.arabic), findsOneWidget);
    expect(find.text(_quran.translations.single.text), findsOneWidget);
    expect(find.text(_quran.reference), findsOneWidget);
  });

  testWidgets(
    'content changes refresh the submitted query, preserving drafts',
    (tester) async {
      final repository = _Repository();
      final audio = _IdleAudioCubit();
      addTearDown(audio.close);
      await tester.pumpWidget(
        _app(repository, audio, initialQuery: 'patience'),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'unfinished new question');

      LocalSearchRevision.changed(source: 'notes');
      LocalSearchRevision.changed(source: 'saved');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(repository.queries, ['patience', 'patience']);
      expect(find.text('unfinished new question'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(repository.queries, ['patience', 'patience', 'patience']);

      await tester.tap(find.byTooltip('Clear'));
      LocalSearchRevision.changed(source: 'notes');
      await tester.pump(const Duration(milliseconds: 300));
      expect(repository.queries, hasLength(3));
    },
  );

  testWidgets('shows source grades independently of result relevance', (
    tester,
  ) async {
    final repository = _Repository(passage: _hadith);
    final audio = _IdleAudioCubit();
    addTearDown(audio.close);
    await tester.pumpWidget(
      _app(repository, audio, initialQuery: 'intentions'),
    );
    await tester.pumpAndSettle();

    expect(find.text(_hadith.arabic), findsOneWidget);
    expect(find.text('Grade: Sahih (source grader)'), findsOneWidget);
    expect(find.text(_hadith.reference), findsOneWidget);
    expect(find.text(_hadith.canonicalId), findsOneWidget);
    expect(find.textContaining('ranked by relevance'), findsOneWidget);
    expect(find.textContaining('500 Quran verses'), findsNothing);
  });

  testWidgets('shows the downloaded edition that matched the query', (
    tester,
  ) async {
    final repository = _Repository(
      passage: OfflineSearchPassage(
        canonicalId: _quran.canonicalId,
        kind: _quran.kind,
        reference: _quran.reference,
        title: _quran.title,
        arabic: _quran.arabic,
        grades: const [],
        language: 'ur',
        sourceLabel: 'Matched Urdu edition',
        translations: [
          ..._quran.translations,
          const OfflineSearchTranslation(
            language: 'ur',
            text: 'Another downloaded translation',
            source: 'Other Urdu edition',
          ),
          const OfflineSearchTranslation(
            language: 'ur',
            text: 'The matching downloaded translation',
            source: 'Matched Urdu edition',
          ),
        ],
      ),
    );
    final audio = _IdleAudioCubit();
    addTearDown(audio.close);
    await tester.pumpWidget(_app(repository, audio, initialQuery: 'patience'));
    await tester.pumpAndSettle();
    expect(find.text('The matching downloaded translation'), findsOneWidget);
    expect(find.text('Another downloaded translation'), findsNothing);
    expect(find.text(_quran.translations.single.text), findsNothing);
  });

  testWidgets('shows readable downloaded content without HTML markup', (
    tester,
  ) async {
    final repository = _Repository(
      passage: const OfflineSearchPassage(
        canonicalId: 'tafsir:download:1:1',
        kind: 'tafsir',
        reference: 'Quran 1:1',
        title: 'Downloaded tafsir',
        arabic: '',
        body: '<p>Commentary &amp; explanation.</p>',
        language: 'en',
        translations: [
          OfflineSearchTranslation(
            language: 'en',
            text: '<p>Downloaded translation<sup>1</sup>.</p>',
            source: 'Downloaded edition',
          ),
        ],
        grades: [],
      ),
    );
    final audio = _IdleAudioCubit();
    addTearDown(audio.close);
    await tester.pumpWidget(
      _app(repository, audio, initialQuery: 'commentary'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Commentary & explanation.'), findsOneWidget);
    expect(find.textContaining('<p>'), findsNothing);
    expect(find.textContaining('<sup>'), findsNothing);
  });

  for (final passage in [_quran, _hadith, _surah]) {
    testWidgets('opens the exact ${passage.kind} source reference', (
      tester,
    ) async {
      final repository = _Repository(passage: passage);
      final audio = _IdleAudioCubit();
      addTearDown(audio.close);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => OfflineSearchPage(
              repository: repository,
              initialQuery: 'patience',
            ),
          ),
          GoRoute(
            path: '/quran/:surahNumber',
            builder: (context, state) => Scaffold(
              body: Text('Opened ${state.uri.path}?${state.uri.query}'),
            ),
          ),
          GoRoute(
            path: '/library/hadith/:bookId',
            builder: (context, state) => Scaffold(
              body: Text('Opened ${state.uri.path}?${state.uri.query}'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        BlocProvider<QuranAudioCubit>.value(
          value: audio,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(passage.reference));
      await tester.tap(find.text(passage.reference));
      await tester.pumpAndSettle();

      expect(
        find.text(switch (passage.kind) {
          'quran' => 'Opened /quran/2?ayah=153',
          'surah' => 'Opened /quran/2?',
          _ => 'Opened /library/hadith/bukhari?hadith=1',
        }),
        findsOneWidget,
      );
    });
  }
}

Widget _app(
  _Repository repository,
  QuranAudioCubit audio, {
  String? initialQuery,
}) => BlocProvider<QuranAudioCubit>.value(
  value: audio,
  child: MaterialApp(
    home: OfflineSearchPage(repository: repository, initialQuery: initialQuery),
  ),
);

const _quran = OfflineSearchPassage(
  canonicalId: 'quran:2:153',
  kind: 'quran',
  reference: 'Quran 2:153',
  title: 'Al-Baqarah',
  arabic: 'إِنَّ اللَّهَ مَعَ الصَّابِرِينَ',
  translations: [
    OfflineSearchTranslation(
      language: 'en',
      text: 'Indeed, Allah is with the patient.',
      source: 'Bundled translation',
    ),
  ],
  grades: [],
  surahNumber: 2,
  ayahNumber: 153,
);

const _hadith = OfflineSearchPassage(
  canonicalId: 'hadith:bukhari:1',
  kind: 'hadith',
  reference: 'Sahih al-Bukhari 1',
  title: 'Revelation',
  arabic: 'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ',
  translations: [
    OfflineSearchTranslation(
      language: 'en',
      text: 'Actions are according to intentions.',
      source: 'Bundled translation',
    ),
  ],
  grades: [OfflineHadithGrade(grade: 'Sahih', grader: 'source grader')],
  itemId: 'hadith:bukhari:1',
);

const _surah = OfflineSearchPassage(
  canonicalId: 'surah:2',
  kind: 'surah',
  reference: 'Surah 2',
  title: 'Al-Baqarah',
  arabic: 'البقرة',
  body: '286 verses',
  route: '/quran/2',
  translations: [],
  grades: [],
);

class _Repository implements OfflineSearchRepository {
  _Repository({this.passage = _quran});

  final OfflineSearchPassage passage;
  final queries = <String>[];

  @override
  Future<void> warmUp() async {}

  @override
  Future<OfflineSearchResponse> search(
    String query, {
    OfflineSearchFilter filter = OfflineSearchFilter.all,
    int limit = 20,
  }) async {
    queries.add(query);
    return OfflineSearchResponse(
      hits: [OfflineSearchHit(passage: passage, score: 0.7)],
      timingsMs: const {},
      semanticAvailable: true,
    );
  }

  @override
  Future<void> dispose() async {}
}

class _IdleAudioCubit extends Cubit<QuranAudioState>
    implements QuranAudioCubit {
  _IdleAudioCubit() : super(const QuranAudioState.initial());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
