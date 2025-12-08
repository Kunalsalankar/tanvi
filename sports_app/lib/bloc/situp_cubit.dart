import 'package:flutter_bloc/flutter_bloc.dart';
import '../api_service.dart';
import 'situp_state.dart';
import 'dart:async';

class SitupCubit extends Cubit<SitupState> {
  final ApiService apiService;
  Timer? _statusTimer;

  SitupCubit({required this.apiService}) : super(const SitupState());

  Future<void> startDetection({double height = 170.0, double weight = 70.0}) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));
      
      final result = await apiService.startSitupDetection(height: height, weight: weight);
      
      if (result) {
        emit(state.copyWith(
          isLoading: false,
          isRunning: true,
          situpCount: 0,
          statusMessage: 'Detection started',
          errorMessage: null,
        ));
        _startStatusPolling();
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to start detection',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> stopDetection() async {
    try {
      _statusTimer?.cancel();
      final result = await apiService.stopSitupDetection();
      
      if (result) {
        emit(state.copyWith(
          isRunning: false,
          statusMessage: 'Detection stopped',
        ));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> resetCounter() async {
    try {
      final result = await apiService.resetSitupCounter();
      
      if (result) {
        emit(state.copyWith(
          situpCount: 0,
          currentAngle: 0,
          currentStage: 'down',
          statusMessage: 'Counter reset',
          errorMessage: null,
        ));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  void _startStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      fetchStatus();
    });
  }

  Future<void> fetchStatus() async {
    try {
      final statusData = await apiService.getSitupStatus();
      
      emit(state.copyWith(
        situpCount: statusData['count'] ?? 0,
        currentAngle: (statusData['angle'] ?? 0).toDouble(),
        currentStage: statusData['stage'] ?? 'down',
        statusMessage: statusData['message'] ?? 'Monitoring...',
        isRunning: statusData['active'] ?? false,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _statusTimer?.cancel();
    return super.close();
  }
}
