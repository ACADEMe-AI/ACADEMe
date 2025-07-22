import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ProgressController {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<List<dynamic>> fetchCourses() async {
    final String backendUrl =
        dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
    final String? token = await _storage.read(key: 'access_token');

    if (token == null) throw Exception("❌ No access token found");

    final response = await http.get(
      Uri.parse("$backendUrl/api/courses/?target_language=en"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("❌ Failed to fetch courses: ${response.statusCode}");
    }
  }

  Future<double> fetchOverallGrade() async {
    final String backendUrl =
        dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
    final String? token =
    await const FlutterSecureStorage().read(key: 'access_token');

    if (token == null) {
      throw Exception("❌ No access token found");
    }

    final response = await http.get(
      Uri.parse("$backendUrl/api/progress-visuals/"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final Map<String, dynamic> visualData = data['visual_data'];

      if (visualData.isNotEmpty) {
        // Calculate the sum of all avg_scores
        double totalAvgScore = 0.0;
        int courseCount = 0;

        for (String courseId in visualData.keys) {
          final double avgScore = (visualData[courseId]['avg_score'] ?? 0).toDouble();
          totalAvgScore += avgScore;
          courseCount++;
        }

        // Return the average of all avg_scores
        return courseCount > 0 ? totalAvgScore / courseCount : 0.0;
      }
      return 0.0;
    } else {
      throw Exception(
          "❌ Failed to fetch overall grade: ${response.statusCode}");
    }
  }

  Future<dynamic> fetchRecommendations({String targetLanguage = 'en'}) async {
    final String backendUrl =
        dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
    final String? token = await _storage.read(key: 'access_token');

    if (token == null) {
      throw Exception("❌ No access token found");
    }

    final response = await http.get(
      Uri.parse(
          "$backendUrl/api/recommendations/?target_language=$targetLanguage"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      // Decode the response body using UTF-8
      final String responseBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(responseBody);
      return data["recommendations"];
    } else {
      throw Exception(
          "❌ Failed to fetch recommendations: ${response.statusCode}");
    }
  }
}