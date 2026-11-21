import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/search/local_search_revision.dart';
import 'package:quran/features/search/domain/entities/offline_search_result.dart';
import 'package:quran/features/search/domain/repositories/offline_search_repository.dart';
import 'package:quran/features/search/presentation/cubit/offline_search_cubit.dart';

void main() {
  testWidgets('refreshes changes received while a submitted query is loading', (
    tester,
  ) async {
    final repository = _ControlledRepository();
    final cubit = OfflineSearchCubit(repository: repository);
    final first = cubit.submit('patience');
    LocalSearchRevision.changed(source: 'notes');
    await tester.pump(const Duration(milliseconds: 300));
    expect(repository.requests, hasLength(1));
    repository.requests.single.result.complete(_response);
    await first;
    await tester.pump(const Duration(milliseconds: 300));
    expect(repository.requests, hasLength(2));
    expect(repository.requests.last.query, 'patience');
    repository.requests.last.result.complete(_emptyResponse);
    await tester.pump();
    expect(cubit.state.status, OfflineSearchStatus.empty);

    LocalSearchRevision.changed(source: 'notes');
    await cubit.close();
    await tester.pump(const Duration(milliseconds: 300));
    LocalSearchRevision.changed(source: 'notes');
    await tester.pump(const Duration(milliseconds: 300));
    expect(repository.requests, hasLength(2));
  });

  test('ignores a completed search after a newer query is submitted', () async {
    final repository = _ControlledRepository();
    final cubit = OfflineSearchCubit(repository: repository);

    final first = cubit.submit('patience');
    final second = cubit.submit('kindness');
    repository.requests[1].result.complete(_response);
    await second;
    repository.requests[0].result.complete(_emptyResponse);
    await first;

    expect(cubit.state.query, 'kindness');
    expect(cubit.state.status, OfflineSearchStatus.success);
    expect(cubit.state.response, same(_response));
    await cubit.close();
    expect(repository.disposed, isFalse);
  });

  test('reruns the submitted query with the selected source filter', () async {
    final repository = _ControlledRepository();
    final cubit = OfflineSearchCubit(repository: repository);
    final search = cubit.submit(' patience ');
    repository.requests.single.result.complete(_response);
    await search;

    final filtered = cubit.selectFilter(OfflineSearchFilter.hadith);
    expect(repository.requests.last.query, 'patience');
    expect(repository.requests.last.filter, OfflineSearchFilter.hadith);
    repository.requests.last.result.complete(_emptyResponse);
    await filtered;

    expect(cubit.state.filter, OfflineSearchFilter.hadith);
    expect(cubit.state.status, OfflineSearchStatus.empty);
    await cubit.close();
  });

  test('clearing a query prevents pending results from returning', () async {
    final repository = _ControlledRepository();
    final cubit = OfflineSearchCubit(repository: repository);
    final search = cubit.submit('patience');
    cubit.clear();
    repository.requests.single.result.complete(_response);
    await search;

    expect(cubit.state.status, OfflineSearchStatus.initial);
    expect(cubit.state.query, isEmpty);
    expect(cubit.state.response, isNull);
    await cubit.close();
  });

  test(
    'does not search for blank input or filter changes before submission',
    () async {
      final repository = _ControlledRepository();
      final cubit = OfflineSearchCubit(repository: repository);

      await cubit.submit('   ');
      await cubit.selectFilter(OfflineSearchFilter.quran);

      expect(repository.requests, isEmpty);
      expect(cubit.state.filter, OfflineSearchFilter.quran);
      expect(cubit.state.status, OfflineSearchStatus.initial);
      await cubit.close();
    },
  );

  test('reports an error and allows a later retry', () async {
    final repository = _ControlledRepository();
    final cubit = OfflineSearchCubit(repository: repository);
    final search = cubit.submit('patience');
    repository.requests.single.result.completeError(
      StateError('model failure'),
    );
    await search;

    expect(cubit.state.status, OfflineSearchStatus.failure);
    expect(cubit.state.errorMessage, isNotEmpty);
    final retry = cubit.submit(cubit.state.query);
    repository.requests.last.result.complete(_response);
    await retry;
    expect(cubit.state.status, OfflineSearchStatus.success);
    await cubit.close();
  });

  test('does not emit results after the page cubit closes', () async {
    final repository = _ControlledRepository();
    final cubit = OfflineSearchCubit(repository: repository);
    final search = cubit.submit('patience');
    await cubit.close();
    repository.requests.single.result.complete(_response);
    await search;

    expect(cubit.isClosed, isTrue);
    expect(repository.disposed, isFalse);
  });
}

final _response = OfflineSearchResponse(
  hits: [
    OfflineSearchHit(
      passage: OfflineSearchPassage(
        canonicalId: 'quran:2:153',
        kind: 'quran',
        reference: 'Quran 2:153',
        title: 'Al-Baqarah',
        arabic: 'إِنَّ اللَّهَ مَعَ الصَّابِرِينَ',
        translations: [],
        grades: [],
        surahNumber: 2,
        ayahNumber: 153,
      ),
      score: 0.9,
    ),
  ],
  timingsMs: {},
  semanticAvailable: true,
);

final _emptyResponse = OfflineSearchResponse(
  hits: [],
  timingsMs: {},
  semanticAvailable: true,
);

class _Request {
  _Request(this.query, this.filter);

  final String query;
  final OfflineSearchFilter filter;
  final result = Completer<OfflineSearchResponse>();
}

class _ControlledRepository implements OfflineSearchRepository {
  final requests = <_Request>[];
  bool disposed = false;

  @override
  Future<void> warmUp() async {}

  @override
  Future<OfflineSearchResponse> search(
    String query, {
    OfflineSearchFilter filter = OfflineSearchFilter.all,
    int limit = 20,
  }) {
    final request = _Request(query, filter);
    requests.add(request);
    return request.result.future;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}
