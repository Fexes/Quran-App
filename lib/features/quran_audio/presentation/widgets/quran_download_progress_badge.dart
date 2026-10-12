import 'package:flutter/material.dart';
import '../../../../core/widgets/app_icon.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../domain/entities/quran_audio_download_item.dart';

class QuranDownloadProgressBadge extends StatelessWidget {
  const QuranDownloadProgressBadge({super.key, required this.group});

  final QuranAudioDownloadGroup group;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDownloading = group.downloadingAyahs > 0;
    final progress = group.progress > 0 ? group.progress : null;

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: QuranTheme.softFill(context, primary),
            child: AppIcon(_iconForGroup(group), color: primary),
          ),
          if (isDownloading)
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 3,
                strokeCap: StrokeCap.round,
                backgroundColor: QuranTheme.softFill(context, primary),
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconForGroup(QuranAudioDownloadGroup group) {
    if (group.isDownloaded) {
      return Icons.offline_pin_rounded;
    }
    if (group.isActive) {
      return Icons.downloading_rounded;
    }
    if (group.hasFailures) {
      return Icons.error_outline_rounded;
    }
    return Icons.download_rounded;
  }
}
