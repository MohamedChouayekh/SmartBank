import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class DeviceSession {
  final int id;
  final String deviceIdentifier;
  final String deviceName;
  final String deviceType;
  final String browser;
  final bool current;
  final bool active;

  DeviceSession({
    required this.id,
    required this.deviceIdentifier,
    required this.deviceName,
    required this.deviceType,
    required this.browser,
    required this.current,
    required this.active,
  });

  factory DeviceSession.fromJson(Map<String, dynamic> json) {
    return DeviceSession(
      id: int.tryParse(
            json['id']?.toString() ?? '',
          ) ??
          0,
      deviceIdentifier:
          json['deviceIdentifier']?.toString() ?? '',
      deviceName:
          json['deviceName']?.toString() ?? '',
      deviceType:
          json['deviceType']?.toString() ?? '',
      browser:
          json['browser']?.toString() ?? '',
      current:
          json['current'] == true,
      active:
          json['active'] == true,
    );
  }
}

class DeviceSessionException implements Exception {
  final String message;

  DeviceSessionException(this.message);

  @override
  String toString() => message;
}

class DeviceSessionService {
  // =========================================================
  // API
  // =========================================================

  final ApiService _apiService = ApiService();

  // =========================================================
  // CONFIGURATION
  // =========================================================

  static const String _deviceIdentifierKey =
      'smartbank_device_identifier';

  // IMPORTANT :
  // On conserve le timeout original de 10 secondes.
  static const Duration _requestTimeout =
      Duration(seconds: 10);

  // =========================================================
  // HEARTBEAT
  // =========================================================

  static const Duration _heartbeatInterval =
      Duration(seconds: 5);

  static Timer? _heartbeatTimer;

  static int? _heartbeatUserId;

  static String? _heartbeatDeviceIdentifier;

  static bool _heartbeatInProgress = false;

  // =========================================================
  // EVENEMENT SESSION INVALIDEE
  // =========================================================

  static final StreamController<void>
      _sessionInvalidatedController =
      StreamController<void>.broadcast();

  static Stream<void>
      get sessionInvalidatedStream =>
          _sessionInvalidatedController.stream;

  // =========================================================
  // DEVICE INFO
  // =========================================================

  final DeviceInfoPlugin _deviceInfo =
      DeviceInfoPlugin();

  // =========================================================
  // IDENTIFIANT UNIQUE ET PERSISTANT
  // =========================================================

  Future<String> _getDeviceIdentifier() async {
    final prefs =
        await SharedPreferences.getInstance();

    final existing =
        prefs.getString(
      _deviceIdentifierKey,
    );

    if (existing != null &&
        existing.trim().isNotEmpty) {
      debugPrint(
        '[DEVICE SESSION] Identifiant existant: '
        '${existing.trim()}',
      );

      return existing.trim();
    }

    // =======================================================
    // ANDROID
    // =======================================================

    if (!kIsWeb) {
      try {
        final androidInfo =
            await _deviceInfo.androidInfo;

        final androidId =
            androidInfo.id.trim();

        if (androidId.isNotEmpty) {
          final identifier =
              'android-$androidId';

          await prefs.setString(
            _deviceIdentifierKey,
            identifier,
          );

          debugPrint(
            '[DEVICE SESSION] Nouvel identifiant Android: '
            '$identifier',
          );

          return identifier;
        }
      } catch (e) {
        debugPrint(
          '[DEVICE SESSION] Erreur Android ID: $e',
        );
      }

      // =====================================================
      // IOS
      // =====================================================

      try {
        final iosInfo =
            await _deviceInfo.iosInfo;

        final iosId =
            iosInfo.identifierForVendor;

        if (iosId != null &&
            iosId.trim().isNotEmpty) {
          final identifier =
              'ios-${iosId.trim()}';

          await prefs.setString(
            _deviceIdentifierKey,
            identifier,
          );

          debugPrint(
            '[DEVICE SESSION] Nouvel identifiant iOS: '
            '$identifier',
          );

          return identifier;
        }
      } catch (e) {
        debugPrint(
          '[DEVICE SESSION] Erreur iOS ID: $e',
        );
      }
    }

    // =======================================================
    // WEB
    // =======================================================

    if (kIsWeb) {
      try {
        final identifier =
            'web-${_randomString(32)}';

        await prefs.setString(
          _deviceIdentifierKey,
          identifier,
        );

        debugPrint(
          '[DEVICE SESSION] Nouvel identifiant Web: '
          '$identifier',
        );

        return identifier;
      } catch (e) {
        debugPrint(
          '[DEVICE SESSION] Erreur identifiant Web: $e',
        );
      }
    }

    // =======================================================
    // FALLBACK
    // =======================================================

    final fallback =
        'device-${_randomString(32)}';

    await prefs.setString(
      _deviceIdentifierKey,
      fallback,
    );

    debugPrint(
      '[DEVICE SESSION] Identifiant fallback: '
      '$fallback',
    );

    return fallback;
  }

