import 'package:equatable/equatable.dart';

enum QuranWordTimingSource { unavailable, quranFoundation, quranAlign }

class QuranWordTimingSegment extends Equatable {
  const QuranWordTimingSegment({
    required this.verseKey,
    required this.wordIndex,
    required this.startMs,
    required this.endMs,
  });

  factory QuranWordTimingSegment.fromJson(Map<dynamic, dynamic> json) {
    return QuranWordTimingSegment(
      verseKey: json['verseKey'] as String? ?? '',
      wordIndex: _int(json['wordIndex']),
      startMs: _int(json['startMs']),
      endMs: _int(json['endMs']),
    );
  }

  final String verseKey;
  final int wordIndex;
  final int startMs;
  final int endMs;

  bool contains(Duration position) {
    final ms = position.inMilliseconds;
    return ms >= startMs && ms < endMs;
  }

  Map<String, Object> toJson() {
    return {
      'verseKey': verseKey,
      'wordIndex': wordIndex,
      'startMs': startMs,
      'endMs': endMs,
    };
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

  @override
  List<Object?> get props => [verseKey, wordIndex, startMs, endMs];
}

class QuranWordTimingResult extends Equatable {
  const QuranWordTimingResult({
    required this.reciterId,
    required this.verseKey,
    required this.segments,
    required this.source,
    required this.isExact,
  });

  factory QuranWordTimingResult.empty({
    required String reciterId,
    required String verseKey,
  }) {
    return QuranWordTimingResult(
      reciterId: reciterId,
      verseKey: verseKey,
      segments: const [],
      source: QuranWordTimingSource.unavailable,
      isExact: false,
    );
  }

  factory QuranWordTimingResult.fromJson(Map<dynamic, dynamic> json) {
    final rawSegments = json['segments'];
    final sourceName = json['source'] as String?;
    return QuranWordTimingResult(
      reciterId: json['reciterId'] as String? ?? '',
      verseKey: json['verseKey'] as String? ?? '',
      segments: [
        if (rawSegments is List)
          for (final item in rawSegments)
            if (item is Map) QuranWordTimingSegment.fromJson(item),
      ],
      source: QuranWordTimingSource.values.firstWhere(
        (source) => source.name == sourceName,
        orElse: () => QuranWordTimingSource.unavailable,
      ),
      isExact: json['isExact'] as bool? ?? false,
    );
  }

  final String reciterId;
  final String verseKey;
  final List<QuranWordTimingSegment> segments;
  final QuranWordTimingSource source;
  final bool isExact;

  bool get hasSegments => segments.isNotEmpty;

  QuranWordTimingSegment? segmentAt(Duration position) {
    for (final segment in segments) {
      if (segment.contains(position)) {
        return segment;
      }
    }
    return null;
  }

  Map<String, Object> toJson() {
    return {
      'reciterId': reciterId,
      'verseKey': verseKey,
      'segments': [for (final segment in segments) segment.toJson()],
      'source': source.name,
      'isExact': isExact,
    };
  }

  @override
  List<Object?> get props => [reciterId, verseKey, segments, source, isExact];
}
