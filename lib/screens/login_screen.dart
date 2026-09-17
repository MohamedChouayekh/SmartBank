import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/device_session_service.dart';
import '../services/biometric_service.dart';
import '../services/otp_service.dart';

import '../widgets/main_navigation.dart';
import '../widgets/smartbank_brand.dart';

import 'create_account_screen.dart';
import 'forgot_password_screen.dart';
import 'admin_cards_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;

  const LoginScreen({
    super.key,
    required this.onThemeChanged,
  });

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final TextEditingController
      usernameController =
      TextEditingController();

  final TextEditingController
      passwordController =
      TextEditingController();

  final AuthService _authService =
      AuthService();

  final OtpService _otpService =
      OtpService();

  final DeviceSessionService
      _deviceSessionService =
      DeviceSessionService();

  final BiometricService
      _biometricService =
      BiometricService();

  final LocalAuthentication
      _localAuth =
      LocalAuthentication();

  static const FlutterSecureStorage
      _secureStorage =
      FlutterSecureStorage();

  bool _obscurePassword = true;

  bool _isLoading = false;
  bool _isBiometricLoading = false;

  bool _isMobilePlatform = false;
  bool _showBiometricButton = false;

  String _deviceIdentifier = '';

  // =========================================================
  // COULEURS SMARTBANK
  // =========================================================

  static const Color primaryBlue =
      Color(0xFF0B5AA6);

  static const Color darkBlue =
      Color(0xFF06457E);

  static const Color lightBlue =
      Color(0xFFF2F7FC);

  static const Color yellow =
      Color(0xFFF7C948);

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _isMobilePlatform =
        !kIsWeb &&
        (defaultTargetPlatform ==
                TargetPlatform.android ||
            defaultTargetPlatform ==
                TargetPlatform.iOS);

    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // =========================================================
  // BIOMÉTRIE DISPONIBLE
  // =========================================================

  Future<void>
      _checkBiometricAvailability() async {
    if (!_isMobilePlatform) {
      if (mounted) {
        setState(() {
          _showBiometricButton =
              false;
        });
      }

      return;
    }

    try {
      final deviceInfo =
          await _deviceSessionService
              .getDeviceInformation();

      _deviceIdentifier =
          (deviceInfo[
                      'deviceIdentifier'] ??
                  '')
              .toString();

      if (_deviceIdentifier.isEmpty) {
        return;
      }

      final isSupported =
          await _localAuth
              .isDeviceSupported();

      if (!isSupported) {
        if (mounted) {
          setState(() {
            _showBiometricButton =
                false;
          });
        }

        return;
      }

      final canCheck =
          await _localAuth
              .canCheckBiometrics;

      if (!canCheck) {
        if (mounted) {
          setState(() {
            _showBiometricButton =
                false;
          });
        }

        return;
      }

      final biometrics =
          await _localAuth
              .getAvailableBiometrics();

      if (mounted) {
        setState(() {
          _showBiometricButton =
              biometrics.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint(
        '[BIOMETRIC LOGIN] Erreur disponibilité : $e',
      );

      if (mounted) {
        setState(() {
          _showBiometricButton =
              false;
        });
      }
    }
  }

  // =========================================================
  // LOGIN BIOMÉTRIQUE
  // =========================================================

  Future<void> _loginWithBiometric() async {
    if (!_isMobilePlatform) {
      return;
    }

    if (_isBiometricLoading) {
      return;
    }

    setState(() {
      _isBiometricLoading = true;
    });

    try {
      debugPrint(
        '[BIOMETRIC LOGIN] Démarrage de l’authentification',
      );

      // =======================================================
      // 1. AUTHENTIFICATION FACIALE / BIOMÉTRIQUE
      // =======================================================

      final authenticated =
          await _localAuth.authenticate(
        localizedReason:
            'Utilisez votre visage ou votre empreinte pour vous connecter à SmartBank.',
        biometricOnly: true,

        // IMPORTANT :
        // On ne garde pas l'authentification en attente
        // si l'application passe en arrière-plan.
        persistAcrossBackgrounding: false,
      );

      debugPrint(
        '[BIOMETRIC LOGIN] Résultat authentification : $authenticated',
      );

      if (!authenticated) {
        _showMessage(
          'Authentification biométrique non reconnue.',
          error: true,
        );

        return;
      }

      // =======================================================
      // 2. RÉCUPÉRATION DE L'IDENTIFIANT DE L'APPAREIL
      // =======================================================

      final deviceInfo =
          await _deviceSessionService
              .getDeviceInformation();

      _deviceIdentifier =
          (deviceInfo['deviceIdentifier'] ?? '')
              .toString();

      if (_deviceIdentifier.trim().isEmpty) {
        _showMessage(
          'Impossible d’identifier cet appareil.',
          error: true,
        );

        return;
      }

      // =======================================================
      // 3. VÉRIFICATION DE L'ASSOCIATION BIOMÉTRIQUE
      // =======================================================

      final status =
          await _biometricService.getDeviceStatus(
        _deviceIdentifier,
      );

      final associated =
          status['associated'] == true;

      final enabled =
          status['enabled'] == true;

      final ownerUserId =
          (status['ownerUserId'] as num?)?.toInt();

      debugPrint(
        '[BIOMETRIC LOGIN] associated=$associated, '
        'enabled=$enabled, '
        'ownerUserId=$ownerUserId',
      );

      // =======================================================
      // 4. AUCUN COMPTE ASSOCIÉ
      // =======================================================

      if (!associated || ownerUserId == null) {
        _showMessage(
          'Aucun compte n’est associé à la biométrie de cet appareil. '
          'Connectez-vous avec votre mot de passe pour la configurer.',
          error: true,
        );

        return;
      }

      // =======================================================
      // 5. BIOMÉTRIE DÉSACTIVÉE
      // =======================================================

      if (!enabled) {
        _showMessage(
          'La connexion biométrique est actuellement désactivée. '
          'Connectez-vous avec votre mot de passe pour la réactiver.',
          error: true,
        );

        return;
      }

      // =======================================================
      // 6. RÉCUPÉRATION DES IDENTIFIANTS SÉCURISÉS
      // =======================================================

      final username =
          await _secureStorage.read(
        key:
            'biometric_username_user_$ownerUserId',
      );

      final password =
          await _secureStorage.read(
        key:
            'biometric_password_user_$ownerUserId',
      );

      if (username == null ||
          password == null ||
          username.isEmpty ||
          password.isEmpty) {
        _showMessage(
          'Les informations de connexion biométrique sont introuvables. '
          'Connectez-vous d’abord avec votre mot de passe.',
          error: true,
        );

        return;
      }

      // =======================================================
      // 7. CONNEXION SMARTBANK
      // =======================================================

      debugPrint(
        '[BIOMETRIC LOGIN] Identifiants récupérés, '
        'connexion SmartBank...',
      );

      await _performLogin(
        username: username,
        password: password,
      );
    } on BiometricServiceException catch (e) {
      debugPrint(
        '[BIOMETRIC LOGIN] Erreur service biométrique : ${e.message}',
      );

      if (mounted) {
        _showMessage(
          e.message,
          error: true,
        );
      }
    } on LocalAuthException catch (e) {
      debugPrint(
        '[BIOMETRIC LOGIN] LocalAuthException : '
        '${e.code.name} - ${e.description}',
      );

      if (!mounted) {
        return;
      }

      // L'utilisateur a simplement annulé.
      if (e.code ==
              LocalAuthExceptionCode.userCanceled ||
          e.code ==
              LocalAuthExceptionCode.systemCanceled) {
        return;
      }

      // Cas où Android bloque temporairement la biométrie.
      if (e.code ==
              LocalAuthExceptionCode.biometricLockout ||
          e.code ==
              LocalAuthExceptionCode.temporaryLockout) {
        _showMessage(
          'La biométrie est temporairement indisponible. '
          'Utilisez votre mot de passe.',
          error: true,
        );

        return;
      }

      _showMessage(
        'La reconnaissance biométrique a échoué. '
        'Vous pouvez utiliser votre mot de passe.',
        error: true,
      );
    } catch (e, stackTrace) {
      debugPrint(
        '[BIOMETRIC LOGIN] EXCEPTION : $e',
      );

      debugPrint(
        '[BIOMETRIC LOGIN] TYPE : ${e.runtimeType}',
      );

      debugPrint(
        '[BIOMETRIC LOGIN] STACK TRACE : $stackTrace',
      );

      if (mounted) {
        _showMessage(
          'Erreur lors de la connexion biométrique.',
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBiometricLoading = false;
        });
      }
    }
  }

  // =========================================================
  // LOGIN NORMAL
  // =========================================================

  Future<void> _login() async {
    final username =
        usernameController.text.trim();

    final password =
        passwordController.text;

    if (username.isEmpty ||
        password.isEmpty) {
      _showMessage(
        'Veuillez remplir tous les champs.',
        error: true,
      );

      return;
    }

    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _performLogin(
        username: username,
        password: password,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =========================================================
  // LOGIN COMMUN
  // =========================================================

  Future<void> _performLogin({
    required String username,
    required String password,
  }) async {
    debugPrint('');
    debugPrint('==========================================');
    debugPrint('[LOGIN] DÉBUT DU PROCESSUS DE CONNEXION');
    debugPrint('[LOGIN] Username : $username');
    debugPrint('==========================================');

    try {
      // ======================================================
      // 1. AUTHENTIFICATION
      // ======================================================

      debugPrint(
        '[LOGIN] ÉTAPE 1 : appel AuthService.login',
      );

      final User user =
          await _authService.login(
        username: username,
        password: password,
      );

      debugPrint(
        '[LOGIN] ÉTAPE 1 OK : utilisateur connecté, '
        'id=${user.id}, role=${user.role}',
      );

      if (!mounted) return;

      // ======================================================
      // 2. SOLDES
      // ======================================================

      debugPrint(
        '[LOGIN] ÉTAPE 2 : récupération des soldes',
      );

      final balances =
          await _authService.fetchAccountBalances(
        user.id,
      );

      debugPrint(
        '[LOGIN] ÉTAPE 2 OK : balances=$balances',
      );

      if (!mounted) return;

      // ======================================================
      // 3. SESSION APPAREIL
      // ======================================================

      debugPrint(
        '[LOGIN] ÉTAPE 3 : création session appareil',
      );

      await _createDeviceSession(
        user,
      );

      debugPrint(
        '[LOGIN] ÉTAPE 3 OK',
      );

      // ======================================================
      // 4. CREDENTIALS PAR COMPTE
      // ======================================================

      debugPrint(
        '[LOGIN] ÉTAPE 4 : sauvegarde identifiants biométriques',
      );

      await _secureStorage.write(
        key:
            'biometric_username_user_${user.id}',
        value: username,
      );

      await _secureStorage.write(
        key:
            'biometric_password_user_${user.id}',
        value: password,
      );

      debugPrint(
        '[LOGIN] ÉTAPE 4 OK',
      );

      if (!mounted) return;

      // ======================================================
      // 5. NAVIGATION SELON LE RÔLE
      // ======================================================

      debugPrint(
        '[LOGIN] ÉTAPE 5 : navigation, role=${user.role}',
      );

      // ------------------------------------------------------
      // ADMINISTRATION BANCAIRE
      // ------------------------------------------------------

      if (user.role == 'BANK_ADMIN') {
        debugPrint(
          '[LOGIN] BANK_ADMIN → espace Administration',
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const AdminCardsScreen(),
          ),
        );
      }

      // ------------------------------------------------------
      // CLIENT NORMAL
      // ------------------------------------------------------

      else {
        debugPrint(
          '[LOGIN] CLIENT → application bancaire',
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MainNavigation(
              user: user,

              initialCourantBalance:
                  (balances['courant'] as num?)
                          ?.toDouble() ??
                      0.0,

              initialEpargneBalance:
                  (balances['epargne'] as num?)
                          ?.toDouble() ??
                      0.0,

              courantAccountNumber:
                  balances[
                          'courantAccountNumber']
                      as String? ??
                  '',

              epargneAccountNumber:
                  balances[
                          'epargneAccountNumber']
                      as String? ??
                  '',

              onThemeChanged:
                  widget.onThemeChanged,
            ),
          ),
        );
      }

      debugPrint(
        '[LOGIN] ÉTAPE 5 OK',
      );

      debugPrint(
        '[LOGIN] CONNEXION TERMINÉE AVEC SUCCÈS',
      );

      debugPrint(
        '==========================================',
      );
    } on AuthException catch (e) {
      debugPrint('');
      debugPrint(
        '[LOGIN] AuthException : $e',
      );
      debugPrint(
        '[LOGIN] Message AuthException : ${e.message}',
      );
      debugPrint(
        '==========================================',
      );

      if (!mounted) return;

      _showMessage(
        e.message,
        error: true,
      );
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint(
        '[LOGIN] ERREUR : $e',
      );
      debugPrint(
        '[LOGIN] TYPE ERREUR : ${e.runtimeType}',
      );
      debugPrint(
        '[LOGIN] STACK TRACE : $stackTrace',
      );
      debugPrint(
        '==========================================',
      );

      if (!mounted) return;

      _showMessage(
        'Erreur login : $e',
        error: true,
      );
    }
  }

  // =========================================================
  // SESSION APPAREIL
  // =========================================================

  Future<void> _createDeviceSession(
    User user,
  ) async {
    try {
      final deviceInfo =
          await _deviceSessionService
              .getDeviceInformation();

      final deviceIdentifier =
          (deviceInfo[
                      'deviceIdentifier'] ??
                  '')
              .toString();

      if (deviceIdentifier
          .trim()
          .isEmpty) {
        return;
      }

      final session =
          await _deviceSessionService
              .createSession(
        userId:
            user.id,
        deviceIdentifier:
            deviceIdentifier,
        deviceName:
            deviceInfo[
                    'deviceName'] ??
                'Appareil',
        deviceType:
            deviceInfo[
                    'deviceType'] ??
                'Inconnu',
        browser:
            deviceInfo[
                    'browser'] ??
                '',
      );

      debugPrint(
        'Session créée/réutilisée. '
        'ID=${session.id} '
        'deviceIdentifier='
        '${session.deviceIdentifier}',
      );
    } catch (e) {
      debugPrint(
        'Erreur session appareil : $e',
      );
    }
  }

  // =========================================================
  // CRÉER COMPTE
  // =========================================================

  Future<void>
      _openCreateAccount() async {
    final result =
        await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                const CreateAccountScreen(),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    if (result is User) {
      setState(() {
        usernameController.text =
            result.username;

        passwordController.clear();
      });

      _showMessage(
        'Compte créé avec succès. '
        'Vous pouvez maintenant vous connecter.',
      );
    } else if (result
        is Map<String, dynamic>) {
      final user =
          result['user'];

      if (user is User) {
        setState(() {
          usernameController.text =
              user.username;

          passwordController.clear();
        });

        _showMessage(
          'Compte créé avec succès. '
          'Vous pouvez maintenant vous connecter.',
        );
      }
    }
  }

  // =========================================================
  // MOT DE PASSE OUBLIÉ
  // =========================================================

  Future<void>
      _forgotPassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                ForgotPasswordScreen(
          otpService:
              _otpService,
        ),
      ),
    );
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(message),
        backgroundColor:
            error
                ? Colors.red
                : null,
        behavior:
            SnackBarBehavior.floating,
        margin:
            const EdgeInsets.all(
          16,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            12,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final isDark =
        theme.brightness ==
            Brightness.dark;

    return Scaffold(
      // ======================================================
      // APP BAR
      // ======================================================

      appBar: AppBar(
        backgroundColor:
            Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin:
                const EdgeInsets.only(
              right: 10,
              top: 6,
              bottom: 6,
            ),
            decoration:
                BoxDecoration(
              color:
                  theme.cardColor
                      .withValues(
                alpha: 0.72,
              ),
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child:
                IconButton(
              onPressed:
                  widget.onThemeChanged,
              tooltip: isDark
                  ? 'Activer le mode clair'
                  : 'Activer le mode sombre',
              icon:
                  Icon(
                isDark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
              ),
            ),
          ),
        ],
      ),

      // ======================================================
      // BODY
      // ======================================================

      body:
          Stack(
        children: [
          // ====================================================
          // DÉCOR SUPÉRIEUR
          // ====================================================

          Positioned(
            top: -90,
            right: -70,
            child:
                Container(
              width:
                  210,
              height:
                  210,
              decoration:
                  BoxDecoration(
                color:
                    primaryBlue.withValues(
                  alpha:
                      0.08,
                ),
                shape:
                    BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            top: 125,
            left: -115,
            child:
                Container(
              width:
                  220,
              height:
                  220,
              decoration:
                  BoxDecoration(
                color:
                    yellow.withValues(
                  alpha:
                      0.10,
                ),
                shape:
                    BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child:
                Center(
              child:
                  SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child:
                    ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth:
                        450,
                  ),
                  child:
                      Column(
                    children: [
                      // ==========================================
                      // LOGO
                      // ==========================================

                      const Center(
                        child:
                            SmartBankBrand(
                          iconSize:
                              62,
                        ),
                      ),

                      const SizedBox(
                        height:
                            17,
                      ),

                      // ==========================================
                      // TITRE
                      // ==========================================

                      Text(
                        'Votre banque, simplement.',
                        textAlign:
                            TextAlign.center,
                        style:
                            TextStyle(
                          fontSize:
                              25,
                          fontWeight:
                              FontWeight
                                  .w800,
                          color:
                              isDark
                                  ? Colors.white
                                  : darkBlue,
                        ),
                      ),

                      const SizedBox(
                        height:
                            7,
                      ),

                      Text(
                        'Sécurisée, moderne et pensée pour vous.',
                        textAlign:
                            TextAlign.center,
                        style:
                            TextStyle(
                          fontSize:
                              13.5,
                          height:
                              1.4,
                          color:
                              theme
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(
                                    alpha:
                                        0.72,
                                  ),
                        ),
                      ),

                      const SizedBox(
                        height:
                            28,
                      ),

                      // ==========================================
                      // CARTE LOGIN
                      // ==========================================

                      Container(
                        padding:
                            const EdgeInsets.fromLTRB(
                          20,
                          22,
                          20,
                          20,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              theme
                                  .cardColor,
                          borderRadius:
                              BorderRadius.circular(
                            24,
                          ),
                          border:
                              Border.all(
                            color:
                                primaryBlue.withValues(
                              alpha:
                                  isDark
                                      ? 0.20
                                      : 0.08,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withValues(
                                alpha:
                                    isDark
                                        ? 0.16
                                        : 0.07,
                              ),
                              blurRadius:
                                  28,
                              offset:
                                  const Offset(
                                0,
                                12,
                              ),
                            ),
                          ],
                        ),
                        child:
                            Column(
                          children: [
                            // =====================================
                            // IDENTIFIANT
                            // =====================================

                            TextField(
                              controller:
                                  usernameController,
                              enabled:
                                  !_isLoading &&
                                      !_isBiometricLoading,
                              textInputAction:
                                  TextInputAction.next,
                              decoration:
                                  InputDecoration(
                                labelText:
                                    'Identifiant',
                                hintText:
                                    'Entrez votre identifiant',
                                prefixIcon:
                                    const Icon(
                                  Icons
                                      .person_outline_rounded,
                                ),
                                filled:
                                    true,
                                fillColor:
                                    lightBlue.withValues(
                                  alpha:
                                      isDark
                                          ? 0.06
                                          : 0.55,
                                ),
                                border:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    15,
                                  ),
                                  borderSide:
                                      BorderSide.none,
                                ),
                                enabledBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    15,
                                  ),
                                  borderSide:
                                      BorderSide(
                                    color:
                                        primaryBlue.withValues(
                                      alpha:
                                          0.10,
                                    ),
                                  ),
                                ),
                                focusedBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    15,
                                  ),
                                  borderSide:
                                      const BorderSide(
                                    color:
                                        primaryBlue,
                                    width:
                                        1.5,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              height:
                                  16,
                            ),

                            // =====================================
                            // MOT DE PASSE
                            // =====================================

                            TextField(
                              controller:
                                  passwordController,
                              enabled:
                                  !_isLoading &&
                                      !_isBiometricLoading,
                              obscureText:
                                  _obscurePassword,
                              textInputAction:
                                  TextInputAction.done,
                              onSubmitted:
                                  (_) =>
                                      _login(),
                              decoration:
                                  InputDecoration(
                                labelText:
                                    'Mot de passe',
                                hintText:
                                    'Entrez votre mot de passe',
                                prefixIcon:
                                    const Icon(
                                  Icons
                                      .lock_outline_rounded,
                                ),
                                suffixIcon:
                                    IconButton(
                                  onPressed:
                                      _isLoading ||
                                              _isBiometricLoading
                                          ? null
                                          : () {
                                              setState(
                                                () {
                                                  _obscurePassword =
                                                      !_obscurePassword;
                                                },
                                              );
                                            },
                                  icon:
                                      Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                                filled:
                                    true,
                                fillColor:
                                    lightBlue.withValues(
                                  alpha:
                                      isDark
                                          ? 0.06
                                          : 0.55,
                                ),
                                border:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    15,
                                  ),
                                  borderSide:
                                      BorderSide.none,
                                ),
                                enabledBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    15,
                                  ),
                                  borderSide:
                                      BorderSide(
                                    color:
                                        primaryBlue.withValues(
                                      alpha:
                                          0.10,
                                    ),
                                  ),
                                ),
                                focusedBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    15,
                                  ),
                                  borderSide:
                                      const BorderSide(
                                    color:
                                        primaryBlue,
                                    width:
                                        1.5,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              height:
                                  7,
                            ),

                            // =====================================
                            // MOT DE PASSE OUBLIÉ
                            // =====================================

                            Align(
                              alignment:
                                  Alignment.centerRight,
                              child:
                                  TextButton(
                                onPressed:
                                    _isLoading ||
                                            _isBiometricLoading
                                        ? null
                                        : _forgotPassword,
                                child:
                                    const Text(
                                  'Mot de passe oublié ?',
                                ),
                              ),
                            ),

                            const SizedBox(
                              height:
                                  10,
                            ),

                            // =====================================
                            // CONNEXION
                            // =====================================

                            SizedBox(
                              width:
                                  double.infinity,
                              height:
                                  56,
                              child:
                                  DecoratedBox(
                                decoration:
                                    BoxDecoration(
                                  gradient:
                                      const LinearGradient(
                                    begin:
                                        Alignment.centerLeft,
                                    end:
                                        Alignment.centerRight,
                                    colors: [
                                      primaryBlue,
                                      darkBlue,
                                    ],
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                    15,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          primaryBlue.withValues(
                                        alpha:
                                            0.22,
                                      ),
                                      blurRadius:
                                          14,
                                      offset:
                                          const Offset(
                                        0,
                                        7,
                                      ),
                                    ),
                                  ],
                                ),
                                child:
                                    ElevatedButton(
                                  onPressed:
                                      _isLoading ||
                                              _isBiometricLoading
                                          ? null
                                          : _login,
                                  style:
                                      ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.transparent,
                                    shadowColor:
                                        Colors.transparent,
                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                        15,
                                      ),
                                    ),
                                  ),
                                  child:
                                      _isLoading
                                          ? const SizedBox(
                                              width:
                                                  24,
                                              height:
                                                  24,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth:
                                                    2.2,
                                                color:
                                                    Colors.white,
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Se connecter',
                                                  style:
                                                      TextStyle(
                                                    color:
                                                        Colors.white,
                                                    fontSize:
                                                        16,
                                                    fontWeight:
                                                        FontWeight.w800,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width:
                                                      9,
                                                ),
                                                Icon(
                                                  Icons
                                                      .arrow_forward_rounded,
                                                  color:
                                                      Colors.white,
                                                  size:
                                                      20,
                                                ),
                                              ],
                                            ),
                                ),
                              ),
                            ),

                            // =====================================
                            // BIOMÉTRIE
                            // =====================================

                            if (_isMobilePlatform &&
                                _showBiometricButton) ...[
                              const SizedBox(
                                height:
                                    14,
                              ),

                              SizedBox(
                                width:
                                    double.infinity,
                                height:
                                    54,
                                child:
                                    OutlinedButton.icon(
                                  onPressed:
                                      _isLoading ||
                                              _isBiometricLoading
                                          ? null
                                          : _loginWithBiometric,
                                  icon:
                                      _isBiometricLoading
                                          ? const SizedBox(
                                              width:
                                                  20,
                                              height:
                                                  20,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth:
                                                    2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons
                                                  .fingerprint,
                                              size:
                                                  27,
                                            ),
                                  label:
                                      const Text(
                                    'Se connecter avec la biométrie',
                                    style:
                                        TextStyle(
                                      fontSize:
                                          14.5,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                  style:
                                      OutlinedButton.styleFrom(
                                    side:
                                        BorderSide(
                                      color:
                                          primaryBlue.withValues(
                                        alpha:
                                            0.35,
                                      ),
                                    ),
                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                        15,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(
                              height:
                                  17,
                            ),

                            // =====================================
                            // CRÉER COMPTE
                            // =====================================

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                              children: [
                                Flexible(
                                  child:
                                      Text(
                                    "Vous n'avez pas de compte ?",
                                    style:
                                        TextStyle(
                                      color:
                                          theme
                                              .textTheme
                                              .bodyMedium
                                              ?.color
                                              ?.withValues(
                                                alpha:
                                                    0.72,
                                              ),
                                      fontSize:
                                          13,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed:
                                      _isLoading ||
                                              _isBiometricLoading
                                          ? null
                                          : _openCreateAccount,
                                  child:
                                      const Text(
                                    'Créer un compte',
                                    style:
                                        TextStyle(
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height:
                            19,
                      ),

                      // ==========================================
                      // SÉCURITÉ
                      // ==========================================

                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal:
                              14,
                          vertical:
                              11,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              yellow.withValues(
                            alpha:
                                isDark
                                    ? 0.08
                                    : 0.13,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                        child:
                            Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            Container(
                              width:
                                  30,
                              height:
                                  30,
                              decoration:
                                  const BoxDecoration(
                                color:
                                    yellow,
                                shape:
                                    BoxShape.circle,
                              ),
                              child:
                                  const Icon(
                                Icons
                                    .verified_user_outlined,
                                size:
                                    17,
                                color:
                                    darkBlue,
                              ),
                            ),
                            const SizedBox(
                              width:
                                  9,
                            ),
                            const Text(
                              'Connexion sécurisée',
                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight.w700,
                                fontSize:
                                    12.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height:
                            25,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}