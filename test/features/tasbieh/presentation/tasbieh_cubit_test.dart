import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/storage/settings_store.dart';
import 'package:quran/features/tasbieh/presentation/cubit/tasbieh_cubit.dart';
import 'package:quran/features/tasbieh/presentation/cubit/tasbieh_state.dart';

void main() {
  group('TasbiehCubit', () {
    test('loads default count and target', () {
      final cubit = TasbiehCubit(settingsStore: SettingsStore.memory())..load();

      expect(cubit.state.count, 0);
      expect(cubit.state.target, 33);
      expect(cubit.state.status, TasbiehStatus.ready);

      cubit.close();
    });

    test('increments, undoes, and resets while keeping target', () async {
      final store = SettingsStore.memory();
      final cubit = TasbiehCubit(settingsStore: store)..load();

      await cubit.increment();
      await cubit.increment();
      await cubit.setTarget(99);
      await cubit.undo();
      await cubit.reset();

      expect(cubit.state.count, 0);
      expect(cubit.state.target, 99);
      expect(store.tasbiehCount, 0);
      expect(store.tasbiehTarget, 99);

      await cubit.close();
    });

    test('undo clamps at zero and custom target persists', () async {
      final store = SettingsStore.memory();
      final cubit = TasbiehCubit(settingsStore: store)..load();

      await cubit.undo();
      await cubit.setTarget(123);

      expect(cubit.state.count, 0);
      expect(cubit.state.target, 123);
      expect(store.tasbiehTarget, 123);

      await cubit.close();
    });
  });
}
