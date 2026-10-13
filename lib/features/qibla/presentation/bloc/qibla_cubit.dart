import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/qibla_repository.dart';
import 'qibla_state.dart';

class QiblaCubit extends Cubit<QiblaState> {
  QiblaCubit({required QiblaRepository repository})
    : _repository = repository,
      super(const QiblaState.initial());

  final QiblaRepository _repository;
  int _loadRevision = 0;

  @override
  Future<void> close() {
    _loadRevision++;
    return super.close();
  }

  Future<void> load() async {
    if (isClosed) return;
    final revision = ++_loadRevision;
    emit(state.copyWith(status: QiblaStatus.loading));
    try {
      final direction = await _repository.getDirection();
      if (isClosed || revision != _loadRevision) return;
      emit(QiblaState(status: QiblaStatus.success, direction: direction));
    } catch (error) {
      if (isClosed || revision != _loadRevision) return;
      emit(
        state.copyWith(
          status: QiblaStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
