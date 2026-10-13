import '../../../azkar/domain/repositories/azkar_repository.dart';
import '../../../hadith/domain/repositories/hadith_repository.dart';
import '../../../quran/domain/entities/quran_translation.dart';
import '../library_translation_language_mapper.dart';

class LibraryLanguageDownloadService {
  const LibraryLanguageDownloadService({
    required this.hadithRepository,
    required this.azkarRepository,
  });

  final HadithRepository hadithRepository;
  final AzkarRepository azkarRepository;

  Future<bool> isReady(QuranTranslationResource resource) async {
    final code = _code(resource);
    if (code.isEmpty) return true;
    final books = (await hadithRepository.bookTranslationCatalog())[code];
    if (books?.isNotEmpty == true) {
      for (final book in books!) {
        if (!await hadithRepository.hasDownloadedTranslation(book.id, code)) {
          return false;
        }
      }
    } else if (!await hadithRepository.hasHadeethEncLanguage(code)) {
      final languages = await hadithRepository.getHadeethEncLanguages();
      if (languages.any((language) => language.code == code)) return false;
    }
    final azkarCode = libraryLanguageFromQuranTranslation(resource).azkarCode;
    return azkarCode == null ||
        !(await azkarRepository.availableTranslationLanguages()).contains(
          azkarCode,
        ) ||
        await azkarRepository.hasInstalledTranslation(azkarCode);
  }

  Stream<LibraryLanguageDownloadProgress> download(
    QuranTranslationResource resource,
  ) async* {
    final code = _code(resource);
    if (code.isEmpty) {
      yield const LibraryLanguageDownloadProgress(isComplete: true);
      return;
    }
    final label = resource.displayLanguage;
    String? notice;
    yield LibraryLanguageDownloadProgress(
      label: 'Checking $label hadith',
      percent: 0,
    );
    final books = (await hadithRepository.bookTranslationCatalog())[code];
    if (books?.isNotEmpty == true) {
      await for (final progress in hadithRepository.downloadTranslationLanguage(
        code,
      )) {
        yield LibraryLanguageDownloadProgress(
          label: '${progress.currentStage ?? 'Preparing'} $label hadith',
          detail:
              '${progress.completedBooks} of ${progress.totalBooks} books saved'
              '${progress.currentBook == null ? '' : ' · ${progress.currentBook}'}'
              '${progress.failureDetails.isEmpty ? '' : '\n${progress.failureDetails.entries.map((entry) => '${entry.key}: ${entry.value}').join('\n')}'}',
          percent: progress.percent * 0.95,
          hasFailed: progress.isFinished && !progress.isComplete,
        );
        if (progress.isFinished && !progress.isComplete) return;
        if (progress.isComplete && progress.unavailableTranslations > 0) {
          notice =
              'All available $label Hadith data is saved. '
              '${progress.unavailableTranslations} translations are not provided by the source.';
        }
      }
    } else if (!await hadithRepository.hasHadeethEncLanguage(code)) {
      final languages = await hadithRepository.getHadeethEncLanguages();
      if (languages.any((language) => language.code == code)) {
        await for (final progress
            in hadithRepository.downloadHadeethEncLanguage(code)) {
          yield LibraryLanguageDownloadProgress(
            label: '${progress.stage ?? 'Downloading'} $label hadith',
            percent: progress.percent * 0.95,
            hasFailed: progress.hasFailed,
          );
          if (progress.hasFailed) return;
        }
        if (!await hadithRepository.hasHadeethEncLanguage(code)) {
          yield LibraryLanguageDownloadProgress(
            label: '$label hadith download failed',
            hasFailed: true,
          );
          return;
        }
      }
    }
    final azkarCode = libraryLanguageFromQuranTranslation(resource).azkarCode;
    if (azkarCode != null &&
        (await azkarRepository.availableTranslationLanguages()).contains(
          azkarCode,
        )) {
      yield LibraryLanguageDownloadProgress(
        label: 'Preparing $label duas',
        percent: 0.95,
      );
      if (!await azkarRepository.hasInstalledTranslation(azkarCode)) {
        await for (final progress in azkarRepository.downloadTranslation(
          azkarCode,
        )) {
          yield LibraryLanguageDownloadProgress(
            label: 'Preparing $label duas',
            percent: 0.95 + progress.percent * 0.05,
            hasFailed: progress.hasFailed,
          );
          if (progress.hasFailed) return;
        }
      }
    }
    yield LibraryLanguageDownloadProgress(
      percent: 1,
      isComplete: true,
      detail: notice,
    );
  }

  static String _code(QuranTranslationResource resource) =>
      resource.resolvedLanguageCode.trim().toLowerCase().replaceAll('_', '-');
}

class LibraryLanguageDownloadProgress {
  const LibraryLanguageDownloadProgress({
    this.label = '',
    this.detail,
    this.percent,
    this.isComplete = false,
    this.hasFailed = false,
  });

  final String label;
  final String? detail;
  final double? percent;
  final bool isComplete;
  final bool hasFailed;
}
