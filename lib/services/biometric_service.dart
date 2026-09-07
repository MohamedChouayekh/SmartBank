import '../services/api_service.dart';

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
      final response =
          await _apiService.get(
        '/api/biometric/device'
        '?deviceIdentifier=${Uri.encodeQueryComponent(deviceIdentifier)}',
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
      final response =
          await _apiService.get(
        '/api/biometric/user/$userId',
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
      final response =
          await _apiService.post(
        '/api/biometric/enable',
        body: {
          'userId': userId,
          'deviceIdentifier': deviceIdentifier,
        },
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
      final response =
          await _apiService.post(
        '/api/biometric/disable',
        body: {
          'userId': userId,
          'deviceIdentifier': deviceIdentifier,
        },
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
    dynamic response,
  ) {
    Map<String, dynamic> data = {};

    final decoded =
        _apiService.decodeResponse(
      response,
    );

    if (decoded is Map) {
      data =
          Map<String, dynamic>.from(
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