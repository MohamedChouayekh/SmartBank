import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../services/device_session_service.dart';
import '../services/biometric_service.dart';
import '../services/otp_service.dart';

import 'forgot_password_screen.dart';
import 'login_screen.dart';

class SecurityScreen extends StatefulWidget {
  final int userId;
  final String userEmail;
  final VoidCallback? onThemeChanged;

  const SecurityScreen({
    super.key,
    required this.userId,
    required this.userEmail,
    this.onThemeChanged,
  });

  @override
  State<SecurityScreen> createState() =>
      _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  // =========================================================
  // SERVICES
  // =========================================================

  final DeviceSessionService _deviceSessionService =
      DeviceSessionService();

  final BiometricService _biometricService =
      BiometricService();

  final LocalAuthentication _localAuth =
      LocalAuthentication();

  // =========================================================
  // BIOMÉTRIE
  // =========================================================

  bool _biometricEnabled = false;

  bool _biometricAssociated = false;

  bool _biometricBelongsToCurrentUser = false;

  bool _isMobilePlatform = false;

  bool _isBiometricLoading = false;

  String _deviceIdentifier = '';

  // =========================================================
  // APPAREILS / SESSIONS
  // =========================================================

  bool _isLoadingDevices = false;

  bool _isDisconnectingDevices = false;

  List<DeviceSession> _connectedDevices = [];

  // =========================================================
  // INITIALISATION
  // =========================================================

  @override
  void initState() {
    super.initState();

    _isMobilePlatform =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    _initializeBiometric();

    _loadConnectedDevices();
  }

  // =========================================================
  // INITIALISER LA BIOMÉTRIE
  // =========================================================

  Future<void> _initializeBiometric() async {
    try {
      if (_isMobilePlatform) {
        // -----------------------------------------------------
        // TÉLÉPHONE
        // -----------------------------------------------------

        final deviceInfo =
            await _deviceSessionService
                .getDeviceInformation();

        _deviceIdentifier =
            (deviceInfo['deviceIdentifier'] ?? '')
                .toString();

        if (_deviceIdentifier.isEmpty) {
          debugPrint(
            '[BIOMETRIC] Device identifier vide.',
          );
          return;
        }

        await _loadMobileBiometricState();
      } else {
        // -----------------------------------------------------
        // PC / WEB
        //
        // IMPORTANT :
        // aucun appel à local_auth.
        // -----------------------------------------------------

        await _loadAccountBiometricState();
      }
    } catch (e) {
      debugPrint(
        '[BIOMETRIC] Erreur initialisation : $e',
      );
    }
  }

  // =========================================================
  // CHARGER ÉTAT BIOMÉTRIQUE — TÉLÉPHONE
  // =========================================================

  Future<void> _loadMobileBiometricState() async {
    try {
      final data =
          await _biometricService.getDeviceStatus(
        _deviceIdentifier,
      );

      final associated =
          data['associated'] == true;

      final enabled =
          data['enabled'] == true;

      final ownerUserId =
          (data['ownerUserId'] as num?)?.toInt();

      final belongsToCurrentUser =
          ownerUserId == widget.userId;

      if (!mounted) return;

      setState(() {
        _biometricAssociated = associated;

        _biometricEnabled =
            enabled &&
            belongsToCurrentUser;

        _biometricBelongsToCurrentUser =
            belongsToCurrentUser;
      });

      debugPrint(
        '[BIOMETRIC] associated=$associated '
        'enabled=$enabled '
        'ownerUserId=$ownerUserId '
        'currentUserId=${widget.userId}',
      );
    } catch (e) {
      debugPrint(
        '[BIOMETRIC] Erreur statut téléphone : $e',
      );

      if (!mounted) return;

      setState(() {
        _biometricAssociated = false;

        _biometricEnabled = false;

        _biometricBelongsToCurrentUser = false;
      });
    }
  }

  // =========================================================
  // CHARGER ÉTAT BIOMÉTRIQUE — PC / WEB
  // =========================================================

