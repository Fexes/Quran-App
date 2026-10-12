import 'package:flutter/material.dart';

import '../../../../core/widgets/app_icon.dart';
import '../../domain/entities/quran_translation.dart';
import '../../domain/repositories/quran_translation_repository.dart';
import 'quran_translation_picker.dart';

/// A share-only choice. Caching text never changes the reader's selection.
class QuranShareTranslationTile extends StatefulWidget {
  const QuranShareTranslationTile({
    super.key,
    required this.repository,
    required this.verseKey,
    required this.surahNumber,
    required this.resource,
    required this.onChanged,
    required this.onLoadingChanged,
    this.enabled = true,
  });

  final QuranTranslationRepository repository;
  final String verseKey;
  final int surahNumber;
  final QuranTranslationResource? resource;
  final void Function(QuranTranslationResource resource, String text) onChanged;
  final ValueChanged<bool> onLoadingChanged;
  final bool enabled;

  @override
  State<QuranShareTranslationTile> createState() =>
      _QuranShareTranslationTileState();
}

class _QuranShareTranslationTileState extends State<QuranShareTranslationTile> {
  String? _loadingLanguage;
  String? _error;

  Future<void> _choose() async {
    final resource = await showModalBottomSheet<QuranTranslationResource>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuranTranslationPicker(
        repository: widget.repository,
        currentResource: widget.resource,
        languagesOnly: true,
      ),
    );
    if (resource == null || !mounted) return;
    setState(() {
      _loadingLanguage = resource.displayLanguage;
      _error = null;
    });
    widget.onLoadingChanged(true);
    try {
      var text = await widget.repository.cachedTranslationForVerse(
        resource.id,
        widget.verseKey,
      );
      if (!mounted) return;
      if (text == null || text.trim().isEmpty) {
        final repository = widget.repository;
        if (repository is! QuranMultiTranslationRepository) {
          throw StateError('Surah translation download is unavailable.');
        }
        await for (final progress
            in (repository as QuranMultiTranslationRepository)
                .downloadSurahTranslation(resource.id, widget.surahNumber)) {
          if (!mounted) return;
          if (progress.failedChapters > 0) {
            throw StateError('Could not download the translation.');
          }
        }
        text = await widget.repository.cachedTranslationForVerse(
          resource.id,
          widget.verseKey,
        );
      }
      if (!mounted) return;
      if (text == null || text.trim().isEmpty) {
        throw StateError('This verse has no translation in this language.');
      }
      widget.onChanged(resource, text);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error =
              'Could not load ${resource.displayLanguage}. '
              'Your previous translation is unchanged. Tap to retry.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loadingLanguage = null);
        widget.onLoadingChanged(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = _loadingLanguage != null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Translation language'),
      subtitle: Text(
        loading
            ? 'Loading $_loadingLanguage...'
            : _error ?? widget.resource?.displayLanguage ?? 'English',
        style: _error == null
            ? null
            : TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      trailing: loading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const AppIcon(Icons.chevron_right_rounded),
      onTap: widget.enabled && !loading ? _choose : null,
    );
  }
}
