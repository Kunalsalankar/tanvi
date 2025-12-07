import 'package:equatable/equatable.dart';

abstract class SquatEvent extends Equatable {
  const SquatEvent();

  @override
  List<Object?> get props => [];
}

class SquatStarted extends SquatEvent {
  const SquatStarted();
}

class SquatStopped extends SquatEvent {
  const SquatStopped();
}

class SquatReset extends SquatEvent {
  const SquatReset();
}

class SquatStatusRequested extends SquatEvent {
  const SquatStatusRequested();
}