  Future<void> _loadAccountBiometricState() async {
    try {
      final data =
          await _biometricService.getUserStatus(
        widget.userId,
      );

      if (!mounted) return;

      setState(() {
        _biometricAssociated =
            data['associated'] == true;

        _biometricEnabled =
            data['enabled'] == true;

        _biometricBelongsToCurrentUser = true;
      });

      debugPrint(
        '[BIOMETRIC] PC/Web '
        'userId=${widget.userId} '
        'enabled=$_biometricEnabled',
      );
    } catch (e) {
      debugPrint(
        '[BIOMETRIC] Erreur statut compte : $e',
      );

      if (!mounted) return;

      setState(() {
        _biometricAssociated = false;

        _biometricEnabled = false;

        _biometricBelongsToCurrentUser = false;
      });
    }
  }

  // =========================================================
  // ACTUALISER ÉTAT BIOMÉTRIQUE
  // =========================================================

  Future<void> _refreshBiometricState() async {
    if (_isMobilePlatform) {
      if (_deviceIdentifier.isEmpty) {
        try {
          final deviceInfo =
              await _deviceSessionService
                  .getDeviceInformation();

          _deviceIdentifier =
              (deviceInfo['deviceIdentifier'] ?? '')
                  .toString();
        } catch (e) {
          debugPrint(
            '[BIOMETRIC] Impossible de récupérer '
            'deviceIdentifier : $e',
          );
        }
      }

      if (_deviceIdentifier.isNotEmpty) {
        await _loadMobileBiometricState();
      }
    } else {
      await _loadAccountBiometricState();
    }
  }

  // =========================================================
  // SWITCH BIOMÉTRIE
  // =========================================================

  Future<void> _toggleBiometric(
    bool value,
  ) async {
    // --------------------------------------------------------
    // PC / WEB
    // --------------------------------------------------------

    if (!_isMobilePlatform) {
      _showSnackBar(
        'La biométrie se gère uniquement depuis votre téléphone.',
      );
      return;
    }

    if (_isBiometricLoading) {
      return;
    }

    if (value) {
      await _enableBiometric();
    } else {
      await _disableBiometric();
    }
  }

  // =========================================================
  // ACTIVER LA BIOMÉTRIE
  // =========================================================

