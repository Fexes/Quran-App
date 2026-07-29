import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'shell_state.dart';

class ShellCubit extends Cubit<ShellState> {
  ShellCubit() : super(const ShellState.initial());

  void setDestination(ShellDestination destination) {
    if (state.destination == destination) {
      return;
    }
    HapticFeedback.selectionClick();
    emit(state.copyWith(destination: destination));
  }

  void openQiblaFinder() {
    HapticFeedback.selectionClick();
    emit(
      state.copyWith(
        destination: ShellDestination.prayer,
        qiblaOpenRequestId: state.qiblaOpenRequestId + 1,
      ),
    );
  }
}
