class JumpState {
  final int jumpCount;
  final double lastJumpHeight;
  final double maxJumpHeight;
  final String statusMessage;
  final bool isRunning;
  final String? errorMessage;

  JumpState({
    this.jumpCount = 0,
    this.lastJumpHeight = 0.0,
    this.maxJumpHeight = 0.0,
    this.statusMessage = 'Waiting to start...',
    this.isRunning = false,
    this.errorMessage,
  });

  JumpState copyWith({
    int? jumpCount,
    double? lastJumpHeight,
    double? maxJumpHeight,
    String? statusMessage,
    bool? isRunning,
    String? errorMessage,
  }) {
    return JumpState(
      jumpCount: jumpCount ?? this.jumpCount,
      lastJumpHeight: lastJumpHeight ?? this.lastJumpHeight,
      maxJumpHeight: maxJumpHeight ?? this.maxJumpHeight,
      statusMessage: statusMessage ?? this.statusMessage,
      isRunning: isRunning ?? this.isRunning,
      errorMessage: errorMessage,
    );
  }
}
