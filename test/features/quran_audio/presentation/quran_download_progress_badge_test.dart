import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/quran_audio/domain/entities/quran_audio_download_item.dart';
import 'package:quran/features/quran_audio/presentation/widgets/quran_download_progress_badge.dart';

void main() {
  testWidgets('shows circular progress while group is downloading', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuranDownloadProgressBadge(group: _group(downloadingAyahs: 1)),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows static icon when group is not downloading', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuranDownloadProgressBadge(group: _group(downloadedAyahs: 1)),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.offline_pin_rounded), findsOneWidget);
  });
}

QuranAudioDownloadGroup _group({
  int downloadedAyahs = 0,
  int queuedAyahs = 0,
  int downloadingAyahs = 0,
}) {
  return QuranAudioDownloadGroup(
    id: 'surah-1',
    title: 'Al-Fatihah',
    subtitle: 'Reciter',
    reciterId: 'reciter',
    scope: QuranAudioDownloadScope.surah,
    surahNumber: 1,
    totalAyahs: 1,
    downloadedAyahs: downloadedAyahs,
    failedAyahs: 0,
    queuedAyahs: queuedAyahs,
    downloadingAyahs: downloadingAyahs,
    bytesDownloaded: downloadedAyahs > 0 ? 100 : 20,
    bytesTotal: 100,
    items: const [],
  );
}