  // =========================================================
  // RANDOM STRING
  // =========================================================

  String _randomString(int length) {
    const characters =
        'abcdefghijklmnopqrstuvwxyz'
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        '0123456789';

    final random =
        Random.secure();

    return List.generate(
      length,
      (_) {
        return characters[
          random.nextInt(
            characters.length,
          )
        ];
      },
    ).join();
  }

  // =========================================================
  // INFORMATIONS DE L'APPAREIL
  // =========================================================

  Future<Map<String, String>>
      getDeviceInformation() async {
    String deviceName =
        'Appareil';

    String deviceType =
        'Ordinateur';

    String browser = '';

    // =======================================================
    // WEB
    // =======================================================

    if (kIsWeb) {
      try {
        final webInfo =
            await _deviceInfo.webBrowserInfo;

        final browserName =
            webInfo.browserName.name;

        browser =
            _formatBrowserName(
          browserName,
        );

        final platform =
            webInfo.platform ?? '';

        final platformLower =
            platform.toLowerCase();

        if (platformLower.contains('windows')) {
          deviceName =
              'PC Windows';

          deviceType =
              'Ordinateur';
        } else if (platformLower.contains('mac')) {
          deviceName =
              'Mac';

          deviceType =
              'Ordinateur';
        } else if (platformLower.contains('android')) {
          deviceName =
              'Téléphone Android';

          deviceType =
              'Smartphone';
        } else if (platformLower.contains('ios')) {
          deviceName =
              'iPhone';

          deviceType =
              'Smartphone';
        } else {
          deviceName =
              'Ordinateur';

          deviceType =
              'Ordinateur';
        }

        debugPrint(
          '[DEVICE SESSION] Web détecté: '
          'name=$deviceName, '
          'type=$deviceType, '
          'browser=$browser',
        );
      } catch (e) {
        debugPrint(
          '[DEVICE SESSION] Erreur informations Web: $e',
        );

        deviceName =
            'Ordinateur';

        deviceType =
            'Ordinateur';

        browser =
            'Navigateur Web';
      }
    }

    // =======================================================
    // ANDROID
    // =======================================================

    else {
      try {
        final androidInfo =
            await _deviceInfo.androidInfo;

        final manufacturer =
            androidInfo.manufacturer.trim();

        final model =
            androidInfo.model.trim();

        if (manufacturer.isNotEmpty &&
            model.isNotEmpty) {
          deviceName =
              '$manufacturer $model';
        } else if (model.isNotEmpty) {
          deviceName =
              model;
        } else {
          deviceName =
              'Téléphone Android';
        }

        deviceType =
            'Smartphone';

        debugPrint(
          '[DEVICE SESSION] Android détecté: '
          'name=$deviceName, '
          'type=$deviceType, '
          'model=$model',
        );
      } catch (e) {
        debugPrint(
          '[DEVICE SESSION] Erreur informations Android: $e',
        );

        deviceName =
            'Téléphone Android';

        deviceType =
            'Smartphone';
      }
    }

    final deviceIdentifier =
        await _getDeviceIdentifier();

    debugPrint(
      '[DEVICE SESSION] Informations finales: '
      'identifier=$deviceIdentifier, '
      'name=$deviceName, '
      'type=$deviceType, '
      'browser=$browser',
    );

    return {
      'deviceIdentifier':
          deviceIdentifier,
      'deviceName':
          deviceName,
      'deviceType':
          deviceType,
      'browser':
          browser,
    };
  }

  // =========================================================
  // NOM DU NAVIGATEUR
  // =========================================================

  String _formatBrowserName(
    String browser,
  ) {
    final value =
        browser.toLowerCase();

    if (value.contains('chrome')) {
      return 'Chrome';
    }

    if (value.contains('firefox')) {
      return 'Firefox';
    }

    if (value.contains('safari')) {
      return 'Safari';
    }

    if (value.contains('edge')) {
      return 'Edge';
    }

    if (value.contains('opera')) {
      return 'Opera';
    }

    if (browser.isEmpty) {
      return 'Navigateur Web';
    }

    return browser;
  }

