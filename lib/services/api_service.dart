import 'dart:convert';

import 'package:http/http.dart' as http;

/// Service centralisé pour tous les appels HTTP vers Spring Boot.
///
/// IMPORTANT :
/// Aucun écran ni autre service ne doit contenir directement
/// l'adresse IP ou le port du backend.
class ApiService {
  // ===========================================================
  // CONFIGURATION CENTRALE
  // ===========================================================

  /// Adresse du backend pour Flutter Web / Chrome
  /// lorsque Spring Boot tourne sur le même PC.
  ///
  /// Pour Android avec `adb reverse tcp:8080 tcp:8080`,
  /// cette même configuration peut être utilisée avec
  /// l'adresse locale adaptée.
  static const String baseUrl =
      'http://localhost:8080';

  final http.Client _client;

  ApiService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  // ===========================================================
  // POST JSON
  // ===========================================================

  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _client
        .post(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(
          const Duration(seconds: 15),
        );
  }

  // ===========================================================
  // GET
  // ===========================================================

  Future<http.Response> get(
    String endpoint,
  ) async {
    return _client
        .get(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Accept': 'application/json',
          },
        )
        .timeout(
          const Duration(seconds: 15),
        );
  }

  // ===========================================================
  // PUT JSON
  // ===========================================================

  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _client
        .put(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(
          const Duration(seconds: 15),
        );
  }

  // ===========================================================
  // DELETE
  // ===========================================================

  Future<http.Response> delete(
    String endpoint,
  ) async {
    return _client
        .delete(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Accept': 'application/json',
          },
        )
        .timeout(
          const Duration(seconds: 15),
        );
  }

  // ===========================================================
  // JSON RESPONSE
  // ===========================================================

  dynamic decodeResponse(
    http.Response response,
  ) {
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
  // MESSAGE D'ERREUR
  // ===========================================================

  String getErrorMessage(
    http.Response response,
  ) {
    if (response.body.isEmpty) {
      return 'Erreur du serveur (${response.statusCode}).';
    }

    try {
      final data = jsonDecode(
        response.body,
      );

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