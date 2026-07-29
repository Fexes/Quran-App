import '../../domain/entities/hifz_models.dart';
import '../../domain/repositories/hifz_repository.dart';
import '../stores/hifz_store.dart';

class HifzRepositoryImpl implements HifzRepository {
  const HifzRepositoryImpl({required HifzStore store}) : _store = store;

  final HifzStore _store;

  @override
  Future<HifzDashboard> dashboard({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final cards = _store.cards;
    final due = cards.values.where((card) => card.isDue(current)).toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    final bySurah = <int, List<HifzCard>>{};
    for (final card in cards.values) {
      bySurah.putIfAbsent(card.surahNumber, () => []).add(card);
    }
    final weak =
        <HifzWeakSurah>[
          for (final entry in bySurah.entries)
            if (entry.key > 0 &&
                entry.value.any(
                  (card) => card.lapses > 0 || card.easeFactor < 2.3,
                ))
              HifzWeakSurah(
                surahNumber: entry.key,
                lapses: entry.value.fold(0, (sum, card) => sum + card.lapses),
                averageEase:
                    entry.value.fold(
                      0.0,
                      (sum, card) => sum + card.easeFactor,
                    ) /
                    entry.value.length,
              ),
        ]..sort((a, b) {
          final lapse = b.lapses.compareTo(a.lapses);
          return lapse != 0 ? lapse : a.averageEase.compareTo(b.averageEase);
        });
    return HifzDashboard(
      collections: _store.collections,
      cards: cards,
      dueCards: due,
      weakSurahs: weak.take(5).toList(growable: false),
    );
  }

  @override
  Future<HifzCollection> saveCollection({
    String? id,
    required String title,
    required List<String> verseKeys,
    DateTime? now,
  }) async {
    final current = now ?? DateTime.now();
    final uniqueKeys = verseKeys.toSet().toList(growable: false);
    HifzCollection? existing;
    for (final collection in _store.collections) {
      if (collection.id == id) {
        existing = collection;
        break;
      }
    }
    final collection = HifzCollection(
      id: existing?.id ?? current.microsecondsSinceEpoch.toString(),
      title: title.trim().isEmpty ? 'Hifz collection' : title.trim(),
      verseKeys: uniqueKeys,
      createdAt: existing?.createdAt ?? current,
      updatedAt: current,
    );
    await _store.saveCollections([
      collection,
      for (final item in _store.collections)
        if (item.id != collection.id) item,
    ]);
    final cards = _store.cards;
    for (final key in uniqueKeys) {
      cards.putIfAbsent(key, () => HifzCard.newCard(key, current));
    }
    await _store.saveCards(cards);
    return collection;
  }

  @override
  Future<void> deleteCollection(String id) async {
    final remaining = _store.collections
        .where((item) => item.id != id)
        .toList(growable: false);
    await _store.saveCollections(remaining);
    final usedKeys = remaining.expand((item) => item.verseKeys).toSet();
    await _store.saveCards({
      for (final entry in _store.cards.entries)
        if (usedKeys.contains(entry.key)) entry.key: entry.value,
    });
  }

  @override
  Future<List<HifzCard>> dueCardsForCollection(
    String collectionId, {
    DateTime? now,
  }) async {
    HifzCollection? collection;
    for (final item in _store.collections) {
      if (item.id == collectionId) {
        collection = item;
        break;
      }
    }
    if (collection == null) {
      return const [];
    }
    final current = now ?? DateTime.now();
    final cards = _store.cards;
    return [
      for (final key in collection.verseKeys)
        if (cards[key]?.isDue(current) == true) cards[key]!,
    ]..sort((a, b) => a.dueAt.compareTo(b.dueAt));
  }

  @override
  Future<HifzCard> reviewCard({
    required String verseKey,
    required HifzReviewRating rating,
    DateTime? now,
  }) async {
    final current = now ?? DateTime.now();
    final cards = _store.cards;
    final reviewed = (cards[verseKey] ?? HifzCard.newCard(verseKey, current))
        .review(rating, current);
    cards[verseKey] = reviewed;
    await _store.saveCards(cards);
    return reviewed;
  }
}
