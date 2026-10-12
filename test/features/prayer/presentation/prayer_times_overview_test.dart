import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/theme/quran_theme.dart';
import 'package:quran/core/widgets/architectural_backdrop.dart';
import 'package:quran/features/prayer/domain/entities/prayer_alert_settings.dart';
import 'package:quran/features/prayer/presentation/widgets/prayer_times_overview.dart';
import 'package:quran/features/prayer_times/domain/entities/daily_prayer_times.dart';
import 'package:quran/features/prayer_times/domain/entities/prayer_calculation_settings.dart';
import 'package:quran/features/prayer_times/domain/entities/prayer_location.dart';
import 'package:quran/features/prayer_times/domain/entities/prayer_time_entry.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await (FontLoader(
      'Manrope',
    )..addFont(rootBundle.load('assets/fonts/Manrope-Variable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final compact in [false, true]) {
    testWidgets(
      'prayer overview fits ${compact ? 'large text' : 'mobile'} and keeps actions',
      (tester) async {
        tester.view.physicalSize = Size(compact ? 320 : 390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final now = DateTime.now();
        final entries = [
          for (var index = 0; index < PrayerTimeName.values.length; index++)
            PrayerTimeEntry(
              name: PrayerTimeName.values[index],
              time: DateTime(
                now.year,
                now.month,
                now.day,
                [5, 6, 12, 16, 18, 20][index],
                15,
              ),
            ),
        ];
        var locationTaps = 0;
        var calendarTaps = 0;
        var alertsTaps = 0;
        PrayerTimeName? toggledPrayer;
        bool? toggledEnabled;
        final artworkKey = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: QuranTheme.buildTheme(
              preset: compact
                  ? QuranTheme.presets.last
                  : QuranTheme.presets.first,
              fontWeightScale: 1,
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(compact ? 2 : 1)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: RepaintBoundary(
                  key: artworkKey,
                  child: ColoredBox(
                    color: compact ? const Color(0xFF141414) : Colors.white,
                    child: PrayerTimesOverview(
                      dailyTimes: DailyPrayerTimes(
                        date: now,
                        location: const PrayerLocation(
                          name: 'Islamabad, Pakistan',
                          latitude: 33.69,
                          longitude: 73.06,
                        ),
                        settings: const PrayerCalculationSettings.karachi(),
                        entries: entries,
                        nextPrayer: entries.first,
                      ),
                      alertSettings: PrayerAlertSettings.disabled(),
                      alertsLoading: false,
                      onLocationTap: () => locationTaps++,
                      onCalendarTap: () => calendarTaps++,
                      onAlertsTap: () => alertsTaps++,
                      onTogglePrayerAlert: (name, enabled) async {
                        toggledPrayer = name;
                        toggledEnabled = enabled;
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(
          () => precacheImage(
            const AssetImage(ArchitecturalBackdrop.assetPath),
            tester.element(find.byType(PrayerTimesOverview)),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Prayer times'), findsOneWidget);
        expect(find.byType(IconButton), findsNWidgets(6));
        await tester.tap(find.text('Islamabad, Pakistan'));
        expect(locationTaps, 1);
        await tester.ensureVisible(find.byIcon(Icons.calendar_today_outlined));
        await tester.tap(find.byIcon(Icons.calendar_today_outlined));
        expect(calendarTaps, 1);
        await tester.ensureVisible(find.text('Alerts'));
        await tester.tap(find.text('Alerts'));
        expect(alertsTaps, 1);
        await tester.ensureVisible(find.byTooltip('Enable Isha alert'));
        await tester.tap(find.byTooltip('Enable Isha alert'));
        expect(toggledPrayer, PrayerTimeName.isha);
        expect(toggledEnabled, isTrue);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        const artifactDirectory = String.fromEnvironment('PRAYER_ARTIFACT_DIR');
        if (artifactDirectory.isNotEmpty) {
          await tester.runAsync(() async {
            final boundary =
                artworkKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2);
            try {
              final png = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await Directory(artifactDirectory).create(recursive: true);
              await File(
                '$artifactDirectory/prayer-${compact ? 'large-text' : 'mobile'}.png',
              ).writeAsBytes(png!.buffer.asUint8List());
            } finally {
              image.dispose();
            }
          });
        }
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
