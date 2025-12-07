import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'squat_state.dart';
import '../api_service.dart';

class SquatCubit extends Cubit<SquatState> {
  final ApiService apiService;
  Timer? _statusTimer;

  SquatCubit({required this.apiService}) : super(const SquatState()) {
    // Start polling for status updates
    _startStatusPolling();
  }

  void _startStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      fetchStatus();
    });
  }

  Future<void> startSquat() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final success = await apiService.startSquatDetection();
      if (success) {
        emit(state.copyWith(
          isRunning: true,
          isLoading: false,
          statusMessage: 'Squat detection started',
        ));
        fetchStatus();
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to start squat detection',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error: ${e.toString()}',
      ));
    }
  }

  Future<void> stopSquat() async {
    emit(state.copyWith(isLoading: true));
    try {
      final success = await apiService.stopSquatDetection();
      if (success) {
        emit(state.copyWith(
          isRunning: false,
          isLoading: false,
          statusMessage: 'Squat detection stopped',
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to stop squat detection',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error: ${e.toString()}',
      ));
    }
  }

  Future<void> resetSquat() async {
    emit(state.copyWith(isLoading: true));
    try {
      final success = await apiService.resetSquatDetection();
      if (success) {
        emit(state.copyWith(
          squatCount: 0,
          currentStage: 'up',
          currentAngle: 0.0,
          isLoading: false,
          statusMessage: 'Reset complete',
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to reset squat count',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error: ${e.toString()}',
      ));
    }
  }

  Future<void> fetchStatus() async {
    try {
      final data = await apiService.getSquatStatus();
      emit(state.copyWith(
        squatCount: data.squatCount,
        currentStage: data.currentStage,
        currentAngle: data.currentAngle,
        statusMessage: data.statusMessage,
        isRunning: data.isRunning,
        errorMessage: null,
      ));
    } catch (e) {
      // Don't emit error on status fetch failure to avoid disrupting UI
      // The error will be shown when user tries to start/stop
    }
  }

  @override
  Future<void> close() {
    _statusTimer?.cancel();
    return super.close();
  }
}

