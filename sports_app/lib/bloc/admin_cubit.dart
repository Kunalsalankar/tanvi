import 'package:flutter_bloc/flutter_bloc.dart';
import 'admin_state.dart';
import '../api_service.dart';

class AdminCubit extends Cubit<AdminState> {
  final ApiService apiService;

  AdminCubit({required this.apiService}) : super(const AdminState()) {
    _initializeData();
  }

  void _initializeData() {
    // Mock data - replace with actual API calls
    final mockUsers = [
      UserRanking(
        userId: '1',
        name: 'Raj Kumar',
        age: 20,
        sport: 'Standing Vertical Jump',
        score: 95.5,
        rank: 1,
      ),
      UserRanking(
        userId: '2',
        name: 'Priya Singh',
        age: 19,
        sport: 'Sit-ups',
        score: 92.3,
        rank: 1,
      ),
      UserRanking(
        userId: '3',
        name: 'Arun Patel',
        age: 21,
        sport: 'Standing Broad Jump',
        score: 88.9,
        rank: 1,
      ),
      UserRanking(
        userId: '4',
        name: 'Neha Sharma',
        age: 20,
        sport: 'Sit-ups',
        score: 88.1,
        rank: 2,
      ),
      UserRanking(
        userId: '5',
        name: 'Vikram Yadav',
        age: 22,
        sport: 'Standing Vertical Jump',
        score: 87.2,
        rank: 2,
      ),
      UserRanking(
        userId: '6',
        name: 'Anjali Gupta',
        age: 21,
        sport: 'Standing Broad Jump',
        score: 86.6,
        rank: 2,
      ),
      UserRanking(
        userId: '7',
        name: 'Ravi Singh',
        age: 19,
        sport: 'Sit-ups',
        score: 85.4,
        rank: 3,
      ),
      UserRanking(
        userId: '8',
        name: 'Divya Nair',
        age: 20,
        sport: 'Standing Vertical Jump',
        score: 84.3,
        rank: 3,
      ),
      UserRanking(
        userId: '9',
        name: 'Sanjay Tiwari',
        age: 22,
        sport: 'Standing Broad Jump',
        score: 82.5,
        rank: 3,
      ),
      UserRanking(
        userId: '10',
        name: 'Meera Das',
        age: 19,
        sport: 'Standing Vertical Jump',
        score: 80.1,
        rank: 4,
      ),
    ];

    final sports = {
      'Standing Vertical Jump',
      'Standing Broad Jump',
      'Sit-ups'
    }.toList();
    final ages = {'19', '20', '21', '22'}.toList();

    emit(state.copyWith(
      allUsers: mockUsers,
      filteredUsers: mockUsers,
      availableSports: sports,
      availableAges: ages,
    ));
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
