import 'dart:convert';

import 'package:http/http.dart' as http;

class BiometricServiceException implements Exception {
  final String message;
  final int? statusCode;

  BiometricServiceException(
    this.message, {
    this.statusCode,
  });

  @override
  String toString() => message;
}

class BiometricService {
  static const String baseUrl =
      'http://192.168.1.155:8080/api/biometric';

  // =========================================================
  // ÉTAT PAR APPAREIL
  // =========================================================

  Future<Map<String, dynamic>> getDeviceStatus(
    String deviceIdentifier,
  ) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/device',
      ).replace(
        queryParameters: {
          'deviceIdentifier': deviceIdentifier,
        },
      );

      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 10),
          );

      return _handleResponse(response);
    } catch (e) {
      if (e is BiometricServiceException) {
        rethrow;
      }

      throw BiometricServiceException(
        'Impossible de récupérer le statut biométrique.',
      );
    }
  }

  // =========================================================
  // ÉTAT PAR COMPTE
  // =========================================================

  Future<Map<String, dynamic>> getUserStatus(
    int userId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/user/$userId',
            ),
          )
          .timeout(
            const Duration(seconds: 10),
          );

      return _handleResponse(response);
    } catch (e) {
      if (e is BiometricServiceException) {
        rethrow;
      }

      throw BiometricServiceException(
        'Impossible de récupérer le statut biométrique du compte.',
      );
    }
  }

  // =========================================================
  // ACTIVER
  // =========================================================

  Future<Map<String, dynamic>> enable({
    required int userId,
    required String deviceIdentifier,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$baseUrl/enable',
            ),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'userId': userId,
              'deviceIdentifier': deviceIdentifier,
            }),
          )
          .timeout(
            const Duration(seconds: 10),
          );

      return _handleResponse(response);
    } catch (e) {
      if (e is BiometricServiceException) {
        rethrow;
      }

      throw BiometricServiceException(
        'Impossible d\'activer la biométrie.',
      );
    }
  }

  // =========================================================
  // DÉSACTIVER
  // =========================================================

  Future<Map<String, dynamic>> disable({
    required int userId,
    required String deviceIdentifier,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$baseUrl/disable',
            ),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'userId': userId,
              'deviceIdentifier': deviceIdentifier,
            }),
          )
          .timeout(
            const Duration(seconds: 10),
          );

      return _handleResponse(response);
    } catch (e) {
      if (e is BiometricServiceException) {
        rethrow;
      }

      throw BiometricServiceException(
        'Impossible de désactiver la biométrie.',
      );
    }
  }

  // =========================================================
  // RESPONSE
  // =========================================================

  Map<String, dynamic> _handleResponse(
    http.Response response,
  ) {
    Map<String, dynamic> data = {};

    try {
      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      }
    } catch (_) {
      // Réponse non JSON.
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    final message =
        data['message']?.toString() ??
            'Erreur biométrique (${response.statusCode}).';

    throw BiometricServiceException(
      message,
      statusCode: response.statusCode,
    );
  }
}