import 'package:cloud_firestore/cloud_firestore.dart';

class ResultsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save test result to Firebase
  Future<void> saveTestResult({
    required String userId,
    required String userName,
    required int userAge,
    required double userHeight,
    required double userWeight,
    required String sportType,
    required double result,
    required String resultUnit,
  }) async {
    try {
      await _firestore.collection('test_results').add({
        'userId': userId,
        'userName': userName,
        'userAge': userAge,
        'userHeight': userHeight,
        'userWeight': userWeight,
        'sportType': sportType,
        'result': result,
        'resultUnit': resultUnit,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateTime.now().toString(),
      });
    } catch (e) {
      throw Exception('Error saving test result: ${e.toString()}');
    }
  }

  // Get all test results for admin
  Future<List<Map<String, dynamic>>> getAllTestResults() async {
    try {
      final snapshot = await _firestore
          .collection('test_results')
          .orderBy('timestamp', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Error fetching test results: ${e.toString()}');
    }
  }

  // Get test results by sport type
  Future<List<Map<String, dynamic>>> getResultsBySport(String sportType) async {
    try {
      final snapshot = await _firestore
          .collection('test_results')
          .where('sportType', isEqualTo: sportType)
          .orderBy('result', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Error fetching sport results: ${e.toString()}');
    }
  }

  // Get user's test history
  Future<List<Map<String, dynamic>>> getUserTestHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('test_results')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Error fetching user history: ${e.toString()}');
    }
  }
}
