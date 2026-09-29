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

  /// Adresse publique du backend Railway.
  static const String baseUrl =
      'https://humble-bravery-production-282c.up.railway.app';

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
  // GET ADMINISTRATEUR
  // ===========================================================
  //
  // Utilisé uniquement pour les endpoints protégés
  // par Spring Security avec le rôle BANK_ADMIN.
  //
  // Les appels normaux get() restent inchangés.
  // ===========================================================

  Future<http.Response> adminGet(
    String endpoint, {
    required String username,
    required String password,
  }) async {
    final credentials =
        base64Encode(
          utf8.encode(
            '$username:$password',
          ),
        );

    return _client
        .get(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Basic $credentials',
          },
        )
        .timeout(
          const Duration(seconds: 15),
        );
  }

  // ===========================================================
  // POST ADMINISTRATEUR
  // ===========================================================
  //
  // Utilisé uniquement pour les endpoints protégés
  // par Spring Security avec le rôle BANK_ADMIN.
  // ===========================================================

  Future<http.Response> adminPost(
    String endpoint, {
    Map<String, dynamic>? body,
    required String username,
    required String password,
  }) async {
    final credentials =
        base64Encode(
          utf8.encode(
            '$username:$password',
          ),
        );

    return _client
        .post(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Basic $credentials',
          },
          body: body == null
              ? null
              : jsonEncode(body),
        )
        .timeout(
          const Duration(seconds: 15),
        );
  }

  // ===========================================================
  // PUT ADMINISTRATEUR
  // ===========================================================

  Future<http.Response> adminPut(
    String endpoint, {
    Map<String, dynamic>? body,
    required String username,
    required String password,
  }) async {
    final credentials =
        base64Encode(
          utf8.encode(
            '$username:$password',
          ),
        );

    return _client
        .put(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Basic $credentials',
          },
          body: body == null
              ? null
              : jsonEncode(body),
        )
        .timeout(
          const Duration(seconds: 15),
        );
  }

  // ===========================================================
  // DELETE ADMINISTRATEUR
  // ===========================================================

  Future<http.Response> adminDelete(
    String endpoint, {
    required String username,
    required String password,
  }) async {
    final credentials =
        base64Encode(
          utf8.encode(
            '$username:$password',
          ),
        );

    return _client
        .delete(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Basic $credentials',
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