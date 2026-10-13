import 'dart:async';

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
    this.showContinueWhileDownloading = true,
  });

  final QuranTranslationRepository repository;
  final QuranTranslationResource resource;
  final bool activateOnComplete;
  final bool showContinueWhileDownloading;

  @override
  State<QuranTranslationDownloadSheet> createState() =>
      _QuranTranslationDownloadSheetState();
}

class _QuranTranslationDownloadSheetState
    extends State<QuranTranslationDownloadSheet> {
  QuranTranslationDownloadProgress? _progress;
  String? _error;
  bool _started = false;
  bool _downloading = false;
  bool _quranReady = false;
  bool _finishing = false;
  int _downloadRevision = 0;
  StreamSubscription<QuranTranslationDownloadProgress>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _download();
  }

  @override
  void dispose() {
    _downloadRevision++;
    _cancelDownload();
    super.dispose();
  }

  void _cancelDownload() {
    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) unawaited(subscription.cancel());
  }

  void _download() {
    if (_downloading || _finishing) return;
    _cancelDownload();
    final revision = ++_downloadRevision;
    setState(() {
      _downloading = true;
      _error = null;
      _progress = null;
    });
    _subscription = widget.repository
        .downloadFullTranslation(widget.resource.id)
        .listen(
          (progress) {
            if (!mounted || revision != _downloadRevision || _finishing) return;
            setState(() {
              _progress = progress;
              _quranReady =
                  _quranReady || progress.quranTextReady || progress.isComplete;
            });
            if (progress.isComplete) unawaited(_complete());
          },
          onError: (Object error) {
            if (!mounted || revision != _downloadRevision || _finishing) return;
            setState(() {
              _downloading = false;
              _error = _quranReady
                  ? 'Quran text is ready. You can continue without the other downloads or retry.'
                  : 'Download interrupted. Retry to continue.';
            });
          },
          onDone: () {
            if (!mounted || revision != _downloadRevision || _finishing) return;
            setState(() {
              _downloading = false;
              _error ??= _quranReady
                  ? 'Quran text is ready. You can continue without the other downloads or retry.'
                  : 'Some chapters failed to download.';
            });
          },
        );
  }

  Future<void> _complete() async {
    if (_finishing || !_quranReady) return;
    _downloadRevision++;
    _cancelDownload();
    setState(() {
      _finishing = true;
      _downloading = false;
    });
    try {
      if (widget.activateOnComplete) {
        await widget.repository.setSelectedTranslation(widget.resource.id);
      }
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      if (_progress?.isComplete == true) {
        if (_progress?.contentDetail case final notice?) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(notice)));
        }
      }
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _finishing = false;
          _error = 'Could not save this language. Please try again.';
        });
      }
    }
  }

  void _close() {
    if (_finishing) return;
    if (_quranReady) {
      unawaited(_complete());
    } else {
      _downloadRevision++;
      _cancelDownload();
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    return PopScope<bool>(
      canPop: !_quranReady || _finishing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: AppSheet(
        title: 'Preparing ${widget.resource.displayLanguage} text',
        subtitle: widget.resource.name,
        onClose: _close,
        footer:
            _quranReady &&
                (widget.showContinueWhileDownloading || !_downloading)
            ? FilledButton(
                onPressed: _finishing ? null : () => unawaited(_complete()),
                child: const Text('Continue with Quran'),
              )
            : OutlinedButton(onPressed: _close, child: const Text('Cancel')),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value:
                  progress?.contentLabel != null &&
                      progress?.contentProgress == null
                  ? null
                  : progress?.percent,
            ),
            const SizedBox(height: 10),
            Text(
              progress?.contentLabel ??
                  (progress == null
                      ? 'Starting download...'
                      : '${progress.completedChapters} of ${progress.totalChapters} surahs saved'),
            ),
            if (progress?.contentDetail case final detail?) Text(detail),
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
          ],
        ),
      ),
    );
  }
}
