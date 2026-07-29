import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    debugPrint('[bloc-error] ${bloc.runtimeType}: $error');
    super.onError(bloc, error, stackTrace);
  }
}
