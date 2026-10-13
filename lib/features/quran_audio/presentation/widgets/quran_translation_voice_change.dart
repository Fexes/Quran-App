import 'package:flutter/material.dart';

import '../../../quran/domain/entities/quran_audio_reciter.dart';
import '../../../quran/domain/entities/quran_translation.dart';
import '../../../quran/domain/repositories/quran_translation_repository.dart';
import '../../../quran/domain/services/quran_translation_audio_pairings.dart';
import '../../../quran/presentation/widgets/quran_translation_download_sheet.dart';

Future<bool> prepareQuranTranslationVoiceChange({
  required BuildContext context,
  required QuranTranslationRepository repository,
  required QuranAudioReciter voice,
}) async {
  final current = await repository.selectedTranslation();
  if (!context.mounted) return false;
  if (!await confirmQuranTranslationVoiceChange(
    context: context,
    voice: voice,
    currentTranslation: current,
  )) {
    return false;
  }
  final pair = quranTranslationPairForVoice(voice.id)!;
  if (await repository.hasReadyReadingLanguage(pair.resource.id)) {
    return context.mounted;
  }
  if (!context.mounted) return false;
  final downloaded = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => QuranTranslationDownloadSheet(
      repository: repository,
      resource: pair.resource,
      activateOnComplete: false,
    ),
  );
  return downloaded == true && context.mounted;
}

Future<bool> confirmQuranTranslationVoiceChange({
  required BuildContext context,
  required QuranAudioReciter voice,
  required QuranTranslationResource? currentTranslation,
  bool draftOnly = false,
}) async {
  final pair = quranTranslationPairForVoice(voice.id);
  if (pair == null) {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Translation edition not verified'),
        content: Text(
          'The exact text edition read by ${voice.name} has not been verified. Choose a verified voice to keep the audio and displayed translation matched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    return false;
  }
  if (currentTranslation?.id != pair.resource.id) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change voice and translation?'),
        content: Text(
          '${voice.name} reads ${pair.resource.name}.\n\nYour displayed ${pair.resource.displayLanguage} translation will also switch to ${pair.resource.name}. ${draftOnly ? 'Changes apply when you save. The matching text will be downloaded if needed.' : 'The matching text will be downloaded first if needed.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Switch both'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return false;
  }
  return context.mounted;
}