  // =========================================================
  // CRÉER / RÉUTILISER UNE SESSION
  // =========================================================

  Future<DeviceSession> createSession({
    required int userId,
    required String deviceIdentifier,
    required String deviceName,
    required String deviceType,
    required String browser,
  }) async {
    final cleanIdentifier =
        deviceIdentifier.trim();

    if (cleanIdentifier.isEmpty) {
      throw DeviceSessionException(
        'Identifiant de l’appareil invalide.',
      );
    }

    const endpoint =
        '/api/device-sessions';

    final requestBody = {
      'userId':
          userId,
      'deviceIdentifier':
          cleanIdentifier,
      'deviceName':
          deviceName.trim().isEmpty
              ? 'Appareil'
              : deviceName.trim(),
      'deviceType':
          deviceType.trim().isEmpty
              ? 'Inconnu'
              : deviceType.trim(),
      'browser':
          browser.trim(),
    };

    debugPrint(
      '==================================================',
    );

    debugPrint(
      '[DEVICE SESSION] POST CREATE SESSION',
    );

    debugPrint(
      '[DEVICE SESSION] URL: '
      '${ApiService.baseUrl}$endpoint',
    );

    debugPrint(
      '[DEVICE SESSION] userId: $userId',
    );

    debugPrint(
      '[DEVICE SESSION] deviceIdentifier: '
      '$cleanIdentifier',
    );

    debugPrint(
      '[DEVICE SESSION] deviceName: '
      '${requestBody['deviceName']}',
    );

    debugPrint(
      '[DEVICE SESSION] deviceType: '
      '${requestBody['deviceType']}',
    );

    debugPrint(
      '[DEVICE SESSION] browser: '
      '${requestBody['browser']}',
    );

    debugPrint(
      '[DEVICE SESSION] JSON: '
      '${jsonEncode(requestBody)}',
    );

    try {
      final response =
          await _apiService
              .post(
                endpoint,
                body: requestBody,
              )
              .timeout(
                _requestTimeout,
              );

      debugPrint(
        '[DEVICE SESSION] HTTP STATUS: '
        '${response.statusCode}',
      );

      debugPrint(
        '[DEVICE SESSION] HTTP BODY: '
        '${response.body}',
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        String message =
            'Impossible d’enregistrer la session.';

        if (response.body.trim().isNotEmpty) {
          try {
            final data =
                _apiService.decodeResponse(
              response,
            );

            if (data is Map &&
                data['message'] != null) {
              message =
                  data['message'].toString();
            } else if (data is Map &&
                data['error'] != null) {
              message =
                  data['error'].toString();
            } else {
              message =
                  response.body;
            }
          } catch (_) {
            message =
                response.body;
          }
        }

        debugPrint(
          '[DEVICE SESSION] ERREUR SERVEUR: '
          '$message',
        );

        throw DeviceSessionException(
          'Erreur serveur HTTP '
          '${response.statusCode}: $message',
        );
      }

      if (response.body.trim().isEmpty) {
        throw DeviceSessionException(
          'Le serveur a accepté la requête '
          'mais a retourné une réponse vide.',
        );
      }

      final decoded =
          _apiService.decodeResponse(
        response,
      );

      if (decoded is! Map) {
        throw DeviceSessionException(
          'Réponse invalide du serveur.',
        );
      }

      final session =
          DeviceSession.fromJson(
        Map<String, dynamic>.from(
          decoded,
        ),
      );

      debugPrint(
        '[DEVICE SESSION] SESSION CRÉÉE/RÉUTILISÉE',
      );

      debugPrint(
        '[DEVICE SESSION] ID: ${session.id}',
      );

      debugPrint(
        '[DEVICE SESSION] Identifier: '
        '${session.deviceIdentifier}',
      );

      debugPrint(
        '[DEVICE SESSION] Active: '
        '${session.active}',
      );

      debugPrint(
        '[DEVICE SESSION] Current: '
        '${session.current}',
      );

      debugPrint(
        '==================================================',
      );

      startHeartbeat(
        userId: userId,
        deviceIdentifier: cleanIdentifier,
      );

      return session;
    } on DeviceSessionException {
      rethrow;
    } catch (e) {
      debugPrint(
        '[DEVICE SESSION] EXCEPTION CREATE SESSION: '
        '$e',
      );

      debugPrint(
        '[DEVICE SESSION] TYPE: '
        '${e.runtimeType}',
      );

      throw DeviceSessionException(
        'Erreur lors de la création de la session : $e',
      );
    }
  }

