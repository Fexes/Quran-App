import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/settings_store.dart';
import 'tasbieh_state.dart';

class TasbiehCubit extends Cubit<TasbiehState> {
  TasbiehCubit({required SettingsStore settingsStore})
    : _settingsStore = settingsStore,
      super(const TasbiehState.initial());

  final SettingsStore _settingsStore;

  void load() {
    emit(
      TasbiehState(
        status: TasbiehStatus.ready,
        count: _settingsStore.tasbiehCount,
        target: _settingsStore.tasbiehTarget,
        updatedAt: _settingsStore.tasbiehUpdatedAt,
      ),
    );
  }

  Future<void> increment() {
    return _save(count: state.count + 1, target: state.target);
  }

  Future<void> undo() {
    return _save(
      count: state.count <= 0 ? 0 : state.count - 1,
      target: state.target,
    );
  }

  Future<void> reset() {
    return _save(count: 0, target: state.target);
  }

  Future<void> setTarget(int target) {
    return _save(count: state.count, target: target.clamp(1, 999999));
  }

  Future<void> _save({required int count, required int target}) async {
    final updatedAt = DateTime.now();
    final next = state.copyWith(
      status: TasbiehStatus.ready,
      count: count.clamp(0, 999999),
      target: target.clamp(1, 999999),
      updatedAt: updatedAt,
    );
    emit(next);
    await _settingsStore.setTasbiehState(
      count: next.count,
      target: next.target,
      updatedAt: updatedAt,
    );
  }
}
