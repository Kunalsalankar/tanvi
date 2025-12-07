import 'package:equatable/equatable.dart';

class AuthState extends Equatable {
  final bool isLoggedIn;
  final bool isAdmin;
  final bool isLoading;
  final String? errorMessage;
  final String? userId;
  final String? name;
  final int? age;
  final double? height;
  final double? weight;

  const AuthState({
    this.isLoggedIn = false,
    this.isAdmin = false,
    this.isLoading = false,
    this.errorMessage,
    this.userId,
    this.name,
    this.age,
    this.height,
    this.weight,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isAdmin,
    bool? isLoading,
    String? errorMessage,
    String? userId,
    String? name,
    int? age,
    double? height,
    double? weight,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isAdmin: isAdmin ?? this.isAdmin,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
    );
  }

  @override
  List<Object?> get props => [
    isLoggedIn,
    isAdmin,
    isLoading,
    errorMessage,
    userId,
    name,
    age,
    height,
    weight,
  ];
}
