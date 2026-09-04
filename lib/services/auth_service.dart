import '../models/user.dart';
import 'api_service.dart';

class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final ApiService _apiService;

  AuthService({
    ApiService? apiService,
  }) : _apiService = apiService ?? ApiService();

  // ===========================================================
  // LOGIN
  // ===========================================================

  Future<User> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/users/login',
        body: {
          'username': username,
          'password': password,
        },
      );

      // -------------------------------------------------------
      // LOGIN REUSSI
      // -------------------------------------------------------

      if (response.statusCode == 200) {
        final data = _apiService.decodeResponse(response);

        if (data is! Map<String, dynamic>) {
          throw AuthException(
            'Réponse invalide du serveur.',
          );
        }

        return _userFromJson(data);
      }

      // -------------------------------------------------------
      // IDENTIFIANT / MOT DE PASSE INCORRECT
      // -------------------------------------------------------

      if (response.statusCode == 401) {
        throw AuthException(
          'Identifiant ou mot de passe incorrect.',
        );
      }

      // -------------------------------------------------------
      // UTILISATEUR NON TROUVE
      // -------------------------------------------------------

      if (response.statusCode == 404) {
        throw AuthException(
          'Utilisateur introuvable.',
        );
      }

      // -------------------------------------------------------
      // AUTRE ERREUR
      // -------------------------------------------------------

      throw AuthException(
        _apiService.getErrorMessage(response),
      );
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }

      throw AuthException(
        'Impossible de contacter le serveur Spring Boot.',
      );
    }
  }

  // ===========================================================
  // RECUPERER LES COMPTES D'UN UTILISATEUR
  // ===========================================================

  Future<Map<String, dynamic>> fetchAccountBalances(
    int userId,
  ) async {
    double courant = 0.0;
    double epargne = 0.0;

    String courantAccountNumber = '';
    String epargneAccountNumber = '';

    try {
      final response = await _apiService.get(
        '/api/accounts/user/$userId',
      );

      if (response.statusCode != 200) {
        return {
          'courant': courant,
          'epargne': epargne,
          'courantAccountNumber': courantAccountNumber,
          'epargneAccountNumber': epargneAccountNumber,
        };
      }

      final data = _apiService.decodeResponse(response);

      if (data is! List) {
        return {
          'courant': courant,
          'epargne': epargne,
          'courantAccountNumber': courantAccountNumber,
          'epargneAccountNumber': epargneAccountNumber,
        };
      }

      for (final account in data) {
        if (account is! Map) {
          continue;
        }

        final type =
            (account['type'] ?? '').toString().toUpperCase();

        final rawBalance = account['balance'];

        double balance = 0.0;

        if (rawBalance is num) {
          balance = rawBalance.toDouble();
        } else {
          balance =
              double.tryParse(rawBalance?.toString() ?? '') ??
                  0.0;
        }

        final accountNumber =
            (account['accountNumber'] ?? '').toString();

        if (type == 'CURRENT') {
          courant = balance;
          courantAccountNumber = accountNumber;
        } else if (type == 'SAVINGS') {
          epargne = balance;
          epargneAccountNumber = accountNumber;
        }
      }
    } catch (_) {
      // Les comptes ne doivent pas empêcher
      // l'utilisateur de se connecter.
    }

    return {
      'courant': courant,
      'epargne': epargne,
      'courantAccountNumber': courantAccountNumber,
      'epargneAccountNumber': epargneAccountNumber,
    };
  }

  // ===========================================================
  // CONVERSION JSON → USER
  // ===========================================================

  User _userFromJson(
    Map<String, dynamic> data,
  ) {
    final fullName =
        (data['fullName'] ?? '').toString().trim();

    String firstName = '';
    String lastName = '';

    if (fullName.isNotEmpty) {
      final parts =
          fullName.split(RegExp(r'\s+'));

      firstName = parts.first;

      if (parts.length > 1) {
        lastName = parts.sublist(1).join(' ');
      }
    }

    return User(
      id: _parseInt(data['id']),
      firstName: firstName,
      lastName: lastName,
      email: (data['email'] ?? '').toString(),
      phone: (data['phoneNumber'] ?? '').toString(),
      username: (data['username'] ?? '').toString(),
      address: (data['address'] ?? '').toString(),
    );
  }

  int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}
