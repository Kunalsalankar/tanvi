import 'package:equatable/equatable.dart';

class SitupState extends Equatable {
  final int situpCount;
  final double currentAngle;
  final String currentStage;
  final String statusMessage;
  final bool isRunning;
  final bool isLoading;
  final String? errorMessage;

  const SitupState({
    this.situpCount = 0,
    this.currentAngle = 0,
    this.currentStage = 'down',
    this.statusMessage = 'Ready to start',
    this.isRunning = false,
    this.isLoading = false,
    this.errorMessage,
  });

  SitupState copyWith({
    int? situpCount,
    double? currentAngle,
    String? currentStage,
    String? statusMessage,
    bool? isRunning,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SitupState(
      situpCount: situpCount ?? this.situpCount,
      currentAngle: currentAngle ?? this.currentAngle,
      currentStage: currentStage ?? this.currentStage,
      statusMessage: statusMessage ?? this.statusMessage,
      isRunning: isRunning ?? this.isRunning,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    situpCount,
    currentAngle,
    currentStage,
    statusMessage,
    isRunning,
    isLoading,
    errorMessage,
  ];
}
