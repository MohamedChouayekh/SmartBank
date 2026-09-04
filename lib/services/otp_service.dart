
import 'api_service.dart';

class OtpException implements Exception {
  final String message;

  OtpException(this.message);

  @override
  String toString() => message;
}

class OtpService {
  final ApiService _apiService;

  OtpService({
    ApiService? apiService,
  }) : _apiService = apiService ?? ApiService();

  // ===========================================================
  // ENVOYER OTP
  // ===========================================================

  Future<void> sendOtp({
    required String email,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/password/forgot',
        body: {
          'email': email,
        },
      );

      if (response.statusCode == 200) {
        return;
      }

      throw OtpException(
        _apiService.getErrorMessage(response),
      );
    } catch (e) {
      if (e is OtpException) {
        rethrow;
      }

      throw OtpException(
        'Impossible de contacter le serveur Spring Boot.',
      );
    }
  }

  // ===========================================================
  // VERIFIER OTP
  // ===========================================================

  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/password/verify-otp',
        body: {
          'email': email,
          'otp': otp,
        },
      );

      if (response.statusCode == 200) {
        return;
      }

      throw OtpException(
        _apiService.getErrorMessage(response),
      );
    } catch (e) {
      if (e is OtpException) {
        rethrow;
      }

      throw OtpException(
        'Impossible de contacter le serveur Spring Boot.',
      );
    }
  }

  // ===========================================================
  // REINITIALISER MOT DE PASSE
  // ===========================================================

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/password/reset',
        body: {
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode == 200) {
        return;
      }

      throw OtpException(
        _apiService.getErrorMessage(response),
      );
    } catch (e) {
      if (e is OtpException) {
        rethrow;
      }

      throw OtpException(
        'Impossible de contacter le serveur Spring Boot.',
      );
    }
  }
}
