import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/quran_audio/data/stores/quran_audio_download_store.dart';
import 'package:quran/features/quran_audio/domain/entities/quran_audio_download_item.dart';

void main() {
  group('QuranAudioDownloadStore', () {
    test('saves, updates, and deletes download records', () async {
      final store = QuranAudioDownloadStore.memory();
      final item = QuranAudioDownloadItem(
        id: 'reciter_001_001',
        reciterId: 'reciter',
        reciterName: 'Reciter',
        surahNumber: 1,
        ayahNumber: 1,
        verseKey: '1:1',
        page: 1,
        remoteUrl: 'https://example.com/001001.mp3',
        relativeDirectory: 'quran_audio/reciter/001',
        filename: '001.mp3',
        status: QuranAudioDownloadStatus.queued,
        updatedAt: DateTime.utc(2026, 5, 5),
      );

      await store.saveItem(item);

      expect(store.itemById(item.id), item);

      await store.saveItem(
        item.copyWith(
          status: QuranAudioDownloadStatus.downloaded,
          localUri: 'file:///audio.mp3',
          bytesDownloaded: 1200,
          bytesTotal: 1200,
        ),
      );

      expect(
        store.itemById(item.id)?.status,
        QuranAudioDownloadStatus.downloaded,
      );
      expect(store.itemsForReciter('reciter'), hasLength(1));

      await store.deleteItems([item.id]);

      expect(store.itemById(item.id), isNull);
    });
  });
}
