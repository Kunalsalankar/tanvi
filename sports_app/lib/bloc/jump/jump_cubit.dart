import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../api_service.dart';
import 'jump_state.dart';

class JumpCubit extends Cubit<JumpState> {
  final ApiService _apiService;
  Timer? _timer;

  JumpCubit(this._apiService) : super(JumpState());

  void startPolling() {
    _timer?.cancel();
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _fetchData();
    });
  }

  void stopPolling() {
    _timer?.cancel();
  }

  Future<void> _fetchData() async {
    try {
      final data = await _apiService.getStatus();
      emit(state.copyWith(
        jumpCount: data.jumpCount,
        lastJumpHeight: data.lastJumpHeight,
        maxJumpHeight: data.maxJumpHeight,
        statusMessage: data.statusMessage,
        isRunning: data.isRunning,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> startDetection({double height = 170.0, double weight = 70.0}) async {
    final success = await _apiService.startDetection(height: height, weight: weight);
    if (success) {
      _fetchData();
    } else {
      emit(state.copyWith(errorMessage: "Failed to start detection"));
    }
  }

  Future<void> stopDetection() async {
    final success = await _apiService.stopDetection();
    if (success) {
      _fetchData();
    } else {
      emit(state.copyWith(errorMessage: "Failed to stop detection"));
    }
  }

  Future<void> resetData() async {
    final success = await _apiService.resetData();
    if (success) {
      _fetchData();
    } else {
      emit(state.copyWith(errorMessage: "Failed to reset data"));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
