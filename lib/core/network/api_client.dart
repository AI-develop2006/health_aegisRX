import 'dart:convert';
import 'package:http/http.dart' as http;
import '../state/app_state.dart';

class ApiClient {
  final String baseUrl;
  final AppState appState;

  ApiClient({required this.baseUrl, required this.appState});

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (appState.token != null) {
      headers['Authorization'] = 'Bearer ${appState.token}';
    }
    return headers;
  }

  Future<http.Response> get(String path) async {
    final url = Uri.parse('$baseUrl$path');
    return await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 5));
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$path');
    return await http.post(
      url,
      headers: _getHeaders(),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 5));
  }
}
