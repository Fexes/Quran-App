import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/storage/settings_store.dart';
import 'package:quran/core/theme/quran_theme.dart';
import 'package:quran/core/widgets/app_icon.dart';
import 'package:quran/features/home/domain/entities/home_tile.dart';
import 'package:quran/features/home/presentation/widgets/home_dashboard_tiles.dart';
import 'package:quran/features/prayer_times/domain/entities/daily_prayer_times.dart';
import 'package:quran/features/prayer_times/domain/entities/prayer_calculation_settings.dart';
import 'package:quran/features/prayer_times/domain/entities/prayer_location.dart';
import 'package:quran/features/prayer_times/domain/entities/prayer_time_entry.dart';
import 'package:quran/features/shell/presentation/bloc/shell_cubit.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await (FontLoader(
      'Manrope',
    )..addFont(rootBundle.load('assets/fonts/Manrope-Variable.ttf'))).load();
  });

  test(
    'Home preferences preserve order, allow empty, and ignore unknown IDs',
    () async {
      final store = SettingsStore.memory();
      expect(HomeTile.fromIds(store.homeTileIds), HomeTile.defaults);
      await store.setHomeTileIds(['qibla', 'fasting', 'qibla', 'future-tile']);
      final restored = SettingsStore.memory(store.exportSnapshot());
      expect(HomeTile.fromIds(restored.homeTileIds), [
        HomeTile.qibla,
        HomeTile.fasting,
      ]);
      await restored.setHomeTileIds([]);
      expect(HomeTile.fromIds(restored.homeTileIds), isEmpty);
    },
  );

  for (final small in [false, true]) {
    testWidgets(
      'Home editor saves, reorders and cancels at ${small ? 'large text' : 'normal size'}',
      (tester) async {
        tester.view.physicalSize = Size(small ? 320 : 390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = SettingsStore.memory({
          'home_companion_tile_ids': ['tasbieh', 'qibla'],
        });
        final shell = ShellCubit();
        final now = DateTime.now();
        final entries = [
          PrayerTimeEntry(
            name: PrayerTimeName.fajr,
            time: DateTime(now.year, now.month, now.day, 5, 12),
          ),
          PrayerTimeEntry(
            name: PrayerTimeName.maghrib,
            time: DateTime(now.year, now.month, now.day, 18, 24),
          ),
        ];
        final key = GlobalKey();
        Widget screen(Key widgetKey) => BlocProvider.value(
          value: shell,
          child: MaterialApp(
            theme: QuranTheme.buildTheme(
              preset: small
                  ? QuranTheme.presets.last
                  : QuranTheme.presets.first,
              fontWeightScale: 1,
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(small ? 2 : 1)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: RepaintBoundary(
                    key: key,
                    child: ColoredBox(
                      color: small ? const Color(0xFF141414) : Colors.white,
                      child: HomeDashboardTiles(
                        key: widgetKey,
                        settingsStore: store,
                        prayerTimes: DailyPrayerTimes(
                          date: now,
                          location: const PrayerLocation(
                            name: 'Islamabad',
                            latitude: 33.69,
                            longitude: 73.06,
                          ),
                          settings: const PrayerCalculationSettings.karachi(),
                          entries: entries,
                          nextPrayer: entries.last,
                        ),
                        onRefreshTimes: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpWidget(screen(const ValueKey('initial')));
        await tester.pumpAndSettle();
        expect(find.byType(AppIcon), findsWidgets);
        await tester.tap(find.byTooltip('Customize Home'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byTooltip('Add Fasting times'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Add Fasting times'));
        await tester.pumpAndSettle();
        expect(find.text('Customize Home'), findsOneWidget);
        tester
            .widget<SliverReorderableList>(
              find.byType(SliverReorderableList, skipOffstage: false),
            )
            .onReorderItem!(2, 0);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save Home'));
        await tester.pumpAndSettle();
        expect(store.homeTileIds, ['fasting', 'tasbieh', 'qibla']);
        expect(find.text('Suhoor ends'), findsOneWidget);
        expect(find.textContaining('5:12'), findsOneWidget);
        expect(find.textContaining('6:24'), findsOneWidget);
        expect(tester.takeException(), isNull);

        const output = String.fromEnvironment('HOME_ARTIFACT_DIR');
        if (output.isNotEmpty) {
          await tester.runAsync(() async {
            final image =
                await (key.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory(output).create(recursive: true);
            await File(
              '$output/home-${small ? 'large-text' : 'tiles'}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.ensureVisible(find.byTooltip('Customize Home'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Customize Home'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byTooltip('Remove Qibla Finder'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Remove Qibla Finder'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
        expect(store.homeTileIds, ['fasting', 'tasbieh', 'qibla']);
        await tester.pumpWidget(screen(const ValueKey('reopened')));
        await tester.pumpAndSettle();
        expect(find.text('Fasting times'), findsOneWidget);
        await tester.ensureVisible(find.text('Qibla Finder'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Qibla Finder'));
        expect(shell.state.qiblaOpenRequestId, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await shell.close();
      },
    );
  }
}
