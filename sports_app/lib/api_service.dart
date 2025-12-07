import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this to your Flask server IP address
  // For Android emulator use: http://10.0.2.2:5000
  // For iOS simulator use: http://localhost:5000
  // For physical device, use your computer's IP: http://192.168.x.x:5000
  static const String baseUrl = 'http://10.235.110.146:5000'; // Physical device IP
  
  Future<JumpData> getStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/status'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return JumpData.fromJson(data);
      } else {
        throw Exception('Failed to load status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching status: $e');
    }
  }
  
  Future<bool> incrementJump(double jumpHeight) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/increment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'jump_height': jumpHeight}),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> startDetection({double height = 170.0, double weight = 70.0}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/start'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'height': height, 'weight': weight}),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> stopDetection() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stop'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resetData() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

class JumpData {
  final int jumpCount;
  final double lastJumpHeight;
  final double maxJumpHeight;
  final String statusMessage;
  final bool isRunning;

  JumpData({
    required this.jumpCount,
    required this.lastJumpHeight,
    required this.maxJumpHeight,
    required this.statusMessage,
    required this.isRunning,
  });

  factory JumpData.fromJson(Map<String, dynamic> json) {
    return JumpData(
      jumpCount: json['jump_count'] ?? 0,
      lastJumpHeight: (json['last_jump_height'] ?? 0.0).toDouble(),
      maxJumpHeight: (json['max_jump_height'] ?? 0.0).toDouble(),
      statusMessage: json['status_message'] ?? 'Waiting to start...',
      isRunning: json['is_running'] ?? false,
    );
  }
}


