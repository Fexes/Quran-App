import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/storage/settings_store.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../library/domain/library_translation_language_mapper.dart';
import '../../domain/entities/hadith_book.dart';
import '../../domain/repositories/hadith_repository.dart';

Future<String?> showHadithTranslationSheet(
  BuildContext context, {
  String? initialLanguageCode,
  VoidCallback? onHadeethEncTap,
}) async {
  final settings = getIt<SettingsStore>();
  final code = await showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _HadithTranslationSheet(
      repository: getIt<HadithRepository>(),
      initialLanguageCode: initialLanguageCode ?? settings.hadithLanguageCode,
      onHadeethEncTap: onHadeethEncTap,
    ),
  );
  if (code == null) return null;
  try {
    await settings.setHadithLanguageCode(code);
    await settings.setLibraryTranslationEnabled(true);
    return code;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save the selected language. Please try again.',
          ),
        ),
      );
    }
    return null;
  }
}

class _HadithTranslationSheet extends StatefulWidget {
  const _HadithTranslationSheet({
    required this.repository,
    this.initialLanguageCode,
    this.onHadeethEncTap,
  });

  final HadithRepository repository;
  final String? initialLanguageCode;
  final VoidCallback? onHadeethEncTap;

  @override
  State<_HadithTranslationSheet> createState() =>
      _HadithTranslationSheetState();
}

class _HadithTranslationSheetState extends State<_HadithTranslationSheet> {
  late Future<Map<String, List<HadithBook>>> _catalog;
  StreamSubscription<HadithLanguageDownloadProgress>? _download;
  HadithLanguageDownloadProgress? _progress;
  String? _downloadingCode;
  String? _error;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _catalog = widget.repository.bookTranslationCatalog();
  }

  @override
  void dispose() {
    _download?.cancel();
    super.dispose();
  }

  void _downloadLanguage(String code) {
    if (_downloadingCode != null) return;
    setState(() {
      _downloadingCode = code;
      _progress = null;
      _error = null;
    });
    _download = widget.repository
        .downloadTranslationLanguage(code)
        .listen(
          (progress) {
            if (!mounted || _dismissed) return;
            setState(() => _progress = progress);
            if (progress.isComplete) {
              if (ModalRoute.of(context)?.isCurrent == true) {
                Navigator.of(context).pop(code);
              }
            } else if (progress.isFinished) {
              setState(() {
                _downloadingCode = null;
                _error = progress.totalBooks == 0
                    ? 'No books are available in ${libraryLanguageLabel(code)}.'
                    : 'Could not download: ${progress.failedBooks.join(', ')}. '
                          'Select the language again to retry. Completed books are saved.';
              });
            }
          },
          onError: (Object error) {
            if (!mounted || _dismissed) return;
            setState(() {
              _downloadingCode = null;
              _error = 'Download failed. Select the language again to retry.';
            });
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<String>(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        _dismissed = true;
        _download?.cancel();
      },
      child: AppSheet(
        title: 'Hadith translation',
        subtitle: 'One language for all available books',
        scrollableChild: true,
        child: FutureBuilder<Map<String, List<HadithBook>>>(
          future: _catalog,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return TextButton.icon(
                onPressed: () => setState(() {
                  _catalog = widget.repository.bookTranslationCatalog();
                }),
                icon: const AppIcon(Icons.refresh_rounded),
                label: const Text('Retry loading languages'),
              );
            }
            final catalog = snapshot.data;
            if (catalog == null) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final codes = catalog.keys.toList()
              ..sort(
                (a, b) =>
                    libraryLanguageLabel(a).compareTo(libraryLanguageLabel(b)),
              );
            final selected = widget.initialLanguageCode;
            final downloading = _downloadingCode;
            return ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                if (downloading != null) ...[
                  Text('Preparing ${libraryLanguageLabel(downloading)}'),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: _progress?.percent),
                  const SizedBox(height: 8),
                  Text(
                    '${_progress?.completedBooks ?? 0} of ${catalog[downloading]?.length ?? 0} books ready',
                  ),
                  if (_progress?.currentBook case final book?) Text(book),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ] else ...[
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  for (final code in codes)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(libraryLanguageLabel(code)),
                      subtitle: Text('${catalog[code]!.length} books'),
                      selected: code == selected,
                      trailing: AppIcon(
                        code == selected
                            ? Icons.check_circle_outline_rounded
                            : Icons.download_rounded,
                      ),
                      onTap: () => _downloadLanguage(code),
                    ),
                  if (widget.onHadeethEncTap != null) ...[
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('HadeethEnc downloads'),
                      subtitle: const Text(
                        'Separate collection, with additional languages',
                      ),
                      trailing: const AppIcon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onHadeethEncTap!();
                      },
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
