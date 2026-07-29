import 'package:equatable/equatable.dart';

sealed class QuranListEvent extends Equatable {
  const QuranListEvent();

  @override
  List<Object> get props => [];
}

class QuranListStarted extends QuranListEvent {
  const QuranListStarted();
}

class QuranListQueryChanged extends QuranListEvent {
  const QuranListQueryChanged(this.query);

  final String query;

  @override
  List<Object> get props => [query];
}
