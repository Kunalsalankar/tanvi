import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Store current logged-in user ID locally
  String? _currentUserId;
  String? _currentUserName;

  AuthService() {
    // Session will be loaded asynchronously by the caller
  }
  
  // Initialize session on app startup - must be called before using auth
  Future<void> initialize() async {
    await _loadSessionFromPreferences();
  }

  // Load session from SharedPreferences
  Future<void> _loadSessionFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('currentUserId');
      _currentUserName = prefs.getString('currentUserName');
    } catch (e) {
      // Silently fail if preferences not available
    }
  }

  // Save session to SharedPreferences
  Future<void> _saveSessionToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentUserId != null) {
        await prefs.setString('currentUserId', _currentUserId!);
      }
      if (_currentUserName != null) {
        await prefs.setString('currentUserName', _currentUserName!);
      }
    } catch (e) {
      // Silently fail if preferences not available
    }
  }

  // Clear session from SharedPreferences
  Future<void> _clearSessionFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('currentUserId');
      await prefs.remove('currentUserName');
    } catch (e) {
      // Silently fail
    }
  }

  // Sign up with name and password
  Future<Map<String, dynamic>?> signUpWithPassword({
    required String name,
    required String password,
    required int age,
    required double height,
    required double weight,
  }) async {
    try {
      // Check if user already exists
      final existingUser = await _firestore
          .collection('users')
          .where('name', isEqualTo: name)
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw Exception('User with this name already exists');
      }

      // Create a new user document
      final userId = _firestore.collection('users').doc().id;
      
      await _firestore.collection('users').doc(userId).set({
        'userId': userId,
        'name': name,
        'password': password,
        'age': age,
        'height': height,
        'weight': weight,
        'createdAt': FieldValue.serverTimestamp(),
        'isAdmin': false,
      });

      _currentUserId = userId;
      _currentUserName = name;
      
      // Save session
      await _saveSessionToPreferences();
      
      return {
        'userId': userId,
        'name': name,
        'age': age,
        'height': height,
        'weight': weight,
      };
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  // Login with name and password
  Future<Map<String, dynamic>?> loginWithPassword({
    required String name,
    required String password,
  }) async {
    try {
      // Find user by name
      final userQuery = await _firestore
          .collection('users')
          .where('name', isEqualTo: name)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('User not found');
      }

      final userData = userQuery.docs.first.data();

      // Check password
      if (userData['password'] != password) {
        throw Exception('Incorrect password');
      }

      _currentUserId = userData['userId'];
      _currentUserName = name;

      // Save session
      await _saveSessionToPreferences();

      return userData;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  // Get current user data from Firestore
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      if (_currentUserId == null) return null;

      final doc = await _firestore.collection('users').doc(_currentUserId).get();
      return doc.data();
    } catch (e) {
      throw Exception('Error fetching user data: ${e.toString()}');
    }
  }

  // Update user data
  Future<void> updateUserData({
    required String name,
    required int age,
    required double height,
    required double weight,
  }) async {
    try {
      if (_currentUserId == null) throw Exception('User not logged in');

      await _firestore.collection('users').doc(_currentUserId).update({
        'name': name,
        'age': age,
        'height': height,
        'weight': weight,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating user data: ${e.toString()}');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      _currentUserId = null;
      _currentUserName = null;
      
      // Clear session
      await _clearSessionFromPreferences();
    } catch (e) {
      throw Exception('Error logging out: ${e.toString()}');
    }
  }

  // Check if admin
  Future<bool> isAdmin() async {
    try {
      final userData = await getCurrentUserData();
      return userData?['isAdmin'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Get current user ID
  String? get currentUserId => _currentUserId;

  // Get current user name
  String? get currentUserName => _currentUserName;

  // Check if user is logged in
  bool isLoggedIn() => _currentUserId != null;
  
  // Set current user (for maintaining session)
  void setCurrentUser(String userId) {
    _currentUserId = userId;
  }
}
