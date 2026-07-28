import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_exception.dart';

typedef TokenProvider = Future<String?> Function();

class ApiClient {
  final TokenProvider getToken;
  final http.Client _client = http.Client();

  ApiClient({required this.getToken});

  Future<dynamic> get(String path) => _send('GET', path);

  Future<dynamic> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path, {Object? body}) async {
    final token = await getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (decoded['success'] == true) {
      return decoded['data'];
    }

    final error = decoded['error'] as Map<String, dynamic>? ?? {};
    throw ApiException(
      error['code'] as String? ?? 'UNKNOWN_ERROR',
      error['message'] as String? ?? 'Something went wrong',
    );
  }
}