  // =========================================================
  // DÉMARRER LE HEARTBEAT
  // =========================================================

  void startHeartbeat({
    required int userId,
    required String deviceIdentifier,
  }) {
    final cleanIdentifier =
        deviceIdentifier.trim();

    if (cleanIdentifier.isEmpty) {
      debugPrint(
        '[HEARTBEAT] Identifiant vide. '
        'Heartbeat non démarré.',
      );

      return;
    }

    _heartbeatTimer?.cancel();

    _heartbeatUserId =
        userId;

    _heartbeatDeviceIdentifier =
        cleanIdentifier;

    _heartbeatInProgress =
        false;

    debugPrint(
      '[HEARTBEAT] Démarrage du heartbeat',
    );

    debugPrint(
      '[HEARTBEAT] userId=$userId',
    );

    debugPrint(
      '[HEARTBEAT] deviceIdentifier=$cleanIdentifier',
    );

    _sendHeartbeat();

    _heartbeatTimer =
        Timer.periodic(
      _heartbeatInterval,
      (_) {
        _sendHeartbeat();
      },
    );
  }

  // =========================================================
  // ENVOYER LE HEARTBEAT
  // =========================================================

  Future<void> _sendHeartbeat() async {
    if (_heartbeatInProgress) {
      return;
    }

    final userId =
        _heartbeatUserId;

    final deviceIdentifier =
        _heartbeatDeviceIdentifier;

    if (userId == null ||
        deviceIdentifier == null ||
        deviceIdentifier.trim().isEmpty) {
      return;
    }

    _heartbeatInProgress =
        true;

    const endpoint =
        '/api/device-sessions/heartbeat';

    final requestBody = {
      'userId':
          userId,
      'deviceIdentifier':
          deviceIdentifier,
    };

    try {
      debugPrint(
        '[HEARTBEAT] Envoi...',
      );

      final response =
          await _apiService
              .post(
                endpoint,
                body: requestBody,
              )
              .timeout(
                _requestTimeout,
              );

      debugPrint(
        '[HEARTBEAT] STATUS: '
        '${response.statusCode}',
      );

      debugPrint(
        '[HEARTBEAT] BODY: '
        '${response.body}',
      );

      // =====================================================
      // SESSION INVALIDÉE À DISTANCE
      // =====================================================

      if (response.statusCode == 401 ||
          response.statusCode == 403) {
        debugPrint(
          '[HEARTBEAT] SESSION INVALIDÉE À DISTANCE.',
        );

        stopHeartbeat();

        if (!_sessionInvalidatedController.isClosed) {
          _sessionInvalidatedController.add(null);
        }

        return;
      }

      // =====================================================
      // RÉPONSE SERVEUR
      // =====================================================

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        // Certains backends peuvent retourner HTTP 200
        // avec active=false au lieu de 401/403.
        if (response.body.trim().isNotEmpty) {
          try {
            final decoded =
                _apiService.decodeResponse(
              response,
            );

            if (decoded is Map &&
                decoded['active'] == false) {
              debugPrint(
                '[HEARTBEAT] '
                'Le serveur indique que la session est inactive.',
              );

              stopHeartbeat();

              if (!_sessionInvalidatedController
                  .isClosed) {
                _sessionInvalidatedController
                    .add(null);
              }

              return;
            }
          } catch (_) {
            // La réponse peut être un simple texte.
            // Dans ce cas, on considère le heartbeat
            // comme réussi si le statut HTTP est 2xx.
          }
        }

        debugPrint(
          '[HEARTBEAT] Session toujours active.',
        );

        return;
      }

      // =====================================================
      // AUTRE ERREUR SERVEUR
      // =====================================================

      debugPrint(
        '[HEARTBEAT] Réponse serveur inattendue: '
        '${response.body}',
      );
    } on TimeoutException {
      debugPrint(
        '[HEARTBEAT] Timeout. '
        'Le serveur n’a pas répondu.',
      );
    } catch (e) {
      debugPrint(
        '[HEARTBEAT] Erreur: $e',
      );
    } finally {
      _heartbeatInProgress = false;
    }
  }

  // =========================================================
  // ARRÊTER LE HEARTBEAT
  // =========================================================

  void stopHeartbeat() {
    debugPrint(
      '[HEARTBEAT] Arrêt du heartbeat.',
    );

    _heartbeatTimer?.cancel();

    _heartbeatTimer =
        null;

    _heartbeatUserId =
        null;

    _heartbeatDeviceIdentifier =
        null;

    _heartbeatInProgress =
        false;
  }

  // =========================================================
  // RÉCUPÉRER LES SESSIONS
  // =========================================================

  Future<List<DeviceSession>>
      getUserSessions(
    int userId,
  ) async {
    try {
      final currentDeviceIdentifier =
          await _getDeviceIdentifier();

      final endpoint =
          '/api/device-sessions/user/$userId';

      final queryString =
          '?currentDeviceIdentifier='
          '${Uri.encodeQueryComponent(currentDeviceIdentifier)}';

      debugPrint(
        '==================================================',
      );

      debugPrint(
        '[DEVICE SESSION] GET USER SESSIONS',
      );

      debugPrint(
        '[DEVICE SESSION] URL: '
        '${ApiService.baseUrl}'
        '$endpoint'
        '$queryString',
      );

      debugPrint(
        '[DEVICE SESSION] Current identifier: '
        '$currentDeviceIdentifier',
      );

      // UNE SEULE REQUÊTE
      final response =
          await _apiService
              .get(
                '$endpoint$queryString',
              )
              .timeout(
                _requestTimeout,
              );

      debugPrint(
        '[DEVICE SESSION] GET STATUS: '
        '${response.statusCode}',
      );

      debugPrint(
        '[DEVICE SESSION] GET BODY: '
        '${response.body}',
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        String message =
            'Impossible de récupérer les appareils connectés.';

        try {
          final data =
              _apiService.decodeResponse(
            response,
          );

          if (data is Map &&
              data['message'] != null) {
            message =
                data['message'].toString();
          } else if (data is Map &&
              data['error'] != null) {
            message =
                data['error'].toString();
          }
        } catch (_) {}

        throw DeviceSessionException(
          'Erreur serveur HTTP '
          '${response.statusCode}: $message',
        );
      }

      if (response.body.trim().isEmpty) {
        throw DeviceSessionException(
          'Le serveur a retourné une réponse vide.',
        );
      }

      final decoded =
          _apiService.decodeResponse(
        response,
      );

      if (decoded is! List) {
        throw DeviceSessionException(
          'Réponse invalide du serveur.',
        );
      }

      final sessions =
          decoded
              .whereType<Map>()
              .map(
                (json) =>
                    DeviceSession.fromJson(
                  Map<String, dynamic>.from(
                    json,
                  ),
                ),
              )
              .toList();

      debugPrint(
        '[DEVICE SESSION] Nombre de sessions: '
        '${sessions.length}',
      );

      for (final session in sessions) {
        debugPrint(
          '[DEVICE SESSION] '
          'id=${session.id} | '
          'identifier=${session.deviceIdentifier} | '
          'name=${session.deviceName} | '
          'type=${session.deviceType} | '
          'current=${session.current} | '
          'active=${session.active}',
        );
      }

      debugPrint(
        '==================================================',
      );

      return sessions;
    } on DeviceSessionException {
      rethrow;
    } catch (e) {
      debugPrint(
        '[DEVICE SESSION] EXCEPTION GET SESSIONS: '
        '$e',
      );

      debugPrint(
        '[DEVICE SESSION] TYPE: '
        '${e.runtimeType}',
      );

      throw DeviceSessionException(
        'Erreur lors de la récupération des sessions : $e',
      );
    }
  }

  // =========================================================
  // DÉCONNECTER UNE SESSION
  // =========================================================

  Future<void> disconnectSession(
    int sessionId,
  ) async {
    final endpoint =
        '/api/device-sessions/$sessionId';

    debugPrint(
      '[DEVICE SESSION] DELETE SESSION '
      'id=$sessionId',
    );

    try {
      final response =
          await _apiService
              .delete(
                endpoint,
              )
              .timeout(
                _requestTimeout,
              );

      debugPrint(
        '[DEVICE SESSION] DELETE STATUS: '
        '${response.statusCode}',
      );

      debugPrint(
        '[DEVICE SESSION] DELETE BODY: '
        '${response.body}',
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        String message =
            'Impossible de déconnecter la session.';

        try {
          final data =
              _apiService.decodeResponse(
            response,
          );

          if (data is Map &&
              data['message'] != null) {
            message =
                data['message'].toString();
          } else if (data is Map &&
              data['error'] != null) {
            message =
                data['error'].toString();
          }
        } catch (_) {}

        throw DeviceSessionException(
          'Erreur serveur HTTP '
          '${response.statusCode}: $message',
        );
      }
    } on DeviceSessionException {
      rethrow;
    } catch (e) {
      debugPrint(
        '[DEVICE SESSION] EXCEPTION DELETE: $e',
      );

      throw DeviceSessionException(
        'Erreur lors de la déconnexion : $e',
      );
    }
  }

  // =========================================================
  // DÉCONNECTER LES AUTRES APPAREILS
  // =========================================================

  Future<void> disconnectOtherSessions(
    int userId,
    int currentSessionId,
  ) async {
    const endpoint =
        '/api/device-sessions/disconnect-others';

    final requestBody = {
      'userId':
          userId,
      'currentSessionId':
          currentSessionId,
    };

    debugPrint(
      '[DEVICE SESSION] DISCONNECT OTHERS',
    );

    debugPrint(
      '[DEVICE SESSION] URL: '
      '${ApiService.baseUrl}$endpoint',
    );

    debugPrint(
      '[DEVICE SESSION] BODY: '
      '${jsonEncode(requestBody)}',
    );

    try {
      final response =
          await _apiService
              .post(
                endpoint,
                body: requestBody,
              )
              .timeout(
                _requestTimeout,
              );

      debugPrint(
        '[DEVICE SESSION] DISCONNECT OTHERS STATUS: '
        '${response.statusCode}',
      );

      debugPrint(
        '[DEVICE SESSION] DISCONNECT OTHERS BODY: '
        '${response.body}',
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        String message =
            'Impossible de déconnecter les autres appareils.';

        try {
          final data =
              _apiService.decodeResponse(
            response,
          );

          if (data is Map &&
              data['message'] != null) {
            message =
                data['message'].toString();
          } else if (data is Map &&
              data['error'] != null) {
            message =
                data['error'].toString();
          }
        } catch (_) {}

        throw DeviceSessionException(
          'Erreur serveur HTTP '
          '${response.statusCode}: $message',
        );
      }
    } on DeviceSessionException {
      rethrow;
    } catch (e) {
      debugPrint(
        '[DEVICE SESSION] EXCEPTION DISCONNECT OTHERS: '
        '$e',
      );

      throw DeviceSessionException(
        'Erreur lors de la déconnexion des autres appareils : $e',
      );
    }
  }

  // =========================================================
  // DÉCONNECTER TOUS LES APPAREILS
  // =========================================================

  Future<void> disconnectAllSessions(
    int userId,
  ) async {
    const endpoint =
        '/api/device-sessions/disconnect-all';

    final requestBody = {
      'userId':
          userId,
    };

    debugPrint(
      '[DEVICE SESSION] DISCONNECT ALL',
    );

    debugPrint(
      '[DEVICE SESSION] URL: '
      '${ApiService.baseUrl}$endpoint',
    );

    debugPrint(
      '[DEVICE SESSION] BODY: '
      '${jsonEncode(requestBody)}',
    );

    try {
      final response =
          await _apiService
              .post(
                endpoint,
                body: requestBody,
              )
              .timeout(
                _requestTimeout,
              );

      debugPrint(
        '[DEVICE SESSION] DISCONNECT ALL STATUS: '
        '${response.statusCode}',
      );

      debugPrint(
        '[DEVICE SESSION] DISCONNECT ALL BODY: '
        '${response.body}',
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        String message =
            'Impossible de déconnecter tous les appareils.';

        try {
          final data =
              _apiService.decodeResponse(
            response,
          );

          if (data is Map &&
              data['message'] != null) {
            message =
                data['message'].toString();
          } else if (data is Map &&
              data['error'] != null) {
            message =
                data['error'].toString();
          }
        } catch (_) {}

        throw DeviceSessionException(
          'Erreur serveur HTTP '
          '${response.statusCode}: $message',
        );
      }

      stopHeartbeat();
    } on DeviceSessionException {
      rethrow;
    } catch (e) {
      debugPrint(
        '[DEVICE SESSION] EXCEPTION DISCONNECT ALL: '
        '$e',
      );

      throw DeviceSessionException(
        'Erreur lors de la déconnexion de tous les appareils : $e',
      );
    }
  }
}