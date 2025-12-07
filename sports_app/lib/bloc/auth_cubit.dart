import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_state.dart';
import '../services/auth_service.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService authService;

  AuthCubit({required this.authService}) : super(const AuthState()) {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    if (authService.isLoggedIn()) {
      final userData = await authService.getCurrentUserData();
      final isAdmin = await authService.isAdmin();
      
      if (userData != null) {
        emit(state.copyWith(
          isLoggedIn: true,
          isAdmin: isAdmin,
          userId: userData['userId'],
          name: userData['name'],
          age: userData['age'],
          height: userData['height'],
          weight: userData['weight'],
        ));
      }
    }
  }

  Future<void> signUpWithPassword({
    required String name,
    required String password,
    required int age,
    required double height,
    required double weight,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final userData = await authService.signUpWithPassword(
        name: name,
        password: password,
        age: age,
        height: height,
        weight: weight,
      );

      if (userData != null) {
        emit(state.copyWith(
          isLoading: false,
          isLoggedIn: true,
          userId: userData['userId'],
          name: name,
          age: age,
          height: height,
          weight: weight,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> loginWithPassword({
    required String name,
    required String password,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final userData = await authService.loginWithPassword(
        name: name,
        password: password,
      );

      if (userData != null) {
        final isAdmin = await authService.isAdmin();

        emit(state.copyWith(
          isLoading: false,
          isLoggedIn: true,
          isAdmin: isAdmin,
          userId: userData['userId'],
          name: userData['name'],
          age: userData['age'],
          height: userData['height'],
          weight: userData['weight'],
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> logout() async {
    emit(state.copyWith(isLoading: true));
    try {
      await authService.logout();
      emit(const AuthState());
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> updateUserData({
    required String name,
    required int age,
    required double height,
    required double weight,
  }) async {
    emit(state.copyWith(isLoading: true));
    try {
      await authService.updateUserData(
        name: name,
        age: age,
        height: height,
        weight: weight,
      );

      emit(state.copyWith(
        isLoading: false,
        name: name,
        age: age,
        height: height,
        weight: weight,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }
}
