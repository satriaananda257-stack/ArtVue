import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:frontend/services/storage_service.dart';
import 'package:frontend/services/api_config.dart';

class PostService {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<String?> _getToken() async => StorageService.getToken();

  // CREATE POST (multipart)
  static Future<bool> createPost({
    required String title,
    required String description,
    String? category,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final token = await _getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/posts'),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    request.fields['title'] = title;
    request.fields['description'] = description;
    if (category != null) request.fields['category'] = category;

    if (imageBytes != null && imageName != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: imageName,
      ));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final body = jsonDecode(response.body);
    return body['success'] == true;
  }

  // GET ALL POSTS
  static Future<List<Map<String, dynamic>>> getPosts() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/posts'),
      headers: headers,
    );

    final body = jsonDecode(response.body);
    if (body['success'] == true) {
      return List<Map<String, dynamic>>.from(body['data']['posts']);
    }
    return [];
  }

  // LIKE POST
  static Future<bool> likePost(int postId) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/posts/$postId/like'),
      headers: headers,
    );
    final body = jsonDecode(response.body);
    return body['success'] == true;
  }

  // UNLIKE POST
  static Future<bool> unlikePost(int postId) async {
    final headers = await _authHeaders();
    final response = await http.delete(
      Uri.parse('$_baseUrl/posts/$postId/like'),
      headers: headers,
    );
    final body = jsonDecode(response.body);
    return body['success'] == true;
  }

  // FAVORITE POST
  static Future<bool> favoritePost(int postId) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/posts/$postId/favorite'),
      headers: headers,
    );
    final body = jsonDecode(response.body);
    return body['success'] == true;
  }

  // UNFAVORITE POST
  static Future<bool> unfavoritePost(int postId) async {
    final headers = await _authHeaders();
    final response = await http.delete(
      Uri.parse('$_baseUrl/posts/$postId/favorite'),
      headers: headers,
    );
    final body = jsonDecode(response.body);
    return body['success'] == true;
  }

  // GET POST BY ID
  static Future<Map<String, dynamic>?> getPostById(int postId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/posts/$postId'),
        headers: headers,
      );
      final body = jsonDecode(response.body);
      if (body['success'] == true) {
        return body['data']['post'] as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // GET COMMENTS BY POST ID
  static Future<List<Map<String, dynamic>>> getComments(int postId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/comments/posts/$postId'),
        headers: headers,
      );
      final body = jsonDecode(response.body);
      if (body['success'] == true) {
        return List<Map<String, dynamic>>.from(body['data']['comments']);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ADD COMMENT
  static Future<Map<String, dynamic>?> addComment(int postId, String comment) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/comments/posts/$postId'),
        headers: headers,
        body: jsonEncode({'comment': comment}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        return body['data']['comment'] as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // DELETE COMMENT
  static Future<bool> deleteComment(int commentId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/comments/$commentId'),
        headers: headers,
      );
      final body = jsonDecode(response.body);
      return body['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // UPDATE POST DESCRIPTION
  static Future<bool> updatePostDescription(int postId, String description) async {
    try {
      final headers = await _authHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/posts/$postId'),
        headers: headers,
        body: jsonEncode({'description': description}),
      );
      final body = jsonDecode(response.body);
      return body['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // DELETE POST
  static Future<bool> deletePost(int postId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/posts/$postId'),
        headers: headers,
      );
      final body = jsonDecode(response.body);
      return body['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