  Future<void> _enableBiometric() async {
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
      // ------------------------------------------------------
      // 1. IDENTIFIER LE TÉLÉPHONE
      // ------------------------------------------------------

      if (_deviceIdentifier.isEmpty) {
        final deviceInfo =
            await _deviceSessionService
                .getDeviceInformation();

        _deviceIdentifier =
            (deviceInfo['deviceIdentifier'] ?? '')
                .toString();
      }

      if (_deviceIdentifier.trim().isEmpty) {
        _showSnackBar(
          'Impossible d’identifier cet appareil.',
          error: true,
        );
        return;
      }

      // ------------------------------------------------------
      // 2. VÉRIFIER L'ASSOCIATION ACTUELLE
      // ------------------------------------------------------

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

      // ------------------------------------------------------
      // UN AUTRE COMPTE UTILISE ACTUELLEMENT
      // ------------------------------------------------------

      if (associated &&
          enabled &&
          ownerUserId != null &&
          ownerUserId != widget.userId) {
        _showSnackBar(
          'La biométrie de ce téléphone est actuellement '
          'active pour un autre compte. Désactivez-la '
          'd’abord sur cet autre compte.',
          error: true,
        );
        return;
      }

      // ------------------------------------------------------
      // DÉJÀ ACTIVE POUR LE COMPTE COURANT
      // ------------------------------------------------------

      if (enabled &&
          ownerUserId == widget.userId) {
        if (!mounted) return;

        setState(() {
          _biometricAssociated = true;
          _biometricEnabled = true;
          _biometricBelongsToCurrentUser = true;
        });

        return;
      }

      // ------------------------------------------------------
      // 3. VÉRIFIER LA BIOMÉTRIE DU TÉLÉPHONE
      // ------------------------------------------------------

      final isSupported =
          await _localAuth.isDeviceSupported();

      if (!isSupported) {
        _showSnackBar(
          'La biométrie n’est pas disponible sur cet appareil.',
          error: true,
        );
        return;
      }

      final canCheck =
          await _localAuth.canCheckBiometrics;

      if (!canCheck) {
        _showSnackBar(
          'Aucune biométrie n’est configurée sur cet appareil.',
          error: true,
        );
        return;
      }

      final available =
          await _localAuth.getAvailableBiometrics();

      if (available.isEmpty) {
        _showSnackBar(
          'Aucune empreinte ou reconnaissance faciale '
          'n’est enregistrée sur cet appareil.',
          error: true,
        );
        return;
      }

      debugPrint(
        '[BIOMETRIC] Biometries disponibles: $available',
      );

      // ------------------------------------------------------
      // 4. DEMANDER VISAGE / EMPREINTE
      // ------------------------------------------------------

      final authenticated =
          await _localAuth.authenticate(
        localizedReason:
            'Authentifiez-vous pour activer '
            'la connexion biométrique SmartBank.',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (!authenticated) {
        _showSnackBar(
          'Authentification biométrique annulée.',
        );
        return;
      }

      // ------------------------------------------------------
      // 5. ASSOCIATION BACKEND
      // ------------------------------------------------------

      final result =
          await _biometricService.enable(
        userId: widget.userId,
        deviceIdentifier: _deviceIdentifier,
      );

      debugPrint(
        '[BIOMETRIC] Activation backend: $result',
      );

      // ------------------------------------------------------
      // 6. ÉTAT LOCAL
      // ------------------------------------------------------

      if (!mounted) return;

      setState(() {
        _biometricAssociated = true;

        _biometricEnabled = true;

        _biometricBelongsToCurrentUser = true;
      });

      _showSnackBar(
        'Authentification biométrique activée. ✅',
      );
    } on BiometricServiceException catch (e) {
      debugPrint(
        '[BIOMETRIC] Erreur backend activation : $e',
      );

      if (!mounted) return;

      _showSnackBar(
        e.message,
        error: true,
      );
    } catch (e) {
      debugPrint(
        '[BIOMETRIC] Erreur activation : $e',
      );

      if (!mounted) return;

      _showSnackBar(
        'Impossible d’activer la biométrie.',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBiometricLoading = false;
        });
      }
    }
  }

  // =========================================================
  // DÉSACTIVER LA BIOMÉTRIE
  // =========================================================

  Future<void> _disableBiometric() async {
    if (!_isMobilePlatform) {
      return;
    }

    if (_isBiometricLoading) {
      return;
    }

    if (!_biometricBelongsToCurrentUser) {
      _showSnackBar(
        'Seul le compte utilisant actuellement '
        'la biométrie peut la désactiver.',
        error: true,
      );
      return;
    }

    if (_deviceIdentifier.trim().isEmpty) {
      _showSnackBar(
        'Impossible d’identifier cet appareil.',
        error: true,
      );
      return;
    }

    setState(() {
      _isBiometricLoading = true;
    });

    try {
      // ------------------------------------------------------
      // 1. AUTHENTIFICATION DE CONFIRMATION
      // ------------------------------------------------------

      final authenticated =
          await _localAuth.authenticate(
        localizedReason:
            'Authentifiez-vous pour désactiver '
            'la biométrie SmartBank.',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (!authenticated) {
        _showSnackBar(
          'Authentification requise pour désactiver la biométrie.',
        );
        return;
      }

      // ------------------------------------------------------
      // 2. BACKEND
      // ------------------------------------------------------

      final result =
          await _biometricService.disable(
        userId: widget.userId,
        deviceIdentifier: _deviceIdentifier,
      );

      debugPrint(
        '[BIOMETRIC] Désactivation backend: $result',
      );

      // ------------------------------------------------------
      // 3. LE TÉLÉPHONE EST MAINTENANT LIBRE
      // ------------------------------------------------------

      if (!mounted) return;

      setState(() {
        _biometricEnabled = false;

        // La ligne backend peut rester dans l'historique,
        // mais elle n'est plus active.
        _biometricAssociated = true;

        _biometricBelongsToCurrentUser = true;
      });

      _showSnackBar(
        'Biométrie désactivée. '
        'Un autre compte pourra maintenant utiliser '
        'la biométrie de ce téléphone.',
      );
    } on BiometricServiceException catch (e) {
      debugPrint(
        '[BIOMETRIC] Erreur backend désactivation : $e',
      );

      if (!mounted) return;

      _showSnackBar(
        e.message,
        error: true,
      );
    } catch (e) {
      debugPrint(
        '[BIOMETRIC] Erreur désactivation : $e',
      );

      if (!mounted) return;

      _showSnackBar(
        'Impossible de désactiver la biométrie.',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBiometricLoading = false;
        });
      }
    }
  }

  // =========================================================
  // CHARGER APPAREILS
  // =========================================================

  Future<void> _loadConnectedDevices() async {
    if (!mounted) return;

    setState(() {
      _isLoadingDevices = true;
    });

    try {
      final devices =
          await _deviceSessionService.getUserSessions(
        widget.userId,
      );

      if (!mounted) return;

      setState(() {
        _connectedDevices = devices;
        _isLoadingDevices = false;
      });
    } on DeviceSessionException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingDevices = false;
      });

      _showSnackBar(
        e.message,
        error: true,
      );
    } catch (e) {
      debugPrint(
        'Erreur appareils : $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoadingDevices = false;
      });

      _showSnackBar(
        'Impossible de charger les appareils connectés.',
        error: true,
      );
    }
  }

  // =========================================================
  // DÉCONNECTER UN APPAREIL
  // =========================================================

  Future<void> _disconnectDevice(
    DeviceSession device,
  ) async {
    if (_isDisconnectingDevices) {
      return;
    }

    if (device.current) {
      _showSnackBar(
        'Vous ne pouvez pas déconnecter la session actuelle ici.',
      );
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Déconnecter cet appareil ?',
          ),
          content: Text(
            'Voulez-vous vraiment déconnecter '
            '${device.deviceName.isNotEmpty ? device.deviceName : 'cet appareil'} ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Annuler',
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              icon: const Icon(
                Icons.logout,
              ),
              label: const Text(
                'Déconnecter',
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    setState(() {
      _isDisconnectingDevices = true;
    });

    try {
      await _deviceSessionService
          .disconnectSession(
        device.id,
      );

      if (!mounted) return;

      setState(() {
        _connectedDevices.removeWhere(
          (item) => item.id == device.id,
        );
      });

      await _loadConnectedDevices();

      if (!mounted) return;

      _showSnackBar(
        '${device.deviceName.isNotEmpty ? device.deviceName : 'L’appareil'} a été déconnecté.',
      );
    } on DeviceSessionException catch (e) {
      if (!mounted) return;

      _showSnackBar(
        e.message,
        error: true,
      );
    } catch (e) {
      debugPrint(
        'Erreur déconnexion appareil : $e',
      );

      if (!mounted) return;

      _showSnackBar(
        'Impossible de déconnecter cet appareil.',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDisconnectingDevices = false;
        });
      }
    }
  }

  // =========================================================
  // POPUP APPAREILS
  // =========================================================

  Future<void> _showConnectedDevices() async {
    await _loadConnectedDevices();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Appareils connectés',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Actualiser',
                    onPressed:
                        _isLoadingDevices ||
                                _isDisconnectingDevices
                            ? null
                            : () async {
                                await _loadConnectedDevices();

                                if (mounted) {
                                  dialogSetState(() {});
                                }
                              },
                    icon: const Icon(
                      Icons.refresh,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: _isLoadingDevices
                    ? const SizedBox(
                        height: 120,
                        child: Center(
                          child:
                              CircularProgressIndicator(),
                        ),
                      )
                    : _connectedDevices.isEmpty
                        ? const Padding(
                            padding:
                                EdgeInsets.symmetric(
                              vertical: 20,
                            ),
                            child: Text(
                              'Aucun appareil connecté.',
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount:
                                _connectedDevices.length,
                            separatorBuilder:
                                (_, index) =>
                                    const Divider(),
                            itemBuilder:
                                (context, index) {
                              final device =
                                  _connectedDevices[index];

                              final type =
                                  device.deviceType
                                      .toLowerCase();

                              final isMobile =
                                  type.contains(
                                        'smartphone',
                                      ) ||
                                      type.contains(
                                        'mobile',
                                      );

                              return ListTile(
                                contentPadding:
                                    EdgeInsets.zero,
                                leading:
                                    CircleAvatar(
                                  child: Icon(
                                    isMobile
                                        ? Icons
                                            .phone_android
                                        : Icons.computer,
                                  ),
                                ),
                                title: Text(
                                  device.deviceName
                                          .isEmpty
                                      ? 'Appareil'
                                      : device.deviceName,
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                subtitle:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(
                                      height: 3,
                                    ),
                                    Text(
                                      '${device.deviceType}'
                                      '${device.browser.isNotEmpty ? ' • ${device.browser}' : ''}',
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    Text(
                                      device.current
                                          ? 'Session actuelle'
                                          : 'Connecté',
                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        color:
                                            device.current
                                                ? Colors
                                                    .green
                                                : null,
                                      ),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing:
                                    device.current
                                        ? const Icon(
                                            Icons
                                                .check_circle,
                                            color:
                                                Colors.green,
                                          )
                                        : TextButton.icon(
                                            onPressed:
                                                _isDisconnectingDevices
                                                    ? null
                                                    : () async {
                                                        await _disconnectDevice(
                                                          device,
                                                        );

                                                        if (mounted) {
                                                          dialogSetState(
                                                            () {},
                                                          );
                                                        }
                                                      },
                                            icon:
                                                const Icon(
                                              Icons.logout,
                                              size: 18,
                                            ),
                                            label:
                                                const Text(
                                              'Déconnecter',
                                            ),
                                            style:
                                                TextButton
                                                    .styleFrom(
                                              foregroundColor:
                                                  Colors.red,
                                            ),
                                          ),
                              );
                            },
                          ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child:
                      const Text('Fermer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================================================
  // OPTIONS DÉCONNEXION
  // =========================================================

  Future<void> _showDisconnectOptions() async {
    if (_isDisconnectingDevices) {
      return;
    }

    final choice =
        await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Déconnecter les appareils',
          ),
          content: const Text(
            'Choisissez l’action à effectuer.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  'cancel',
                );
              },
              child: const Text(
                'Annuler',
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  'others',
                );
              },
              icon:
                  const Icon(Icons.devices),
              label:
                  const Text('Autres appareils'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  'all',
                );
              },
              icon:
                  const Icon(Icons.logout),
              label:
                  const Text('Tous les appareils'),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (!mounted ||
        choice == null ||
        choice == 'cancel') {
      return;
    }

    if (choice == 'others') {
      await _disconnectOtherDevices();
    } else if (choice == 'all') {
      await _confirmDisconnectAll();
    }
  }

  // =========================================================
  // DÉCONNECTER LES AUTRES
  // =========================================================

  Future<void> _disconnectOtherDevices() async {
    DeviceSession? currentSession;

    for (final device in _connectedDevices) {
      if (device.current && device.active) {
        currentSession = device;
        break;
      }
    }

    if (currentSession == null) {
      await _loadConnectedDevices();

      if (!mounted) return;

      for (final device in _connectedDevices) {
        if (device.current && device.active) {
          currentSession = device;
          break;
        }
      }
    }

    if (currentSession == null) {
      if (!mounted) return;

      _showSnackBar(
        'Session actuelle introuvable.',
        error: true,
      );

      return;
    }

    setState(() {
      _isDisconnectingDevices = true;
    });

    try {
      await _deviceSessionService
          .disconnectOtherSessions(
        widget.userId,
        currentSession.id,
      );

      await _loadConnectedDevices();

      if (!mounted) return;

      _showSnackBar(
        'Les autres appareils ont été déconnectés.',
      );
    } on DeviceSessionException catch (e) {
      if (!mounted) return;

      _showSnackBar(
        e.message,
        error: true,
      );
    } catch (e) {
      debugPrint(
        'Erreur déconnexion autres appareils : $e',
      );

      if (!mounted) return;

      _showSnackBar(
        'Impossible de déconnecter les autres appareils.',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDisconnectingDevices = false;
        });
      }
    }
  }

  // =========================================================
  // DÉCONNECTER TOUS
  // =========================================================

  Future<void> _confirmDisconnectAll() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Déconnecter tous les appareils ?',
          ),
          content: const Text(
            'Cette action va déconnecter tous les appareils, '
            'y compris celui que vous utilisez actuellement. '
            'Vous serez ensuite redirigé vers la page de connexion.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Annuler',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              child: const Text(
                'Déconnecter tout',
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    setState(() {
      _isDisconnectingDevices = true;
    });

    try {
      await _deviceSessionService
          .disconnectAllSessions(
        widget.userId,
      );

      if (!mounted) return;

      Navigator.of(context)
          .pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) =>
              LoginScreen(
            onThemeChanged:
                widget.onThemeChanged ??
                    () {},
          ),
        ),
        (route) => false,
      );
    } on DeviceSessionException catch (e) {
      if (!mounted) return;

      setState(() {
        _isDisconnectingDevices = false;
      });

      _showSnackBar(
        e.message,
        error: true,
      );
    } catch (e) {
      debugPrint(
        'Erreur déconnexion totale : $e',
      );

      if (!mounted) return;

      setState(() {
        _isDisconnectingDevices = false;
      });

      _showSnackBar(
        'Impossible de déconnecter tous les appareils.',
        error: true,
      );
    }
  }

  // =========================================================
  // SNACKBAR
  // =========================================================

  void _showSnackBar(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            error ? Colors.red : null,
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final isPC = !_isMobilePlatform;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sécurité',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed:
                _isBiometricLoading ||
                        _isLoadingDevices ||
                        _isDisconnectingDevices
                    ? null
                    : () async {
                        await _refreshBiometricState();
                        await _loadConnectedDevices();
                      },
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: ListView(
          padding:
              const EdgeInsets.symmetric(
            vertical: 12,
          ),
          children: [

            // =================================================
            // PROTECTION
            // =================================================

            const Padding(
              padding:
                  EdgeInsets.fromLTRB(
                20,
                10,
                20,
                18,
              ),
              child: Text(
                'Protection du compte',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // =================================================
            // MOT DE PASSE
            // =================================================

            ListTile(
              leading: const Icon(
                Icons.lock_reset_outlined,
              ),
              title: const Text(
                'Modifier le mot de passe',
              ),
              subtitle: const Text(
                'Vérification par code envoyé par e-mail',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ForgotPasswordScreen(
                      otpService:
                          OtpService(),
                      initialEmail:
                          widget.userEmail,
                      hideEmailField:
                          true,
                    ),
                  ),
                );
              },
            ),

            const Divider(),

            // =================================================
            // BIOMÉTRIE
            // =================================================

            SwitchListTile(
              secondary:
                  _isBiometricLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.fingerprint,
                        ),

              title: const Text(
                'Authentification biométrique',
              ),

              subtitle: Text(
                isPC
                    ? (_biometricEnabled
                        ? 'Biométrie activée pour ce compte'
                        : 'Biométrie désactivée pour ce compte')
                    : (_biometricEnabled
                        ? 'Biométrie activée sur ce téléphone'
                        : (!_biometricAssociated
                            ? 'Utiliser votre visage ou votre empreinte'
                            : _biometricBelongsToCurrentUser
                                ? 'Biométrie désactivée — téléphone disponible pour un autre compte'
                                : 'Biométrie active pour un autre compte')),
              ),

              value: _biometricEnabled,

              // PC : lecture seulement.
              onChanged:
                  isPC
                      ? null
                      : _isBiometricLoading
                          ? null
                          : _toggleBiometric,
            ),

            if (isPC)
              const Padding(
                padding:
                    EdgeInsets.fromLTRB(
                  72,
                  0,
                  20,
                  12,
                ),
                child: Text(
                  'La gestion de la biométrie se fait uniquement depuis votre téléphone.',
                  style:
                      TextStyle(
                    fontSize: 12,
                  ),
                ),
              ),

            const Divider(),

            // =================================================
            // APPAREILS
            // =================================================

            const Padding(
              padding:
                  EdgeInsets.fromLTRB(
                20,
                18,
                20,
                8,
              ),
              child: Text(
                'Appareils et sessions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            ListTile(
              leading: const Icon(
                Icons.devices_outlined,
              ),
              title: const Text(
                'Appareils connectés',
              ),
              subtitle: Text(
                _isLoadingDevices
                    ? 'Chargement...'
                    : '${_connectedDevices.length} appareil(s) connecté(s)',
              ),
              trailing:
                  const Icon(
                Icons.chevron_right,
              ),
              onTap:
                  _showConnectedDevices,
            ),

            ListTile(
              leading: const Icon(
                Icons.logout,
              ),
              title: const Text(
                'Déconnecter tous les appareils',
              ),
              subtitle: const Text(
                'Gérer les sessions ouvertes sur vos appareils',
              ),
              trailing:
                  _isDisconnectingDevices
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.chevron_right,
                        ),
              enabled:
                  !_isDisconnectingDevices,
              onTap:
                  _isDisconnectingDevices
                      ? null
                      : _showDisconnectOptions,
            ),

            const SizedBox(
              height: 30,
            ),

            // =================================================
            // INFORMATION
            // =================================================

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Container(
                padding:
                    const EdgeInsets.all(16),
                decoration:
                    BoxDecoration(
                  color:
                      Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Icon(
                      Icons.info_outline,
                    ),
                    SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child: Text(
                        'Vous pouvez déconnecter uniquement les autres appareils ou fermer toutes les sessions, y compris celle de cet appareil.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}