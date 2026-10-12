import 'package:flutter/material.dart';

import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../domain/entities/quran_translation.dart';
import '../../domain/repositories/quran_translation_repository.dart';

class QuranTranslationDownloadSheet extends StatefulWidget {
  const QuranTranslationDownloadSheet({
    super.key,
    required this.repository,
    required this.resource,
    this.activateOnComplete = true,
  });

  final QuranTranslationRepository repository;
  final QuranTranslationResource resource;
  final bool activateOnComplete;

  @override
  State<QuranTranslationDownloadSheet> createState() =>
      _QuranTranslationDownloadSheetState();
}

class _QuranTranslationDownloadSheetState
    extends State<QuranTranslationDownloadSheet> {
  QuranTranslationDownloadProgress? _progress;
  String? _error;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _download();
  }

  Future<void> _download() async {
    setState(() => _error = null);
    try {
      await for (final progress in widget.repository.downloadFullTranslation(
        widget.resource.id,
      )) {
        if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
        setState(() => _progress = progress);
        if (progress.isComplete) {
          if (widget.activateOnComplete) {
            await widget.repository.setSelectedTranslation(widget.resource.id);
          }
          if (mounted && ModalRoute.of(context)?.isCurrent == true) {
            Navigator.of(context).pop(true);
          }
          return;
        }
      }
      if (mounted) {
        setState(() => _error = 'Some chapters failed to download.');
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    return AppSheet(
      title: 'Preparing ${widget.resource.displayLanguage}',
      subtitle: widget.resource.name,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          LinearProgressIndicator(value: progress?.percent),
          const SizedBox(height: 10),
          Text(
            progress == null
                ? 'Starting download...'
                : '${progress.completedChapters}/${progress.totalChapters} chapters \u00b7 ${progress.completedVerses}/${progress.totalVerses} verses',
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _download,
              icon: const AppIcon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
