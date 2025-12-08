import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  // For web app: use localhost
  // For physical device: use your computer's IP address (e.g., http://10.117.19.2:5001)
  // For Android emulator: use http://10.0.2.2:5001
  // For iOS simulator: use http://localhost:5001
  static const String baseUrl = 'http://localhost:5001';  // Jump detection (app1.py)
  static const String squatBaseUrl = 'http://localhost:5002';  // Squat detection (squat_app.py)
  static const String situpsBaseUrl = 'http://localhost:5003';  // Sit-ups detection (situps_app.py)

  // Check if running on web
  static bool get isWeb => kIsWeb;

  Future<JumpData> getStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/status'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout: Server did not respond in time. Make sure app1.py is running on port 5001');
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return JumpData.fromJson(data);
      } else {
        throw Exception('Failed to load status: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Connection failed: Server at $baseUrl is not reachable. Make sure app1.py is running: $e');
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
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout: Server did not respond in time');
        },
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
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout: Server did not respond in time');
        },
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
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout: Server did not respond in time');
        },
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
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout: Server did not respond in time');
        },
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

  // Squat detection endpoints (using port 5001 for squat_app.py)
  // For Android emulator use: http://10.0.2.2:5001
  // For iOS simulator use: http://localhost:5001
  // For physical device, use your computer's IP: http://10.117.19.2:5001
  // Squat detection endpoints (using port 5001 for squat_app.py)
  
  Future<SquatData> getSquatStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$squatBaseUrl/squat/status'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout: Server did not respond in time');
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SquatData.fromJson(data);
      } else {
        throw Exception('Failed to load squat status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching squat status: $e');
    }
  }

  Future<bool> startSquatDetection() async {
    try {
      final response = await http.post(
        Uri.parse('$squatBaseUrl/squat/start'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout: Server did not respond in time');
        },
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

  Future<bool> stopSquatDetection() async {
    try {
      final response = await http.post(
        Uri.parse('$squatBaseUrl/squat/stop'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout: Server did not respond in time');
        },
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

  Future<bool> resetSquatDetection() async {
    try {
      final response = await http.post(
        Uri.parse('$squatBaseUrl/squat/reset'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout: Server did not respond in time');
        },
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

  // Sit-ups detection endpoints (using port 5003 for situps_app.py)
  Future<Map<String, dynamic>> getSitupStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$situpsBaseUrl/situp/status'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout: Server did not respond in time');
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load situp status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching situp status: $e');
    }
  }

  Future<bool> startSitupDetection({double height = 170.0, double weight = 70.0}) async {
    try {
      final response = await http.post(
        Uri.parse('$situpsBaseUrl/situp/start'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'height': height, 'weight': weight}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout: Server did not respond in time');
        },
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

  Future<bool> stopSitupDetection() async {
    try {
      final response = await http.post(
        Uri.parse('$situpsBaseUrl/situp/stop'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout: Server did not respond in time');
        },
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

  Future<bool> resetSitupCounter() async {
    try {
      final response = await http.post(
        Uri.parse('$situpsBaseUrl/situp/reset'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout: Server did not respond in time');
        },
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

class SquatData {
  final int squatCount;
  final String currentStage;
  final double currentAngle;
  final String statusMessage;
  final bool isRunning;

  SquatData({
    required this.squatCount,
    required this.currentStage,
    required this.currentAngle,
    required this.statusMessage,
    required this.isRunning,
  });

  factory SquatData.fromJson(Map<String, dynamic> json) {
    return SquatData(
      squatCount: json['squat_count'] ?? 0,
      currentStage: json['current_stage'] ?? 'up',
      currentAngle: (json['current_angle'] ?? 0.0).toDouble(),
      statusMessage: json['status_message'] ?? 'Ready to start',
      isRunning: json['is_running'] ?? false,
    );
  }
}