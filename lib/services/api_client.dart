import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Thrown when the API returns a non-2xx response. [message] is user-facing.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  ApiException(this.statusCode, this.message, [this.errors]);

  @override
  String toString() => message;
}

class ApiClient {
  String? _token;

  void setToken(String? token) => _token = token;

  Map<String, String> _headers({bool json = true}) => {
        'Accept': 'application/json',
        if (json) 'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final cleaned = query?.map((k, v) => MapEntry(k, v.toString()))
      ?..removeWhere((_, v) => v.isEmpty);
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: cleaned);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final res = await http.get(_uri(path, query), headers: _headers());
    return _decode(res);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final res = await http.post(_uri(path), headers: _headers(), body: jsonEncode(body ?? {}));
    return _decode(res);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final res = await http.patch(_uri(path), headers: _headers(), body: jsonEncode(body ?? {}));
    return _decode(res);
  }

  /// Multipart POST: [fields] are string form values, [filePath] is attached
  /// under [fileField]. Used for the check-in selfie upload.
  Future<dynamic> postMultipart(
    String path, {
    required Map<String, String> fields,
    required String fileField,
    required String filePath,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path))
      ..headers.addAll(_headers(json: false))
      ..fields.addAll(fields)
      ..files.add(await http.MultipartFile.fromPath(fileField, filePath));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    final dynamic decoded = res.body.isNotEmpty ? jsonDecode(res.body) : null;

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }

    final map = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    final message = map['message']?.toString() ?? 'Terjadi kesalahan (${res.statusCode}).';
    throw ApiException(
      res.statusCode,
      message,
      map['errors'] is Map<String, dynamic> ? map['errors'] as Map<String, dynamic> : null,
    );
  }
}
