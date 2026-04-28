import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static const Duration defaultTimeout = Duration(seconds: 20);
  static const int maxAttempts = 2;

  final String baseUrl;
  final String? apiKey;
  final http.Client _client = http.Client();

  ApiClient({
    this.baseUrl = 'https://jules.googleapis.com/v1alpha',
    this.apiKey,
  });

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (apiKey != null) headers['x-goog-api-key'] = apiKey!;
    return headers;
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    final url = '$baseUrl$endpoint';
    _logRequest('GET', url);

    return _sendWithRetry(
      method: 'GET',
      url: url,
      request: () => _client
          .get(Uri.parse(url), headers: _headers)
          .timeout(defaultTimeout),
    );
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = '$baseUrl$endpoint';
    _logRequest('POST', url, body: body);

    return _sendWithRetry(
      method: 'POST',
      url: url,
      request: () => _client
          .post(Uri.parse(url), headers: _headers, body: jsonEncode(body))
          .timeout(defaultTimeout),
    );
  }

  Future<Map<String, dynamic>> _sendWithRetry({
    required String method,
    required String url,
    required Future<http.Response> Function() request,
  }) async {
    Object? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await request();
        _logResponse(method, url, response);

        if (response.statusCode < 500 || attempt == maxAttempts) {
          return _handleResponse(response);
        }

        lastError = Exception(
          'API Error: ${response.statusCode} - ${response.reasonPhrase}',
        );
      } catch (e) {
        lastError = e;
        if (attempt == maxAttempts) rethrow;
      }

      await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
    }

    throw lastError ?? StateError('Request failed without an error');
  }

  void _logRequest(String method, String url, {Map<String, dynamic>? body}) {
    final maskedHeaders = Map.from(_headers);
    if (maskedHeaders.containsKey('x-goog-api-key')) {
      maskedHeaders['x-goog-api-key'] =
          '***${apiKey!.substring(apiKey!.length - 4)}';
    }

    debugPrint('🚀 [API REQ] $method $url');
    debugPrint('   Headers: $maskedHeaders');
    if (body != null) debugPrint('   Body: ${jsonEncode(body)}');
  }

  void _logResponse(String method, String url, http.Response response) {
    debugPrint('✅ [API RES] ${response.statusCode} $method $url');
    final body = response.body.length > 500
        ? '${response.body.substring(0, 500)}... (truncated)'
        : response.body;
    debugPrint('   Body: $body');
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'API Error: ${response.statusCode} - ${response.reasonPhrase}\n${response.body}',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
