import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/storage/settings_store.dart';
import 'package:quran/features/tasbieh/presentation/pages/tasbieh_page.dart';

void main() {
  testWidgets(
    'taps count once with the existing haptic, including rapid taps',
    (tester) async {
      final haptics = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final store = SettingsStore.memory();
      await tester.pumpWidget(
        MaterialApp(home: TasbiehPage(settingsStore: store)),
      );
      await tester.pumpAndSettle();
      final bead = find.byKey(const ValueKey('tasbieh-bead'));
      for (var count = 1; count <= 10; count++) {
        await tester.tap(bead);
        await tester.pump(const Duration(milliseconds: 30));
        expect(store.tasbiehCount, count);
      }
      await tester.pumpAndSettle();
      expect(haptics, List.filled(10, 'HapticFeedbackType.mediumImpact'));
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(store.tasbiehCount, 9);
    },
  );

  testWidgets(
    'cancel, secondary fingers, and drag out and back do not double count',
    (tester) async {
      final store = SettingsStore.memory();
      await tester.pumpWidget(
        MaterialApp(home: TasbiehPage(settingsStore: store)),
      );
      await tester.pumpAndSettle();
      final bead = find.byKey(const ValueKey('tasbieh-bead'));
      final center = tester.getCenter(bead);
      final first = await tester.startGesture(center, pointer: 1);
      final second = await tester.startGesture(
        center + const Offset(10, 0),
        pointer: 2,
      );
      await second.up();
      expect(store.tasbiehCount, 0);
      await first.moveBy(const Offset(64, 0));
      await first.up();
      await tester.pumpAndSettle();
      expect(store.tasbiehCount, 1);
      final cancelled = await tester.startGesture(center);
      await cancelled.moveBy(const Offset(0, 64));
      await cancelled.cancel();
      await tester.pumpAndSettle();
      expect(store.tasbiehCount, 1);
      final returned = await tester.startGesture(center);
      await returned.moveBy(const Offset(64, 0));
      await returned.moveTo(center);
      await returned.up();
      await tester.pumpAndSettle();
      expect(store.tasbiehCount, 1);
      await tester.tapAt(tester.getTopLeft(bead) + const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(store.tasbiehCount, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('dragging bead past threshold increments count', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: TasbiehPage(settingsStore: SettingsStore.memory())),
    );
    await tester.pump(const Duration(milliseconds: 80));

    _expectVisibleNumber('0');

    await tester.drag(
      find.byKey(const ValueKey('tasbieh-bead')),
      const Offset(0, 64),
    );
    await tester.pump(const Duration(milliseconds: 500));

    _expectVisibleNumber('1');
  });

  testWidgets('classic bead counts from any drag direction', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: TasbiehPage(settingsStore: SettingsStore.memory())),
    );
    await tester.pump(const Duration(milliseconds: 80));

    await tester.drag(
      find.byKey(const ValueKey('tasbieh-bead')),
      const Offset(64, 0),
    );
    await tester.pump(const Duration(milliseconds: 500));
    _expectVisibleNumber('1');

    await tester.drag(
      find.byKey(const ValueKey('tasbieh-bead')),
      const Offset(-48, -48),
    );
    await tester.pump(const Duration(milliseconds: 500));
    _expectVisibleNumber('2');
  });

  testWidgets('small drag does not increment count', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: TasbiehPage(settingsStore: SettingsStore.memory())),
    );
    await tester.pump(const Duration(milliseconds: 80));

    await tester.drag(
      find.byKey(const ValueKey('tasbieh-bead')),
      const Offset(20, 0),
    );
    await tester.pump(const Duration(milliseconds: 500));

    _expectVisibleNumber('0');
  });

  testWidgets('target sheet shows presets and custom field', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: TasbiehPage(settingsStore: SettingsStore.memory())),
    );
    await tester.pump(const Duration(milliseconds: 80));

    await tester.tap(find.byKey(const ValueKey('tasbieh-target-button')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('33'), findsWidgets);
    expect(find.text('99'), findsWidgets);
    expect(find.text('Common targets'), findsOneWidget);
    expect(find.text('Custom target'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tasbieh-target-sheet-surface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tasbieh-custom-target-field')),
      findsOneWidget,
    );
  });

  testWidgets('style switcher is removed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: TasbiehPage(settingsStore: SettingsStore.memory())),
    );
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.byKey(const ValueKey('tasbieh-concept-button')), findsNothing);
    expect(find.text('Tasbieh Style'), findsNothing);
  });

  testWidgets('classic renders when animations are disabled', (tester) async {
    final store = SettingsStore.memory();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: TasbiehPage(settingsStore: store),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byKey(const ValueKey('tasbieh-classic-bead')), findsOneWidget);
    expect(find.byKey(const ValueKey('tasbieh-bead')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tasbieh-bead')));
    await tester.pumpAndSettle();
    expect(store.tasbiehCount, 1);
    await tester.drag(
      find.byKey(const ValueKey('tasbieh-bead')),
      const Offset(64, 0),
    );
    await tester.pumpAndSettle();
    expect(store.tasbiehCount, 2);
    expect(tester.hasRunningAnimations, isFalse);
  });
}

void _expectVisibleNumber(String value) {
  expect(find.text(value), findsWidgets);
}
