import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

import '../models/partner_establishment.dart';
import '../models/partner_promotion.dart';

class ApiServiceException implements Exception {
  final int? statusCode;
  final String message;

  const ApiServiceException({this.statusCode, required this.message});

  @override
  String toString() => message;
}

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

  ApiService({http.Client? client}) : _client = client ?? http.Client();

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
        .timeout(const Duration(seconds: 30));
  }

  // ===========================================================
  // GET
  // ===========================================================

  Future<http.Response> get(String endpoint) async {
    return _client
        .get(
          Uri.parse('$baseUrl$endpoint'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 30));
  }

  // ===========================================================
  // BIAT PRIVILÈGES
  // ===========================================================

  Future<List<PartnerEstablishment>> getPartnerEstablishments() {
    return _getList(
      '/api/privileges/establishments',
      PartnerEstablishment.fromJson,
    );
  }

  Future<List<PartnerPromotion>> getPartnerPromotions() {
    return _getList('/api/privileges/promotions', PartnerPromotion.fromJson);
  }

  Future<List<T>> _getList<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    late final http.Response response;

    try {
      response = await get(endpoint);
    } on TimeoutException {
      throw const ApiServiceException(
        message: 'Le serveur met trop de temps à répondre.',
      );
    } on http.ClientException {
      throw const ApiServiceException(
        message: 'Impossible de contacter le serveur.',
      );
    }

    if (response.statusCode == 204 || response.body.trim().isEmpty) {
      if (response.statusCode == 200 || response.statusCode == 204) {
        return <T>[];
      }
    }

    if (response.statusCode != 200) {
      throw ApiServiceException(
        statusCode: response.statusCode,
        message: getErrorMessage(response),
      );
    }

    final decoded = decodeResponse(response);

    if (decoded is! List) {
      throw const ApiServiceException(
        statusCode: 200,
        message: 'La réponse du serveur ne contient pas une liste valide.',
      );
    }

    return decoded
        .map((item) {
          if (item is! Map) {
            throw const ApiServiceException(
              statusCode: 200,
              message: 'Un élément de la réponse du serveur est invalide.',
            );
          }

          return fromJson(Map<String, dynamic>.from(item));
        })
        .toList(growable: false);
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
        .timeout(const Duration(seconds: 15));
  }

  // ===========================================================
  // DELETE
  // ===========================================================

  Future<http.Response> delete(String endpoint) async {
    return _client
        .delete(
          Uri.parse('$baseUrl$endpoint'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 15));
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
    final credentials = base64Encode(utf8.encode('$username:$password'));

    return _client
        .get(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Basic $credentials',
          },
        )
        .timeout(const Duration(seconds: 15));
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
    final credentials = base64Encode(utf8.encode('$username:$password'));

    return _client
        .post(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Basic $credentials',
          },
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
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
    final credentials = base64Encode(utf8.encode('$username:$password'));

    return _client
        .put(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Basic $credentials',
          },
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
  }

  // ===========================================================
  // DELETE ADMINISTRATEUR
  // ===========================================================

  Future<http.Response> adminDelete(
    String endpoint, {
    required String username,
    required String password,
  }) async {
    final credentials = base64Encode(utf8.encode('$username:$password'));

    return _client
        .delete(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Basic $credentials',
          },
        )
        .timeout(const Duration(seconds: 15));
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
  // MESSAGE D'ERREUR
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
