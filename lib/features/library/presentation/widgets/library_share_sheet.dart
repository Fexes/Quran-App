import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/theme/quran_theme_cubit.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/content_share_sheet.dart';
import '../../../azkar/domain/entities/dhikr_item.dart';
import '../../../azkar/domain/repositories/azkar_repository.dart';
import '../../../hadith/domain/entities/hadith_item.dart';
import '../../../hadith/domain/repositories/hadith_repository.dart';
import '../../../quran/domain/entities/quran_translation.dart';
import '../../domain/library_translation_language_mapper.dart';

Future<void> showHadithShareSheet(
  BuildContext context,
  HadithItem item, {
  String? languageCode,
  QuranTranslationResource? translationResource,
  bool includeTranslation = true,
  bool translationAvailable = true,
}) {
  final repository = getIt<HadithRepository>();
  return showContentShareSheet(
    context,
    ContentShareSheet(
      title: 'Share hadith',
      heading: 'HADITH',
      arabicText: item.arabic,
      script: context.read<QuranThemeCubit>().state.quranArabicScript,
      translation: translationAvailable ? item.translation : '',
      translationResource: translationResource,
      translationLanguageCode: languageCode,
      initialIncludeTranslation: includeTranslation,
      referenceTitle: item.collectionName.isEmpty
          ? item.reference
          : item.collectionName,
      referenceSubtitle: [
        if (item.collectionName.isNotEmpty) item.reference,
        if (item.grade.isNotEmpty) item.grade,
      ].join('  /  '),
      fileName: 'hadith_${_safeFileName(item.id)}.png',
      translationPickerBuilder:
          (
            resource,
            code,
            enabled,
            onChanged,
            onLoading,
          ) => _LibraryShareTranslationTile(
            languageCode: code,
            enabled: enabled,
            onLoadingChanged: onLoading,
            onChanged: (code, text) => onChanged(null, text, code),
            languages: () =>
                repository.availableTranslationLanguagesForBook(item.bookId),
            loadTranslation: (code, onProgress) async {
              if (!await repository.hasFullTranslation(item.bookId, code)) {
                await for (final progress in repository.downloadBookTranslation(
                  item.bookId,
                  code,
                )) {
                  if (!onProgress(progress.percent)) return '';
                  if (progress.hasFailed) {
                    throw StateError('Hadith translation download failed.');
                  }
                }
              }
              final translated = await repository.getHadithById(
                item.id,
                languageCode: code,
              );
              return translated?.translation ?? '';
            },
          ),
    ),
  );
}

Future<void> showDhikrShareSheet(
  BuildContext context,
  DhikrItem item, {
  String? languageCode,
  QuranTranslationResource? translationResource,
  bool includeTranslation = true,
  bool translationAvailable = true,
  bool includeTransliteration = true,
}) {
  final repository = getIt<AzkarRepository>();
  return showContentShareSheet(
    context,
    ContentShareSheet(
      title: 'Share dhikr',
      heading: 'DAILY REMEMBRANCE',
      arabicText: item.arabic,
      script: context.read<QuranThemeCubit>().state.quranArabicScript,
      translation: translationAvailable ? item.translation : '',
      translationResource: translationResource,
      translationLanguageCode: languageCode,
      transliteration: item.transliteration,
      initialIncludeTransliteration: includeTransliteration,
      initialIncludeTranslation: includeTranslation,
      referenceTitle: item.title.isEmpty ? 'Dhikr' : item.title,
      referenceSubtitle: item.reference,
      fileName: 'azkar_${_safeFileName(item.id)}.png',
      translationPickerBuilder:
          (resource, code, enabled, onChanged, onLoading) =>
              _LibraryShareTranslationTile(
                languageCode: code,
                enabled: enabled,
                onLoadingChanged: onLoading,
                onChanged: (code, text) => onChanged(null, text, code),
                languages: repository.availableTranslationLanguages,
                loadTranslation: (code, onProgress) async {
                  if (!await repository.hasFullTranslation(code)) {
                    await for (final progress in repository.downloadTranslation(
                      code,
                    )) {
                      if (!onProgress(progress.percent)) return '';
                      if (progress.hasFailed) {
                        throw StateError('Azkar translation download failed.');
                      }
                    }
                  }
                  final items = await repository.getDhikr(
                    categoryId: item.categoryId,
                    languageCode: code,
                    limit: 10000,
                  );
                  return items
                          .where((value) => value.id == item.id)
                          .firstOrNull
                          ?.translation ??
                      '';
                },
              ),
    ),
  );
}

String _safeFileName(String id) =>
    id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

class _LibraryShareTranslationTile extends StatefulWidget {
  const _LibraryShareTranslationTile({
    required this.languageCode,
    required this.enabled,
    required this.languages,
    required this.loadTranslation,
    required this.onChanged,
    required this.onLoadingChanged,
  });

  final String? languageCode;
  final bool enabled;
  final Future<List<String>> Function() languages;
  final Future<String> Function(String code, bool Function(double) onProgress)
  loadTranslation;
  final void Function(String code, String text) onChanged;
  final ValueChanged<bool> onLoadingChanged;

  @override
  State<_LibraryShareTranslationTile> createState() =>
      _LibraryShareTranslationTileState();
}

class _LibraryShareTranslationTileState
    extends State<_LibraryShareTranslationTile> {
  bool _loading = false;
  double? _progress;
  String? _loadingLanguage;
  String? _error;

  Future<void> _choose() async {
    if (_loading || !widget.enabled) return;
    setState(() {
      _loading = true;
      _error = null;
      _progress = null;
    });
    widget.onLoadingChanged(true);
    try {
      final codes = (await widget.languages()).toSet().toList()
        ..sort(
          (a, b) => libraryLanguageLabel(a).compareTo(libraryLanguageLabel(b)),
        );
      if (!mounted) return;
      final code = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AppSheet(
          title: 'Translation language',
          scrollableChild: true,
          child: codes.isEmpty
              ? const Text('No translations available for this content.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: codes.length,
                  itemBuilder: (context, index) {
                    final code = codes[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(libraryLanguageLabel(code)),
                      selected: code == widget.languageCode,
                      trailing: AppIcon(
                        code == widget.languageCode
                            ? Icons.check_circle_outline_rounded
                            : Icons.chevron_right_rounded,
                      ),
                      onTap: () => Navigator.of(context).pop(code),
                    );
                  },
                ),
        ),
      );
      if (!mounted || code == null) return;
      setState(() => _loadingLanguage = libraryLanguageLabel(code));
      final text = await widget.loadTranslation(code, (progress) {
        if (!mounted) return false;
        setState(() => _progress = progress.clamp(0.0, 1.0));
        return true;
      });
      if (!mounted) return;
      if (text.trim().isEmpty) {
        throw StateError('No translation for this item.');
      }
      // Sharing never changes the reader's language or translation preference.
      widget.onChanged(code, text);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not load this translation. Your previous choice is unchanged. Tap to retry.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingLanguage = null;
        });
        widget.onLoadingChanged(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: const Text('Translation language'),
    subtitle: Text(
      _loadingLanguage != null
          ? 'Loading $_loadingLanguage...'
          : _error ??
                (widget.languageCode == null
                    ? 'Select language'
                    : libraryLanguageLabel(widget.languageCode!)),
      style: _error == null
          ? null
          : TextStyle(color: Theme.of(context).colorScheme.error),
    ),
    trailing: _loading
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(value: _progress, strokeWidth: 2),
          )
        : const AppIcon(Icons.chevron_right_rounded),
    onTap: widget.enabled && !_loading ? _choose : null,
  );
}
