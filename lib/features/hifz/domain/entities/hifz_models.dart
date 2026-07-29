import 'package:equatable/equatable.dart';

enum HifzCardStatus { newCard, learning, review, mastered }

enum HifzReviewRating { again, hard, good, easy }

class HifzCollection extends Equatable {
  const HifzCollection({
    required this.id,
    required this.title,
    required this.verseKeys,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HifzCollection.fromJson(Map<dynamic, dynamic> json) {
    final created = _date(json['createdAt']) ?? DateTime.now();
    return HifzCollection(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Hifz collection',
      verseKeys: [
        for (final item
            in json['verseKeys'] is List ? json['verseKeys'] as List : const [])
          if (item is String && item.contains(':')) item,
      ],
      createdAt: created,
      updatedAt: _date(json['updatedAt']) ?? created,
    );
  }

  final String id;
  final String title;
  final List<String> verseKeys;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object> toJson() {
    return {
      'id': id,
      'title': title,
      'verseKeys': verseKeys,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object> get props => [id, title, verseKeys, createdAt, updatedAt];
}

class HifzCard extends Equatable {
  const HifzCard({
    required this.verseKey,
    required this.status,
    required this.repetitions,
    required this.lapses,
    required this.intervalDays,
    required this.easeFactor,
    required this.dueAt,
    this.lastReviewedAt,
  });

  factory HifzCard.newCard(String verseKey, DateTime now) {
    return HifzCard(
      verseKey: verseKey,
      status: HifzCardStatus.newCard,
      repetitions: 0,
      lapses: 0,
      intervalDays: 0,
      easeFactor: 2.5,
      dueAt: now,
    );
  }

  factory HifzCard.fromJson(Map<dynamic, dynamic> json) {
    final now = DateTime.now();
    return HifzCard(
      verseKey: json['verseKey'] as String? ?? '',
      status: HifzCardStatus.values.firstWhere(
        (item) => item.name == json['status'],
        orElse: () => HifzCardStatus.newCard,
      ),
      repetitions: _int(json['repetitions']).clamp(0, 100000),
      lapses: _int(json['lapses']).clamp(0, 100000),
      intervalDays: _int(json['intervalDays']).clamp(0, 3650),
      easeFactor: _double(json['easeFactor']).clamp(1.3, 3.0),
      dueAt: _date(json['dueAt']) ?? now,
      lastReviewedAt: _date(json['lastReviewedAt']),
    );
  }

  final String verseKey;
  final HifzCardStatus status;
  final int repetitions;
  final int lapses;
  final int intervalDays;
  final double easeFactor;
  final DateTime dueAt;
  final DateTime? lastReviewedAt;

  int get surahNumber => int.tryParse(verseKey.split(':').first) ?? 0;

  bool isDue(DateTime now) =>
      status == HifzCardStatus.newCard || !dueAt.isAfter(now);

  HifzCard review(HifzReviewRating rating, DateTime now) {
    var nextEase = easeFactor;
    var nextInterval = intervalDays;
    var nextRepetitions = repetitions;
    var nextLapses = lapses;

    switch (rating) {
      case HifzReviewRating.again:
        nextRepetitions = 0;
        nextLapses++;
        nextInterval = 1;
        nextEase = (nextEase - 0.20).clamp(1.3, 3.0);
      case HifzReviewRating.hard:
        nextRepetitions++;
        nextInterval = intervalDays <= 1 ? 1 : (intervalDays * 1.2).round();
        nextEase = (nextEase - 0.15).clamp(1.3, 3.0);
      case HifzReviewRating.good:
        nextInterval = repetitions == 0
            ? 1
            : repetitions == 1
            ? 6
            : (intervalDays * nextEase).round();
        nextRepetitions++;
      case HifzReviewRating.easy:
        nextInterval = repetitions == 0
            ? 4
            : (intervalDays * nextEase * 1.3).round();
        nextRepetitions++;
        nextEase = (nextEase + 0.15).clamp(1.3, 3.0);
    }

    nextInterval = nextInterval.clamp(1, 3650);
    final nextStatus = nextRepetitions >= 5 && nextInterval >= 30
        ? HifzCardStatus.mastered
        : nextRepetitions >= 2
        ? HifzCardStatus.review
        : HifzCardStatus.learning;
    return HifzCard(
      verseKey: verseKey,
      status: nextStatus,
      repetitions: nextRepetitions,
      lapses: nextLapses,
      intervalDays: nextInterval,
      easeFactor: nextEase,
      dueAt: rating == HifzReviewRating.again
          ? now.add(const Duration(minutes: 10))
          : now.add(Duration(days: nextInterval)),
      lastReviewedAt: now,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'verseKey': verseKey,
      'status': status.name,
      'repetitions': repetitions,
      'lapses': lapses,
      'intervalDays': intervalDays,
      'easeFactor': easeFactor,
      'dueAt': dueAt.toIso8601String(),
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    verseKey,
    status,
    repetitions,
    lapses,
    intervalDays,
    easeFactor,
    dueAt,
    lastReviewedAt,
  ];
}

class HifzWeakSurah extends Equatable {
  const HifzWeakSurah({
    required this.surahNumber,
    required this.lapses,
    required this.averageEase,
  });

  final int surahNumber;
  final int lapses;
  final double averageEase;

  @override
  List<Object> get props => [surahNumber, lapses, averageEase];
}

class HifzDashboard extends Equatable {
  const HifzDashboard({
    required this.collections,
    required this.cards,
    required this.dueCards,
    required this.weakSurahs,
  });

  final List<HifzCollection> collections;
  final Map<String, HifzCard> cards;
  final List<HifzCard> dueCards;
  final List<HifzWeakSurah> weakSurahs;

  int get masteredCount => cards.values
      .where((card) => card.status == HifzCardStatus.mastered)
      .length;

  @override
  List<Object> get props => [collections, cards, dueCards, weakSurahs];
}

int _int(Object? value) {
  if (value is num) {
    return value.round();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _double(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 2.5;
}

DateTime? _date(Object? value) {
  return value is String ? DateTime.tryParse(value) : null;
}
