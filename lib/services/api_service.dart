import 'dart:convert';

import 'package:http/http.dart' as http;

/// Service centralisé pour les appels HTTP vers Spring Boot.
class ApiService {
  /// Pour Flutter Web / Chrome.
  ///
  /// Si tu testes sur Android Emulator :
  /// http://10.0.2.2:8080
  ///
  /// Si tu testes sur téléphone physique :
  /// http://IP_DE_TON_PC:8080
static const String baseUrl = 'http://192.168.1.155:8080';
  final http.Client _client;

  ApiService({http.Client? client})
      : _client = client ?? http.Client();

  // ===========================================================
  // POST JSON
  // ===========================================================

  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: body == null ? null : jsonEncode(body),
    );

    return response;
  }

  // ===========================================================
  // GET
  // ===========================================================

  Future<http.Response> get(
    String endpoint,
  ) async {
    final response = await _client.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Accept': 'application/json',
      },
    );

    return response;
  }

  // ===========================================================
  // DELETE
  // ===========================================================

  Future<http.Response> delete(
    String endpoint,
  ) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Accept': 'application/json',
      },
    );

    return response;
  }

  // ===========================================================
  // JSON RESPONSE
  // ===========================================================

  dynamic decodeResponse(http.Response response) {
    if (response.body.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(response.body);
    } catch (_) {
      return response.body;
    }
  }

  // ===========================================================
  // ERROR MESSAGE
  // ===========================================================

  String getErrorMessage(http.Response response) {
    if (response.body.isEmpty) {
      return 'Erreur du serveur (${response.statusCode}).';
    }

    try {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        if (data['message'] != null) {
          return data['message'].toString();
        }

        if (data['error'] != null) {
          return data['error'].toString();
        }
      }

      return response.body;
    } catch (_) {
      return response.body;
    }
  }

  // ===========================================================
  // DISPOSE
  // ===========================================================

  void dispose() {
    _client.close();
  }
}
