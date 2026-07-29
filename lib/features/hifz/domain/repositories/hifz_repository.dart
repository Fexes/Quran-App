import '../entities/hifz_models.dart';

abstract interface class HifzRepository {
  Future<HifzDashboard> dashboard({DateTime? now});

  Future<HifzCollection> saveCollection({
    String? id,
    required String title,
    required List<String> verseKeys,
    DateTime? now,
  });

  Future<void> deleteCollection(String id);

  Future<List<HifzCard>> dueCardsForCollection(
    String collectionId, {
    DateTime? now,
  });

  Future<HifzCard> reviewCard({
    required String verseKey,
    required HifzReviewRating rating,
    DateTime? now,
  });
}
