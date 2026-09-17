import '../services/api_service.dart';
import 'package:flutter/foundation.dart';
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
  // =========================================================
  // API
  // =========================================================

  final ApiService _apiService = ApiService();

  // =========================================================
  // ÉTAT PAR APPAREIL
  // =========================================================

  Future<Map<String, dynamic>> getDeviceStatus(
    String deviceIdentifier,
  ) async {
    try {
      debugPrint(
        '[BIOMETRIC SERVICE] Vérification appareil : $deviceIdentifier',
      );

      final response = await _apiService.get(
        '/api/biometric/device'
        '?deviceIdentifier=${Uri.encodeQueryComponent(deviceIdentifier)}',
      );

      debugPrint(
        '[BIOMETRIC SERVICE] Statut appareil : ${response.statusCode}',
      );

      return _handleResponse(response);
    } catch (e) {
      debugPrint(
        '[BIOMETRIC SERVICE] Erreur getDeviceStatus : $e',
      );

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
      debugPrint(
        '[BIOMETRIC SERVICE] Vérification utilisateur : $userId',
      );

      final response = await _apiService.get(
        '/api/biometric/user/$userId',
      );

      debugPrint(
        '[BIOMETRIC SERVICE] Statut utilisateur : ${response.statusCode}',
      );

      return _handleResponse(response);
    } catch (e) {
      debugPrint(
        '[BIOMETRIC SERVICE] Erreur getUserStatus : $e',
      );

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
      debugPrint(
        '[BIOMETRIC SERVICE] Activation biométrie '
        'userId=$userId',
      );

      final response = await _apiService.post(
        '/api/biometric/enable',
        body: {
          'userId': userId,
          'deviceIdentifier': deviceIdentifier,
        },
      );

      debugPrint(
        '[BIOMETRIC SERVICE] Activation : ${response.statusCode}',
      );

      return _handleResponse(response);
    } catch (e) {
      debugPrint(
        '[BIOMETRIC SERVICE] Erreur enable : $e',
      );

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
      debugPrint(
        '[BIOMETRIC SERVICE] Désactivation biométrie '
        'userId=$userId',
      );

      final response = await _apiService.post(
        '/api/biometric/disable',
        body: {
          'userId': userId,
          'deviceIdentifier': deviceIdentifier,
        },
      );

      debugPrint(
        '[BIOMETRIC SERVICE] Désactivation : ${response.statusCode}',
      );

      return _handleResponse(response);
    } catch (e) {
      debugPrint(
        '[BIOMETRIC SERVICE] Erreur disable : $e',
      );

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
    dynamic response,
  ) {
    Map<String, dynamic> data = {};

    final decoded = _apiService.decodeResponse(
      response,
    );

    if (decoded is Map) {
      data = Map<String, dynamic>.from(
        decoded,
      );
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

  // =========================================================
  // DISPOSE
  // =========================================================

  void dispose() {
    _apiService.dispose();
  }
}