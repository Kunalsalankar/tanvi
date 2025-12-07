import 'package:equatable/equatable.dart';

class SquatState extends Equatable {
  final int squatCount;
  final String currentStage;
  final double currentAngle;
  final String statusMessage;
  final bool isRunning;
  final bool isLoading;
  final String? errorMessage;

  const SquatState({
    this.squatCount = 0,
    this.currentStage = 'up',
    this.currentAngle = 0.0,
    this.statusMessage = 'Ready to start',
    this.isRunning = false,
    this.isLoading = false,
    this.errorMessage,
  });

  SquatState copyWith({
    int? squatCount,
    String? currentStage,
    double? currentAngle,
    String? statusMessage,
    bool? isRunning,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SquatState(
      squatCount: squatCount ?? this.squatCount,
      currentStage: currentStage ?? this.currentStage,
      currentAngle: currentAngle ?? this.currentAngle,
      statusMessage: statusMessage ?? this.statusMessage,
      isRunning: isRunning ?? this.isRunning,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        squatCount,
        currentStage,
        currentAngle,
        statusMessage,
        isRunning,
        isLoading,
        errorMessage,
      ];
}





