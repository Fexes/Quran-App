import '../entities/quran_audio_reciter.dart';
import '../entities/quran_translation.dart';
import 'quran_translation_audio_pairings.dart';

bool quranTranslationHasMatchingAudio(
  QuranTranslationResource resource,
  List<QuranAudioReciter> reciters,
) {
  final pair = quranTranslationPairForResource(resource.id);
  return pair != null &&
      reciters.any(
        (voice) => voice.isTranslation && pair.voiceIds.contains(voice.id),
      );
}

QuranTranslationResource quranRecommendedTranslationForLanguage(
  QuranTranslationLanguage language,
  List<QuranAudioReciter> reciters, {
  int? preferredResourceId,
}) {
  final editions = language.availableResources;
  // A deliberate edition choice takes precedence over automatic recommendations.
  final preferred = editions
      .where((item) => item.id == preferredResourceId)
      .firstOrNull;
  if (preferred != null) return preferred;
  if (quranTranslationHasMatchingAudio(language.defaultResource, reciters)) {
    return language.defaultResource;
  }
  return editions
          .where((item) => quranTranslationHasMatchingAudio(item, reciters))
          .firstOrNull ??
      language.defaultResource;
}

List<QuranTranslationLanguage> quranLanguagesWithAudioFirst(
  List<QuranTranslationLanguage> languages,
  List<QuranAudioReciter> reciters,
) {
  final sorted = [...languages];
  sorted.sort((a, b) {
    final aHasAudio = a.availableResources.any(
      (item) => quranTranslationHasMatchingAudio(item, reciters),
    );
    final bHasAudio = b.availableResources.any(
      (item) => quranTranslationHasMatchingAudio(item, reciters),
    );
    if (aHasAudio != bHasAudio) return aHasAudio ? -1 : 1;
    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  });
  return sorted;
}
