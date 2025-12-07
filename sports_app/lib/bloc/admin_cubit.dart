import 'package:flutter_bloc/flutter_bloc.dart';
import 'admin_state.dart';
import '../api_service.dart';
import '../services/results_service.dart';

class AdminCubit extends Cubit<AdminState> {
  final ApiService apiService;
  final ResultsService _resultsService = ResultsService();

  AdminCubit({required this.apiService}) : super(const AdminState()) {
    _initializeData();
  }

  Future<void> _initializeData() async {
    emit(state.copyWith(isLoading: true));
    try {
      final results = await _resultsService.getAllTestResults();
      
      // Convert test results to user rankings grouped by sport
      final List<UserRanking> rankings = [];
      final Map<String, List<dynamic>> sportResults = {};
      final Set<String> sportsSet = {};
      final Set<int> agesSet = {};
      
      // Group results by sport and collect available sports and ages
      for (var result in results) {
        final sport = result['sportType'] ?? 'Unknown';
        final age = result['userAge'] as int? ?? 0;
        
        sportsSet.add(sport);
        if (age > 0) agesSet.add(age);
        
        if (!sportResults.containsKey(sport)) {
          sportResults[sport] = [];
        }
        sportResults[sport]!.add(result);
      }
      
      // Create rankings for each sport
      int globalRank = 1;
      for (var sport in sportResults.keys) {
        final topResults = sportResults[sport]!
            .toList()
            ..sort((a, b) => (b['result'] as num).compareTo(a['result'] as num));
        
        for (int i = 0; i < topResults.length; i++) {
          final result = topResults[i];
          rankings.add(UserRanking(
            userId: result['userId'] ?? '',
            name: result['userName'] ?? 'Unknown',
            age: result['userAge'] ?? 0,
            sport: sport,
            score: (result['result'] as num).toDouble(),
            rank: i + 1,
          ));
        }
      }
      
      // Sort available sports and ages
      final sortedSports = sportsSet.toList()..sort();
      final sortedAges = agesSet.toList()..sort();
      
      emit(state.copyWith(
        isLoading: false,
        allUsers: rankings,
        filteredUsers: rankings,
        availableSports: sortedSports,
        availableAges: sortedAges.map((age) => age.toString()).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Exception: Error fetching test results: ${e.toString().replaceAll('Exception: ', '')}',
      ));
    }
  }

  void updateSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
    _applyFilters();
  }

  void filterBySport(String? sport) {
    emit(state.copyWith(selectedSport: sport));
    _applyFilters();
  }

  void filterByAge(String? age) {
    emit(state.copyWith(selectedAge: age));
    _applyFilters();
  }

  void clearFilters() {
    emit(state.copyWith(
      selectedSport: null,
      selectedAge: null,
      searchQuery: '',
    ));
    _applyFilters();
  }

  void _applyFilters() {
    List<UserRanking> filtered = state.allUsers;

    // Filter by sport
    if (state.selectedSport != null && state.selectedSport!.isNotEmpty) {
      filtered = filtered
          .where((user) => user.sport == state.selectedSport)
          .toList();
    }

    // Filter by age
    if (state.selectedAge != null && state.selectedAge!.isNotEmpty) {
      filtered = filtered
          .where((user) => user.age.toString() == state.selectedAge)
          .toList();
    }

    // Filter by search query (name search)
    if (state.searchQuery.isNotEmpty) {
      filtered = filtered
          .where((user) =>
              user.name.toLowerCase().contains(state.searchQuery.toLowerCase()))
          .toList();
    }

    // Re-rank after filtering
    filtered = _rankUsers(filtered);

    emit(state.copyWith(filteredUsers: filtered));
  }

  List<UserRanking> _rankUsers(List<UserRanking> users) {
    // Sort by score descending
    users.sort((a, b) => b.score.compareTo(a.score));

    // Assign new ranks
    return List<UserRanking>.generate(users.length, (index) {
      return UserRanking(
        userId: users[index].userId,
        name: users[index].name,
        age: users[index].age,
        sport: users[index].sport,
        score: users[index].score,
        rank: index + 1,
      );
    });
  }

  Future<void> fetchUsersFromApi() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      // TODO: Replace with actual API call
      // final users = await apiService.getAdminUsers();
      // emit(state.copyWith(
      //   allUsers: users,
      //   filteredUsers: users,
      //   isLoading: false,
      // ));
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error fetching users: ${e.toString()}',
      ));
    }
  }
}
