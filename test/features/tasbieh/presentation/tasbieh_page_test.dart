import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/storage/settings_store.dart';
import 'package:quran/features/tasbieh/presentation/pages/tasbieh_page.dart';

void main() {
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
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: TasbiehPage(settingsStore: SettingsStore.memory()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byKey(const ValueKey('tasbieh-classic-bead')), findsOneWidget);
    expect(find.byKey(const ValueKey('tasbieh-bead')), findsOneWidget);
  });
}

void _expectVisibleNumber(String value) {
  expect(find.text(value), findsWidgets);
}
