import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiResponse {
  final bool success;
  final String? message;
  final dynamic data;
  final Map<String, dynamic>? errors;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
    required this.statusCode,
  });

  Map<String, dynamic> toMap() => {
        'success': success,
        'message': message,
        'data': data,
        'errors': errors,
        'statusCode': statusCode,
      };
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  static const String _tokenKey = 'auth_bearer_token';
  static const String _userRoleKey = 'auth_user_role';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  VoidCallback? onSessionTerminated;

  Future<String?> getToken() async {
    try {
      final secureToken = await _secureStorage.read(key: _tokenKey);
      if (secureToken != null && secureToken.isNotEmpty) {
        return secureToken;
      }
    } catch (_) {
      // Fallback to SharedPreferences in headless test environments or unsupported platforms
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token, [String? role]) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
      if (role != null) {
        await _secureStorage.write(key: _userRoleKey, value: role);
      }
    } catch (_) {
      // Fallback to SharedPreferences when secure storage channel is unavailable
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (role != null) {
      await prefs.setString(_userRoleKey, role);
    }
  }

  Future<String?> getUserRole() async {
    try {
      final secureRole = await _secureStorage.read(key: _userRoleKey);
      if (secureRole != null && secureRole.isNotEmpty) {
        return secureRole;
      }
    } catch (_) {
      // Fallback to SharedPreferences
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  Future<void> clearToken() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _userRoleKey);
    } catch (_) {
      // Fallback to SharedPreferences
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userRoleKey);
  }

  Future<void> clearSession() async {
    await clearToken();
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  ApiResponse _handleResponse(http.Response response) {
    dynamic jsonBody;
    try {
      jsonBody = json.decode(response.body);
    } catch (_) {
      jsonBody = null;
    }

    if (response.statusCode == 401) {
      clearSession();
      if (onSessionTerminated != null) {
        onSessionTerminated!();
      }
    }

    if (jsonBody is Map<String, dynamic>) {
      return ApiResponse(
        success: jsonBody['success'] == true,
        message: jsonBody['message']?.toString(),
        data: jsonBody['data'],
        errors: jsonBody['errors'] is Map<String, dynamic>
            ? jsonBody['errors'] as Map<String, dynamic>
            : null,
        statusCode: response.statusCode,
      );
    }

    return ApiResponse(
      success: response.statusCode >= 200 && response.statusCode < 300,
      message: response.reasonPhrase,
      statusCode: response.statusCode,
    );
  }

  Future<ApiResponse> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      var uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final headers = await _getHeaders();
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getHeaders();
      final response = await http
          .post(
            uri,
            headers: headers,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getHeaders();
      final response = await http
          .put(
            uri,
            headers: headers,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getHeaders();
      final response = await http
          .patch(
            uri,
            headers: headers,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse> delete(String endpoint) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getHeaders();
      final response = await http
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        statusCode: 0,
      );
    }
  }

  /// Sends a multipart POST request and returns an [ApiResponse].
  Future<ApiResponse> multipartPost(
    String endpoint,
    Map<String, String> fields, {
    File? file,
    String fileField = 'profile_photo',
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final request = http.MultipartRequest('POST', uri);
      final token = await getToken();

      request.headers['Accept'] = 'application/json';
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields.addAll(fields);

      if (file != null && await file.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath(fileField, file.path),
        );
      }

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        statusCode: 0,
      );
    }
  }

  /// Sends a multipart POST request supporting either file path or raw bytes,
  /// returning a normalized JSON response map.
  Future<Map<String, dynamic>> postMultipart(
    String endpoint, {
    required Map<String, String> fields,
    String? fileField,
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final request = http.MultipartRequest('POST', uri);
      final token = await getToken();

      request.headers['Accept'] = 'application/json';
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields.addAll(fields);

      final effectiveField = fileField ?? 'profile_photo';
      if (fileBytes != null && fileBytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            effectiveField,
            fileBytes,
            filename: fileName ?? 'upload.jpg',
          ),
        );
      } else if (filePath != null && filePath.isNotEmpty) {
        final file = File(filePath);
        if (await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              effectiveField,
              filePath,
              filename: fileName,
            ),
          );
        }
      }

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      final apiResponse = _handleResponse(response);
      return apiResponse.toMap();
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
        'errors': null,
        'statusCode': 0,
      };
    }
  }

  /// Downloads raw binary bytes (e.g. PDF, CSV, XLSX report exports).
  Future<({
    List<int> bytes,
    int statusCode,
    String? contentType,
    String? errorMessage,
  })> downloadBytes(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      var uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final token = await getToken();
      final headers = <String, String>{
        'Accept': '*/*',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 401) {
        clearSession();
        onSessionTerminated?.call();
      }

      final contentType = response.headers['content-type'];
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return (
          bytes: response.bodyBytes,
          statusCode: response.statusCode,
          contentType: contentType,
          errorMessage: null,
        );
      }

      String? errorMessage = response.reasonPhrase ?? 'Download failed';
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          errorMessage = decoded['message'].toString();
        }
      } catch (_) {}

      return (
        bytes: <int>[],
        statusCode: response.statusCode,
        contentType: contentType,
        errorMessage: errorMessage,
      );
    } catch (e) {
      return (
        bytes: <int>[],
        statusCode: 0,
        contentType: null,
        errorMessage: 'Network error: $e',
      );
    }
  }
}
