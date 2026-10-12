import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/constants/quran_arabic_script.dart';
import 'package:quran/core/theme/quran_theme.dart';
import 'package:quran/features/home/domain/entities/daily_ayah.dart';
import 'package:quran/features/home/presentation/widgets/daily_ayah_share_sheet.dart';
import 'package:quran/features/quran/data/repositories/quran_translation_repository_impl.dart';
import 'package:quran/features/quran/data/stores/quran_translation_store.dart';
import 'package:quran/features/quran/domain/entities/quran_ayah.dart';
import 'package:quran/features/quran/domain/entities/quran_surah.dart';
import 'package:quran/features/quran/domain/entities/quran_translation.dart';

void main() {
  final shared = Completer<Map<Object?, Object?>>();
  QuranTranslationRepositoryImpl emptyRepository() =>
      QuranTranslationRepositoryImpl(
        store: QuranTranslationStore.memory(),
        resourcesFetcher: () async => {'translations': <Object>[]},
      );
  late Directory shareDirectory;
  final dailyAyah = DailyAyah(
    date: DateTime(2026, 10, 12),
    ayah: QuranAyah(
      surahNumber: 1,
      number: 1,
      text: QuranArabicScript.uthmani.bismillah,
      indoPakText: QuranArabicScript.indoPak.bismillah,
      translation: '',
      page: 1,
      juz: 1,
      isSajda: false,
    ),
    surah: const QuranSurah(
      number: 1,
      englishName: 'Al-Fatihah',
      arabicName: 'الفاتحة',
      ayahCount: 7,
      revelationType: 'Meccan',
    ),
    translation:
        'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
  );

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    shareDirectory = Directory.systemTemp.createTempSync('quran-share-test-');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => shareDirectory.path,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (call) async {
        shared.complete(Map<Object?, Object?>.from(call.arguments as Map));
        return '';
      },
    );
    for (final font in {
      'Manrope': 'Manrope-Variable.ttf',
      'IndoPakQuran': 'DigitalKhattIndoPak.ttf',
      'NotoSansArabic': 'NotoSansArabic-Variable.ttf',
      'NotoNastaliqUrdu': 'NotoNastaliqUrdu-Variable.ttf',
    }.entries) {
      await (FontLoader(
        font.key,
      )..addFont(rootBundle.load('assets/fonts/${font.value}'))).load();
    }
  });

  tearDownAll(() => shareDirectory.deleteSync(recursive: true));

  testWidgets('verse choices update the preview and share a full PNG', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: QuranTheme.buildTheme(
          preset: QuranTheme.presets.first,
          fontWeightScale: 1,
        ),
        home: Scaffold(
          body: DailyAyahShareSheet(
            dailyAyah: dailyAyah,
            script: QuranArabicScript.indoPak,
            translationRepository: emptyRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(QuranArabicScript.indoPak.bismillah), findsOneWidget);
    expect(find.text(dailyAyah.translation), findsOneWidget);

    Future<void> toggle(String label) async {
      final tile = find.widgetWithText(SwitchListTile, label);
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();
    }

    await toggle('Translation');
    expect(find.text(dailyAyah.translation), findsNothing);
    expect(
      tester
          .widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'Arabic'))
          .onChanged,
      isNull,
    );
    await toggle('Surah and ayah reference');
    expect(find.text('Al-Fatihah'), findsNothing);
    await toggle('Background image');
    expect(find.byType(Image), findsNothing);
    await toggle('Translation');
    await toggle('Arabic');
    expect(find.text(QuranArabicScript.indoPak.bismillah), findsNothing);
    expect(find.text(dailyAyah.translation), findsOneWidget);
    await toggle('Arabic');
    await toggle('Surah and ayah reference');
    await toggle('Background image');

    final share = find.widgetWithText(FilledButton, 'Share image');
    await tester.ensureVisible(share);
    await tester.runAsync(() async {
      await tester.tap(share);
      for (var frame = 0; frame < 100 && !shared.isCompleted; frame++) {
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      final params = await shared.future.timeout(const Duration(seconds: 10));
      expect(params['text'], isNull);
      expect(params['mimeTypes'], ['image/png']);
      final path = (params['paths'] as List).single as String;
      expect(path, endsWith('/quran_1_1.png'));
      expect(params['originWidth'], greaterThan(0));
      expect(params['originHeight'], greaterThan(0));
      final bytes = await File(path).readAsBytes();
      expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      final header = ByteData.sublistView(bytes);
      expect(header.getUint32(16), 1080);
      expect(header.getUint32(20), greaterThan(1080));
      const artifactDirectory = String.fromEnvironment('SHARE_ARTIFACT_DIR');
      if (artifactDirectory.isNotEmpty) {
        await Directory(artifactDirectory).create(recursive: true);
        await File(
          '$artifactDirectory/verse-of-the-day.png',
        ).writeAsBytes(bytes);
      }
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Creating image...'), findsNothing);
  });

  testWidgets('Urdu and large controls fit a small screen without clipping', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const translation = 'شروع اللہ کے نام سے جو بڑا مہربان نہایت رحم والا ہے';
    await tester.pumpWidget(
      MaterialApp(
        theme: QuranTheme.buildTheme(
          preset: QuranTheme.presets.last,
          fontWeightScale: 1,
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: DailyAyahShareSheet(
            script: QuranArabicScript.indoPak,
            translationRepository: emptyRepository(),
            dailyAyah: DailyAyah(
              date: dailyAyah.date,
              ayah: dailyAyah.ayah,
              surah: dailyAyah.surah,
              translation: translation,
              translationResource: const QuranTranslationResource(
                id: 97,
                languageName: 'urdu',
                name: 'Fateh Muhammad Jalandhari',
                authorName: 'Fateh Muhammad Jalandhari',
                slug: 'urdu-jalandhari',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final text = tester.widget<Text>(find.text(translation));
    expect(text.textDirection, TextDirection.rtl);
    expect(text.textAlign, TextAlign.right);
    expect(text.style!.fontFamily, 'NotoNastaliqUrdu');
    expect(text.style!.fontSize, 15);
    expect(find.text('Fateh Muhammad Jalandhari'), findsNothing);
    final share = find.widgetWithText(FilledButton, 'Share image');
    await tester.ensureVisible(share);
    expect(share.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'share language changes only the image and preserves failed choices',
    (tester) async {
      const english = QuranTranslationResource(
        id: 85,
        languageName: 'english',
        name: 'English edition',
        authorName: 'English author',
        slug: 'en',
      );
      const urdu = QuranTranslationResource(
        id: 234,
        languageName: 'urdu',
        name: 'Urdu edition',
        authorName: 'Urdu author',
        slug: 'ur',
      );
      const french = QuranTranslationResource(
        id: 31,
        languageName: 'french',
        name: 'French edition',
        authorName: 'French author',
        slug: 'fr',
      );
      const urduText = 'شروع اللہ کے نام سے جو بڑا مہربان نہایت رحم والا ہے';
      final store = QuranTranslationStore.memory();
      await store.saveCatalog([english, urdu, french]);
      await store.saveSelectedResource(english);
      await store.saveVerseTranslations(
        resourceId: english.id,
        translations: {'1:1': dailyAyah.translation},
      );
      final response = Completer<Map<String, Object?>>();
      final requests = <(int, int)>[];
      final repository = QuranTranslationRepositoryImpl(
        store: store,
        resourcesFetcher: () async => throw StateError('Catalog is cached'),
        chapterTranslationFetcher:
            ({required chapterNumber, required resourceId}) {
              requests.add((resourceId, chapterNumber));
              if (resourceId == french.id) throw StateError('Offline');
              return response.future;
            },
      );
      Widget screen() => MaterialApp(
        home: Scaffold(
          body: DailyAyahShareSheet(
            dailyAyah: dailyAyah,
            script: QuranArabicScript.uthmani,
            translationRepository: repository,
          ),
        ),
      );
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      Future<void> choose(String language, {bool settle = true}) async {
        final tile = find.widgetWithText(ListTile, 'Translation language');
        await tester.ensureVisible(tile);
        await tester.tap(tile);
        await tester.pumpAndSettle();
        expect(find.text('Urdu author'), findsNothing);
        expect(find.text('English edition'), findsNothing);
        expect(find.byTooltip('Choose translator'), findsNothing);
        await tester.tap(find.widgetWithText(ListTile, language).last);
        if (settle) {
          await tester.pumpAndSettle();
        } else {
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
        }
      }

      await choose('Urdu', settle: false);
      expect(find.text('Loading Urdu...'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Share image'),
            )
            .onPressed,
        isNull,
      );
      response.complete({
        'verses': [
          {
            'verse_key': '1:1',
            'translations': [
              {'resource_id': urdu.id, 'text': urduText},
            ],
          },
        ],
      });
      await tester.pumpAndSettle();
      expect(find.text(urduText), findsOneWidget);
      expect(
        tester.widget<Text>(find.text(urduText)).textDirection,
        TextDirection.rtl,
      );
      expect(requests, [(urdu.id, 1)]);
      expect(await repository.selectedTranslation(), english);

      await choose('French');
      expect(find.text(urduText), findsOneWidget);
      expect(find.textContaining('Could not load French'), findsOneWidget);
      expect(await repository.selectedTranslation(), english);

      await choose('English');
      expect(find.text(dailyAyah.translation), findsOneWidget);
      expect(requests, [(urdu.id, 1), (french.id, 1)]);
      await choose('Urdu');
      expect(requests.length, 2);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      expect(find.text(dailyAyah.translation), findsOneWidget);
      expect(find.text(urduText), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
