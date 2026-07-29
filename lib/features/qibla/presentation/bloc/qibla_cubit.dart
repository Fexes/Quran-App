import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/qibla_repository.dart';
import 'qibla_state.dart';

class QiblaCubit extends Cubit<QiblaState> {
  QiblaCubit({required QiblaRepository repository})
    : _repository = repository,
      super(const QiblaState.initial());

  final QiblaRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: QiblaStatus.loading));
    try {
      final direction = await _repository.getDirection();
      emit(QiblaState(status: QiblaStatus.success, direction: direction));
    } catch (error) {
      emit(
        state.copyWith(
          status: QiblaStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
