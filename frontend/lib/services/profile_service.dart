import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/services/storage_service.dart';
import 'package:frontend/services/api_config.dart';

class ProfileService {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // GET my profile
  static Future<Map<String, dynamic>?> getMyProfile() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/users/me'),
        headers: headers,
      );
      final body = jsonDecode(response.body);
      if (body['success'] == true) {
        return body['data']['profile'] as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // GET user profile by id
  static Future<Map<String, dynamic>?> getUserProfile(int userId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId/profile'),
        headers: headers,
      );
      final body = jsonDecode(response.body);
      if (body['success'] == true) {
        return body['data']['profile'] as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // FOLLOW user
  static Future<bool> followUser(int userId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/users/$userId/follow'),
        headers: headers,
      );
      final body = jsonDecode(response.body);
      return body['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // UNFOLLOW user
  static Future<bool> unfollowUser(int userId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/users/$userId/follow'),
        headers: headers,
      );
      final body = jsonDecode(response.body);
      return body['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // GET my posts
  static Future<List<Map<String, dynamic>>> getMyPosts() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/users/me/posts'),
        headers: headers,
      );
      final body = jsonDecode(response.body);
      if (body['success'] == true) {
        return List<Map<String, dynamic>>.from(body['data']['posts']);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // GET my saved (favorites)
  static Future<List<Map<String, dynamic>>> getMySaved() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/users/me/favorites'),
        headers: headers,
      );
      final body = jsonDecode(response.body);
      if (body['success'] == true) {
        return List<Map<String, dynamic>>.from(body['data']['posts']);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // GET my liked posts
  static Future<List<Map<String, dynamic>>> getMyLiked() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/users/me/liked'),
        headers: headers,
      );
      final body = jsonDecode(response.body);
      if (body['success'] == true) {
        return List<Map<String, dynamic>>.from(body['data']['posts']);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // UPDATE my profile (username & bio)
  static Future<Map<String, dynamic>?> updateMyProfile({
    String? username,
    String? bio,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/users/me'),
        headers: headers,
        body: jsonEncode({
          if (username != null) 'username': username,
          if (bio != null) 'bio': bio,
        }),
      );
      final body = jsonDecode(response.body);
      if (body['success'] == true) {
        return body['data']['profile'] as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
