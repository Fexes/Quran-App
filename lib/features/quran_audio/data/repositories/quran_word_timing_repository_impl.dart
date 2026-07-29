import 'dart:convert';
import 'dart:io';

import '../../../../core/content/content_cache_policy.dart';
import '../../../quran/domain/entities/quran_audio_reciter.dart';
import '../../domain/entities/quran_audio_queue_item.dart';
import '../../domain/entities/quran_word_timing.dart';
import '../../domain/repositories/quran_word_timing_repository.dart';
import '../stores/quran_word_timing_store.dart';

typedef QuranFoundationVerseFetcher =
    Future<Map<String, Object?>> Function({
      required int recitationId,
      required String verseKey,
    });

class QuranWordTimingRepositoryImpl implements QuranWordTimingRepository {
  QuranWordTimingRepositoryImpl({
    required QuranWordTimingStore store,
    QuranFoundationVerseFetcher? fetchQuranFoundationVerse,
  }) : _store = store,
       _fetchQuranFoundationVerse =
           fetchQuranFoundationVerse ?? _fetchQuranFoundationVerseJson;

  final QuranWordTimingStore _store;
  final QuranFoundationVerseFetcher _fetchQuranFoundationVerse;

  static const contentCachePolicy = ContentCachePolicy.quranFoundation;

  @override
  Future<QuranWordTimingResult> timingsFor({
    required QuranAudioReciter reciter,
    required QuranAudioQueueItem item,
  }) async {
    await _store.purgeExpired(cachePolicy: contentCachePolicy);
    final cached = _store.resultFor(
      reciterId: reciter.id,
      verseKey: item.verseKey,
      cachePolicy: contentCachePolicy,
    );
    if (cached != null) {
      return cached;
    }

    final recitationId = reciter.timingRecitationId;
    if (reciter.timingProvider != QuranAudioTimingProvider.quranFoundation ||
        recitationId == null) {
      return QuranWordTimingResult.empty(
        reciterId: reciter.id,
        verseKey: item.verseKey,
      );
    }

    try {
      final json = await _fetchQuranFoundationVerse(
        recitationId: recitationId,
        verseKey: item.verseKey,
      );
      final result = parseQuranFoundationVerse(
        reciterId: reciter.id,
        verseKey: item.verseKey,
        json: json,
      );
      if (result.hasSegments) {
        await _store.saveResult(result);
      }
      return result;
    } catch (_) {
      return QuranWordTimingResult.empty(
        reciterId: reciter.id,
        verseKey: item.verseKey,
      );
    }
  }

  static QuranWordTimingResult parseQuranFoundationVerse({
    required String reciterId,
    required String verseKey,
    required Map<dynamic, dynamic> json,
  }) {
    final audioFiles = json['audio_files'];
    final audioFile = audioFiles is List && audioFiles.isNotEmpty
        ? audioFiles.first
        : null;
    final rawSegments = audioFile is Map ? audioFile['segments'] : null;
    final segments = <QuranWordTimingSegment>[];
    if (rawSegments is List) {
      for (final raw in rawSegments) {
        if (raw is! List || raw.length < 4) {
          continue;
        }
        final startWord = _int(raw[0]);
        final endWord = _int(raw[1]);
        final startMs = _int(raw[2]);
        final endMs = _int(raw[3]);
        for (var index = startWord; index < endWord; index++) {
          segments.add(
            QuranWordTimingSegment(
              verseKey: verseKey,
              wordIndex: index + 1,
              startMs: startMs,
              endMs: endMs,
            ),
          );
        }
      }
    }
    return QuranWordTimingResult(
      reciterId: reciterId,
      verseKey: verseKey,
      segments: segments,
      source: segments.isEmpty
          ? QuranWordTimingSource.unavailable
          : QuranWordTimingSource.quranFoundation,
      isExact: segments.isNotEmpty,
    );
  }

  static QuranWordTimingResult parseQuranAlignEntry({
    required String reciterId,
    required Map<dynamic, dynamic> json,
  }) {
    final surah = _int(json['surah']);
    final ayah = _int(json['ayah']);
    final verseKey = '$surah:$ayah';
    final rawSegments = json['segments'];
    final segments = <QuranWordTimingSegment>[];
    if (rawSegments is List) {
      for (final raw in rawSegments) {
        if (raw is! List || raw.length < 4) {
          continue;
        }
        final startWord = _int(raw[0]);
        final endWord = _int(raw[1]);
        final startMs = _int(raw[2]);
        final endMs = _int(raw[3]);
        for (var index = startWord; index < endWord; index++) {
          segments.add(
            QuranWordTimingSegment(
              verseKey: verseKey,
              wordIndex: index + 1,
              startMs: startMs,
              endMs: endMs,
            ),
          );
        }
      }
    }
    return QuranWordTimingResult(
      reciterId: reciterId,
      verseKey: verseKey,
      segments: segments,
      source: segments.isEmpty
          ? QuranWordTimingSource.unavailable
          : QuranWordTimingSource.quranAlign,
      isExact: segments.isNotEmpty,
    );
  }

  static Future<Map<String, Object?>> _fetchQuranFoundationVerseJson({
    required int recitationId,
    required String verseKey,
  }) async {
    final uri = Uri.https(
      'api.quran.com',
      '/api/v4/recitations/$recitationId/by_ayah/$verseKey',
      {'fields': 'segments,url'},
    );
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();
      final body = await utf8.decodeStream(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const HttpException('Failed to fetch Quran word timings');
      }
      final decoded = jsonDecode(body);
      if (decoded is Map<String, Object?>) {
        return decoded;
      }
      return const {};
    } finally {
      client.close(force: true);
    }
  }

  static int _int(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
