import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/constants/quran_arabic_script.dart';
import '../../../../core/theme/quran_theme_cubit.dart';
import '../../../../core/widgets/content_share_sheet.dart';
import '../../../quran/domain/repositories/quran_translation_repository.dart';
import '../../../quran/presentation/widgets/quran_share_translation_tile.dart';
import '../../domain/entities/daily_ayah.dart';

Future<void> showDailyAyahShareSheet(
  BuildContext context,
  DailyAyah dailyAyah,
) {
  final script = context.read<QuranThemeCubit>().state.quranArabicScript;
  return showContentShareSheet(
    context,
    DailyAyahShareSheet(
      dailyAyah: dailyAyah,
      script: script,
      translationRepository: getIt<QuranTranslationRepository>(),
    ),
  );
}

class DailyAyahShareSheet extends StatelessWidget {
  const DailyAyahShareSheet({
    super.key,
    required this.dailyAyah,
    required this.script,
    required this.translationRepository,
  });

  final DailyAyah dailyAyah;
  final QuranArabicScript script;
  final QuranTranslationRepository translationRepository;

  @override
  Widget build(BuildContext context) {
    final ayah = dailyAyah.ayah;
    return ContentShareSheet(
      title: 'Share verse',
      heading: 'VERSE OF THE DAY',
      arabicText: ayah.textForScript(script),
      script: script,
      translation: dailyAyah.translation,
      translationResource: dailyAyah.translationResource,
      referenceTitle: dailyAyah.surah.englishName,
      referenceSubtitle:
          'Surah ${dailyAyah.surah.number}  /  Ayah ${ayah.number}',
      referenceLabel: 'Surah and ayah reference',
      fileName: 'quran_${ayah.surahNumber}_${ayah.number}.png',
      translationPickerBuilder: (resource, _, enabled, onChanged, onLoading) =>
          QuranShareTranslationTile(
            repository: translationRepository,
            verseKey: ayah.verseKey,
            surahNumber: ayah.surahNumber,
            resource: resource,
            enabled: enabled,
            onLoadingChanged: onLoading,
            onChanged: (resource, text) =>
                onChanged(resource, text, resource.resolvedLanguageCode),
          ),
    );
  }
}
