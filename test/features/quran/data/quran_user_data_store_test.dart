import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/quran/domain/entities/quran_reading_mode.dart';
import 'package:quran/features/quran/data/stores/quran_user_data_store.dart';

void main() {
  group('QuranUserDataStore', () {
    test('saves last read and normalizes bookmarks', () async {
      final store = QuranUserDataStore.memory();
      final updatedAt = DateTime.utc(2026, 4, 25, 12);

      await store.saveLastRead(
        surahNumber: 2,
        ayahNumber: 255,
        updatedAt: updatedAt,
      );
      await store.setBookmarks(['2:255', '2:255', '', '1:1']);
      await store.setAudioReciterId('everyayah:Alafasy_128kbps');

      expect(store.lastReadSurah, 2);
      expect(store.lastReadAyah, 255);
      expect(store.lastReadUpdatedAt, updatedAt);
      expect(store.bookmarks, ['2:255', '1:1']);
      expect(store.audioReciterId, 'everyayah:Alafasy_128kbps');
    });

    test(
      'defaults to separated ayah layout and persists combined layout',
      () async {
        final store = QuranUserDataStore.memory();

        expect(store.ayahTextLayout, QuranAyahTextLayout.separated);

        await store.setAyahTextLayout(QuranAyahTextLayout.combined);

        expect(store.ayahTextLayout, QuranAyahTextLayout.combined);
      },
    );

    test('falls back from invalid stored ayah layout preference', () {
      final store = QuranUserDataStore.memory({'ayah_text_layout': 'broken'});

      expect(store.ayahTextLayout, QuranAyahTextLayout.separated);
    });

    test('migrates old book layout preference to combined', () {
      final store = QuranUserDataStore.memory({'ayah_text_layout': 'book'});

      expect(store.ayahTextLayout, QuranAyahTextLayout.combined);
    });

    test('saves, updates, sorts, and deletes notes', () async {
      final store = QuranUserDataStore.memory();
      final firstTime = DateTime.utc(2026, 5, 7, 9);
      final secondTime = DateTime.utc(2026, 5, 7, 10);
      final updateTime = DateTime.utc(2026, 5, 7, 11);

      final first = await store.saveNote(
        text: ' First reflection ',
        now: firstTime,
      );
      final second = await store.saveNote(
        text: 'Second reflection',
        now: secondTime,
      );

      expect(store.notes.map((note) => note.id), [second.id, first.id]);
      expect(first.text, 'First reflection');

      final updated = await store.saveNote(
        id: first.id,
        text: 'Updated reflection',
        now: updateTime,
      );

      expect(updated.createdAt, firstTime);
      expect(store.notes.map((note) => note.text), [
        'Updated reflection',
        'Second reflection',
      ]);

      await store.deleteNote(second.id);

      expect(store.notes.map((note) => note.id), [first.id]);
    });
  });
}
