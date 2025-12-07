import 'package:equatable/equatable.dart';

class UserRanking extends Equatable {
  final String userId;
  final String name;
  final int age;
  final String sport;
  final double score;
  final int rank;

  const UserRanking({
    required this.userId,
    required this.name,
    required this.age,
    required this.sport,
    required this.score,
    required this.rank,
  });

  @override
  List<Object?> get props => [userId, name, age, sport, score, rank];
}

class AdminState extends Equatable {
  final List<UserRanking> allUsers;
  final List<UserRanking> filteredUsers;
  final String? selectedSport;
  final String? selectedAge;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;
  final List<String> availableSports;
  final List<String> availableAges;

  const AdminState({
    this.allUsers = const [],
    this.filteredUsers = const [],
    this.selectedSport,
    this.selectedAge,
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
    this.availableSports = const [],
    this.availableAges = const [],
  });

  AdminState copyWith({
    List<UserRanking>? allUsers,
    List<UserRanking>? filteredUsers,
    String? selectedSport,
    String? selectedAge,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
    List<String>? availableSports,
    List<String>? availableAges,
  }) {
    return AdminState(
      allUsers: allUsers ?? this.allUsers,
      filteredUsers: filteredUsers ?? this.filteredUsers,
      selectedSport: selectedSport ?? this.selectedSport,
      selectedAge: selectedAge ?? this.selectedAge,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      availableSports: availableSports ?? this.availableSports,
      availableAges: availableAges ?? this.availableAges,
    );
  }

  @override
  List<Object?> get props => [
    allUsers,
    filteredUsers,
    selectedSport,
    selectedAge,
    searchQuery,
    isLoading,
    errorMessage,
    availableSports,
    availableAges,
  ];
}
