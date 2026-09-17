import 'dart:async';

import 'package:flutter/material.dart';

import '../models/user.dart';
import '../screens/home_screen.dart';
import '../screens/accounts_screen.dart';
import '../screens/transfers_screen.dart';
import '../screens/cards_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/login_screen.dart';
import '../services/api_service.dart';
import '../services/device_session_service.dart';

class MainNavigation extends StatefulWidget {
  final User user;
  final VoidCallback onThemeChanged;

  final double initialCourantBalance;
  final double initialEpargneBalance;

  final String courantAccountNumber;
  final String epargneAccountNumber;

  const MainNavigation({
    super.key,
    required this.user,
    required this.onThemeChanged,
    this.initialCourantBalance = 0.0,
    this.initialEpargneBalance = 0.0,
    this.courantAccountNumber = '',
    this.epargneAccountNumber = '',
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  // =========================================================
  // API
  // =========================================================

  final ApiService _apiService = ApiService();

  // =========================================================
  // CONFIGURATION
  // =========================================================

  static const Duration notificationInterval =
      Duration(seconds: 2);

  static const Duration bannerDuration =
      Duration(seconds: 8);

  static const int bannerTotalSeconds = 8;

  // =========================================================
  // COULEURS SMARTBANK
  // =========================================================

  // -----------------------------
  // VIREMENT EXTERNE
  // -----------------------------

  static const Color primaryBlue =
      Color(0xFF0B5AA6);

  static const Color darkBlue =
      Color(0xFF06457E);

  // -----------------------------
  // COURANT → ÉPARGNE
  // VERT FONCÉ
  // -----------------------------

  static const Color currentToSavingsGreen =
      Color(0xFF087A5B);

  static const Color currentToSavingsDarkGreen =
      Color(0xFF055B45);

  // -----------------------------
  // ÉPARGNE → COURANT
  // VERT CLAIR
  // -----------------------------

  static const Color savingsToCurrentGreen =
      Color(0xFF32B67A);

  static const Color savingsToCurrentDarkGreen =
      Color(0xFF20915F);

  // =========================================================
  // NAVIGATION
  // =========================================================

  int _currentIndex = 0;

  // =========================================================
  // SOLDES
  // =========================================================

  late double _courantBalance;
  late double _epargneBalance;

  final List<TransferRecord> _transferHistory = [];

  // =========================================================
  // TRANSFERTS
  // =========================================================

  final GlobalKey<TransfersScreenState>
      _transfersScreenKey =
      GlobalKey<TransfersScreenState>();

  // =========================================================
  // SESSION
  // =========================================================

  StreamSubscription<void>?
      _sessionInvalidationSubscription;

  // =========================================================
  // NOTIFICATIONS
  // =========================================================

  Timer? _notificationTimer;
  Timer? _notificationBannerTimer;
  Timer? _notificationCountdownTimer;

  bool _notificationRequestRunning = false;

  int? _lastDisplayedNotificationId;

  Map<String, dynamic>?
      _visibleNotification;

  int _bannerRemainingSeconds =
      bannerTotalSeconds;

  // =========================================================
  // ANIMATION
  // =========================================================

  late final AnimationController
      _notificationAnimationController;

  late final Animation<Offset>
      _notificationSlideAnimation;

  late final Animation<double>
      _notificationFadeAnimation;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _courantBalance =
        widget.initialCourantBalance;

    _epargneBalance =
        widget.initialEpargneBalance;

    // ---------------------------------------------------------
    // Animation
    // ---------------------------------------------------------

    _notificationAnimationController =
        AnimationController(
      vsync: this,
      duration:
          const Duration(
        milliseconds: 420,
      ),
      reverseDuration:
          const Duration(
        milliseconds: 280,
      ),
    );

    _notificationSlideAnimation =
        Tween<Offset>(
      begin:
          const Offset(
        0,
        -1.25,
      ),
      end:
          Offset.zero,
    ).animate(
      CurvedAnimation(
        parent:
            _notificationAnimationController,
        curve:
            Curves.easeOutCubic,
        reverseCurve:
            Curves.easeInCubic,
      ),
    );

    _notificationFadeAnimation =
        CurvedAnimation(
      parent:
          _notificationAnimationController,
      curve:
          Curves.easeOut,
      reverseCurve:
          Curves.easeIn,
    );

    // ---------------------------------------------------------
    // Session
    // ---------------------------------------------------------

    _sessionInvalidationSubscription =
        DeviceSessionService
            .sessionInvalidatedStream
            .listen((_) {
      _handleSessionInvalidation();
    });

    // ---------------------------------------------------------
    // Notifications
    // ---------------------------------------------------------

    _initializeNotifications();
  }

  // =========================================================
  // INITIALISATION NOTIFICATIONS
  // =========================================================

  Future<void>
      _initializeNotifications() async {
    try {
      await _loadLatestTransferNotification(
        initializeOnly: true,
      );
    } catch (e) {
      debugPrint(
        '[NOTIFICATIONS] Erreur initialisation: $e',
      );
    }

    if (!mounted) return;

    _startNotificationWatcher();
  }

  // =========================================================
  // WATCHER
  // =========================================================

  void _startNotificationWatcher() {
    _notificationTimer?.cancel();

    _notificationTimer =
        Timer.periodic(
      notificationInterval,
      (_) {
        _checkNotifications();
      },
    );

    debugPrint(
      '[NOTIFICATIONS] ✅ Watcher démarré.',
    );
  }

  Future<void> _checkNotifications() async {
    if (!mounted ||
        _notificationRequestRunning) {
      return;
    }

    _notificationRequestRunning = true;

    try {
      await _loadLatestTransferNotification();
    } catch (e) {
      debugPrint(
        '[NOTIFICATIONS] Erreur watcher: $e',
      );
    } finally {
      _notificationRequestRunning = false;
    }
  }

  // =========================================================
  // CHARGER LE DERNIER VIREMENT
  // =========================================================

  Future<void> _loadLatestTransferNotification({
    bool initializeOnly = false,
  }) async {
    final response = await _apiService.get(
      '/api/notifications/user/${widget.user.id}',
    );

    debugPrint(
      '[NOTIFICATIONS] HTTP ${response.statusCode}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur HTTP ${response.statusCode}',
      );
    }

    final decoded =
        _apiService.decodeResponse(response);

    if (decoded is! List ||
        decoded.isEmpty) {
      return;
    }

    final notifications =
        <Map<String, dynamic>>[];

    for (final item in decoded) {
      if (item is Map) {
        notifications.add(
          Map<String, dynamic>.from(
            item,
          ),
        );
      }
    }

    if (notifications.isEmpty) {
      return;
    }

    // =======================================================
    // TRI PAR DATE DESCENDANTE
    // =======================================================

    notifications.sort(
      (a, b) {
        final aDate =
            DateTime.tryParse(
                  (a['createdAt'] ?? '')
                      .toString(),
                ) ??
                DateTime.fromMillisecondsSinceEpoch(
                  0,
                );

        final bDate =
            DateTime.tryParse(
                  (b['createdAt'] ?? '')
                      .toString(),
                ) ??
                DateTime.fromMillisecondsSinceEpoch(
                  0,
                );

        return bDate.compareTo(
          aDate,
        );
      },
    );

    // =======================================================
    // CHERCHER LE DERNIER VIREMENT À AFFICHER
    //
    // On accepte :
    //
    // 1. TRANSFER_IN
    // 2. TRANSFER + "Virement reçu"
    // 3. TRANSFER + transfert interne
    //
    // On ignore :
    //
    // 1. TRANSFER_OUT
    // 2. TRANSFER + "Virement envoyé"
    //
    // Cela permet de gérer les anciennes notifications qui
    // utilisent encore type = TRANSFER.
    // =======================================================

    Map<String, dynamic>?
        latestTransfer;

    for (final notification
        in notifications) {
      final type =
          (notification['type'] ?? '')
              .toString()
              .trim()
              .toUpperCase();

      // =====================================================
      // TRANSFERT SORTANT MODERNE
      // =====================================================

      if (type == 'TRANSFER_OUT') {
        continue;
      }

      // =====================================================
      // TRANSFERT ENTRANT MODERNE
      // =====================================================

      if (type == 'TRANSFER_IN') {
        latestTransfer =
            notification;
        break;
      }

      // =====================================================
      // ANCIEN FORMAT TRANSFER
      // =====================================================

      if (type == 'TRANSFER') {
        // -----------------------------------------------
        // Virement reçu
        // -----------------------------------------------

        if (_isIncomingTransfer(
          notification,
        )) {
          latestTransfer =
              notification;
          break;
        }

        // -----------------------------------------------
        // Transfert entre ses propres comptes
        // -----------------------------------------------

        if (_isInternalTransfer(
          notification,
        )) {
          latestTransfer =
              notification;
          break;
        }

        // -----------------------------------------------
        // Virement envoyé
        // -----------------------------------------------

        if (_isOutgoingTransfer(
          notification,
        )) {
          continue;
        }
      }
    }

    if (latestTransfer ==
        null) {
      return;
    }

    // =======================================================
    // ID
    // =======================================================

    final notificationId =
        int.tryParse(
      (latestTransfer['id'] ?? '')
          .toString(),
    );

    if (notificationId ==
        null) {
      debugPrint(
        '[NOTIFICATIONS] ⚠️ Notification sans ID valide.',
      );

      return;
    }

    final originalType =
        (latestTransfer['type'] ?? '')
            .toString()
            .trim()
            .toUpperCase();

    final isUnread =
        latestTransfer['read'] !=
            true;

    debugPrint(
      '[NOTIFICATIONS] '
      'Dernier transfert détecté : '
      'id=$notificationId '
      'type=$originalType '
      'title=${latestTransfer['title']} '
      'read=${latestTransfer['read']} '
      'amount=${latestTransfer['amount']}',
    );

    // =======================================================
    // PREMIER CHARGEMENT
    //
    // On mémorise la dernière notification existante
    // pour éviter d'afficher une ancienne notification.
    //
    // Si elle est encore non lue, elle peut être affichée.
    // =======================================================

    if (initializeOnly) {
      _lastDisplayedNotificationId =
          notificationId;

      debugPrint(
        '[NOTIFICATIONS] '
        'Initialisation : '
        'id=$notificationId '
        'unread=$isUnread',
      );

      final allowed =
          await _isNotificationAllowed(
        originalType,
      );

      if (!mounted) return;

      if (allowed &&
          isUnread) {
        _showNotificationBanner(
          latestTransfer,
        );
      }

      return;
    }

    // =======================================================
    // NOTIFICATION DÉJÀ AFFICHÉE
    // =======================================================

    if (_lastDisplayedNotificationId ==
        notificationId) {
      return;
    }

    // =======================================================
    // NOUVELLE NOTIFICATION
    //
    // IMPORTANT :
    // On ne vérifie PAS read == false ici.
    //
    // L'ID permet de détecter une nouvelle notification même
    // si elle a déjà été marquée comme lue.
    // =======================================================

    debugPrint(
      '[NOTIFICATIONS] '
      '🆕 Nouvelle notification détectée : '
      'id=$notificationId '
      'type=$originalType '
      'title=${latestTransfer['title']} '
      'read=${latestTransfer['read']} '
      'amount=${latestTransfer['amount']}',
    );

    _lastDisplayedNotificationId =
        notificationId;

    final allowed =
        await _isNotificationAllowed(
      originalType,
    );

    if (!allowed ||
        !mounted) {
      debugPrint(
        '[NOTIFICATIONS] '
        '🚫 Notification bloquée par les préférences.',
      );

      return;
    }

    _showNotificationBanner(
      latestTransfer,
    );
  }

  // =========================================================
  // DÉTECTER VIREMENT ENTRANT
  //
  // Compatible avec :
  //
  // TRANSFER_IN
  //
  // et ancien format :
  //
  // TRANSFER + Virement reçu
  // =========================================================

  bool _isIncomingTransfer(
    Map<String, dynamic>
        notification,
  ) {
    final type =
        (notification['type'] ?? '')
            .toString()
            .trim()
            .toUpperCase();

    if (type == 'TRANSFER_IN') {
      return true;
    }

    if (type != 'TRANSFER') {
      return false;
    }

    if (_isInternalTransfer(
      notification,
    )) {
      return false;
    }

    final title =
        (notification['title'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

    final message =
        (notification['message'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

    if (title.contains(
          'virement reçu',
        ) ||
        title.contains(
          'transfert reçu',
        )) {
      return true;
    }

    if (message.contains(
          'vous avez reçu',
        ) &&
        message.contains(
          'tnd',
        )) {
      return true;
    }

    return false;
  }

  // =========================================================
  // DÉTECTER VIREMENT SORTANT
  //
  // Compatible avec :
  //
  // TRANSFER_OUT
  //
  // et ancien format :
  //
  // TRANSFER + Virement envoyé
  // =========================================================

  bool _isOutgoingTransfer(
    Map<String, dynamic>
        notification,
  ) {
    final type =
        (notification['type'] ?? '')
            .toString()
            .trim()
            .toUpperCase();

    if (type == 'TRANSFER_OUT') {
      return true;
    }

    if (type != 'TRANSFER') {
      return false;
    }

    if (_isInternalTransfer(
      notification,
    )) {
      return false;
    }

    final title =
        (notification['title'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

    final message =
        (notification['message'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

    if (title.contains(
          'virement envoyé',
        ) ||
        title.contains(
          'transfert envoyé',
        )) {
      return true;
    }

    if (message.contains(
          'vous avez envoyé',
        ) &&
        message.contains(
          'tnd',
        )) {
      return true;
    }

    return false;
  }

  // =========================================================
  // PRÉFÉRENCES
  // =========================================================

  Future<bool> _isNotificationAllowed(
    String type,
  ) async {
    try {
      final response =
          await _apiService.get(
        '/api/notification-preferences/${widget.user.id}',
      );

      if (response.statusCode !=
          200) {
        return true;
      }

      final decoded =
          _apiService.decodeResponse(
        response,
      );

      if (decoded is! Map) {
        return true;
      }

      final preferences =
          Map<String, dynamic>.from(
        decoded,
      );

      // =====================================================
      // GÉNÉRAL
      // =====================================================

      final general =
          preferences[
                  'generalNotifications'] ==
              true;

      if (!general) {
        return false;
      }

      // =====================================================
      // TYPE
      // =====================================================

      final normalized =
          _normalizeNotificationType(
        type,
      );

      switch (normalized) {
        case 'TRANSFER':
          return preferences[
                  'transfers'] ==
              true;

        case 'PAYMENT':
          return preferences[
                  'cardPayments'] ==
              true;

        case 'WITHDRAWAL':
          return preferences[
                  'withdrawals'] ==
              true;

        case 'SECURITY':
          return preferences[
                  'securityAlerts'] ==
              true;

        case 'PROMOTION':
          return preferences[
                  'promotions'] ==
              true;

        default:
          return true;
      }
    } catch (e) {
      debugPrint(
        '[NOTIFICATIONS] '
        'Erreur préférences: $e',
      );

      return true;
    }
  }

  // =========================================================
  // NORMALISATION
  // =========================================================

  String _normalizeNotificationType(
    String type,
  ) {
    switch (
        type.trim().toUpperCase()) {
      case 'TRANSFER':
      case 'TRANSFER_IN':
      case 'TRANSFER_OUT':
        return 'TRANSFER';

      case 'PAYMENT':
      case 'CARD_PAYMENT':
      case 'CARD':
        return 'PAYMENT';

      case 'WITHDRAWAL':
      case 'ATM_WITHDRAWAL':
        return 'WITHDRAWAL';

      case 'SECURITY':
      case 'SECURITY_ALERT':
        return 'SECURITY';

      case 'PROMOTION':
      case 'PROMOTIONS':
        return 'PROMOTION';

      default:
        return type
            .trim()
            .toUpperCase();
    }
  }

  // =========================================================
  // DÉTECTER TRANSFERT INTERNE
  // =========================================================

  bool _isInternalTransfer(
    Map<String, dynamic>
        notification,
  ) {
    final title =
        (notification['title'] ?? '')
            .toString()
            .toLowerCase();

    final sourceType =
        (notification[
                    'sourceAccountType'] ??
                '')
            .toString()
            .trim()
            .toUpperCase();

    final destinationType =
        (notification[
                    'destinationAccountType'] ??
                '')
            .toString()
            .trim()
            .toUpperCase();

    return title.contains(
          'entre vos comptes',
        ) ||
        (sourceType ==
                'CURRENT' &&
            destinationType ==
                'SAVINGS') ||
        (sourceType ==
                'SAVINGS' &&
            destinationType ==
                'CURRENT');
  }

  // =========================================================
  // LABEL TYPE COMPTE
  // =========================================================

  String _accountTypeLabel(
    dynamic type,
  ) {
    switch (
        (type ?? '')
            .toString()
            .trim()
            .toUpperCase()) {
      case 'CURRENT':
        return 'compte courant';

      case 'SAVINGS':
        return 'compte épargne';

      default:
        return 'compte';
    }
  }

  // =========================================================
  // FORMAT MONTANT
  // =========================================================

  String _formatAmount(
    dynamic value,
  ) {
    double amount = 0.0;

    if (value is num) {
      amount =
          value.toDouble();
    } else {
      amount =
          double.tryParse(
                value?.toString() ?? '',
              ) ??
              0.0;
    }

    return '${amount.toStringAsFixed(2)} DT';
  }

  // =========================================================
  // MASQUER NUMÉRO COMPTE
  // =========================================================

  String _maskAccountNumber(
    dynamic accountNumber,
  ) {
    if (accountNumber ==
        null) {
      return '';
    }

    final clean =
        accountNumber
            .toString()
            .trim();

    if (clean.isEmpty) {
      return '';
    }

    if (clean.contains('••••')) {
      return clean;
    }

    if (clean.length <= 4) {
      return clean;
    }

    return '•••• ${clean.substring(clean.length - 4)}';
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  String _buildBannerMessage(
    Map<String, dynamic>
        notification,
  ) {
    final internal =
        _isInternalTransfer(
      notification,
    );

    // =======================================================
    // TRANSFERT INTERNE
    // =======================================================

    if (internal) {
      final destinationType =
          _accountTypeLabel(
        notification[
            'destinationAccountType'],
      );

      final amount =
          _formatAmount(
        notification['amount'],
      );

      return 'Vous effectuez un virement de '
          '$amount vers votre $destinationType.';
    }

    // =======================================================
    // TRANSFERT EXTERNE
    // =======================================================

    final senderName =
        (notification['senderName'] ?? '')
            .toString()
            .trim();

    final senderAccount =
        _maskAccountNumber(
      notification[
          'senderAccountNumber'],
    );

    final amount =
        _formatAmount(
      notification['amount'],
    );

    final notificationType =
        (notification['type'] ?? '')
            .toString()
            .trim()
            .toUpperCase();

    final isIncoming =
        _isIncomingTransfer(
      notification,
    );

    final isOutgoing =
        _isOutgoingTransfer(
      notification,
    );

    // =======================================================
    // TRANSFERT SORTANT
    // =======================================================

    if (isOutgoing) {
      final recipientAccount =
          (notification[
                      'recipientAccountNumber'] ??
                  notification[
                      'destinationAccountNumber'] ??
                  notification[
                      'relatedAccountNumber'] ??
                  '')
              .toString()
              .trim();

      if (recipientAccount
          .isNotEmpty) {
        return 'Virement envoyé vers '
            '$recipientAccount • $amount';
      }

      final outgoingMessage =
          (notification['message'] ?? '')
              .toString()
              .trim();

      return outgoingMessage.isNotEmpty
          ? outgoingMessage
          : 'Montant envoyé : $amount';
    }

    // =======================================================
    // TRANSFERT ENTRANT
    // =======================================================

    if (isIncoming) {
      if (senderName.isNotEmpty &&
          senderAccount.isNotEmpty) {
        return 'Virement reçu de '
            '$senderName • $senderAccount • $amount';
      }

      if (senderName.isNotEmpty) {
        return 'Virement reçu de '
            '$senderName • $amount';
      }

      if (senderAccount.isNotEmpty) {
        return 'Virement reçu • '
            '$senderAccount • $amount';
      }

      final incomingMessage =
          (notification['message'] ?? '')
              .toString()
              .trim();

      return incomingMessage.isNotEmpty
          ? incomingMessage
          : 'Montant reçu : $amount';
    }

    // =======================================================
    // COMPATIBILITÉ
    // =======================================================

    final message =
        (notification['message'] ?? '')
            .toString()
            .trim();

    return message.isNotEmpty
        ? message
        : 'Virement effectué.';
  }

  // =========================================================
  // COULEUR PRINCIPALE DU BANDEAU
  // =========================================================

  Color _getBannerPrimaryColor(
    Map<String, dynamic>
        notification,
  ) {
    final internal =
        _isInternalTransfer(
      notification,
    );

    // ---------------------------------------------
    // VIREMENT EXTERNE
    // ---------------------------------------------

    if (!internal) {
      return primaryBlue;
    }

    final sourceType =
        (notification[
                    'sourceAccountType'] ??
                '')
            .toString()
            .trim()
            .toUpperCase();

    final destinationType =
        (notification[
                    'destinationAccountType'] ??
                '')
            .toString()
            .trim()
            .toUpperCase();

    // ---------------------------------------------
    // COURANT → ÉPARGNE
    // ---------------------------------------------

    if (sourceType ==
            'CURRENT' &&
        destinationType ==
            'SAVINGS') {
      return currentToSavingsGreen;
    }

    // ---------------------------------------------
    // ÉPARGNE → COURANT
    // ---------------------------------------------

    if (sourceType ==
            'SAVINGS' &&
        destinationType ==
            'CURRENT') {
      return savingsToCurrentGreen;
    }

    return currentToSavingsGreen;
  }

  // =========================================================
  // COULEUR SOMBRE DU BANDEAU
  // =========================================================

  Color _getBannerDarkColor(
    Map<String, dynamic>
        notification,
  ) {
    final internal =
        _isInternalTransfer(
      notification,
    );

    // ---------------------------------------------
    // VIREMENT EXTERNE
    // ---------------------------------------------

    if (!internal) {
      return darkBlue;
    }

    final sourceType =
        (notification[
                    'sourceAccountType'] ??
                '')
            .toString()
            .trim()
            .toUpperCase();

    final destinationType =
        (notification[
                    'destinationAccountType'] ??
                '')
            .toString()
            .trim()
            .toUpperCase();

    // ---------------------------------------------
    // COURANT → ÉPARGNE
    // ---------------------------------------------

    if (sourceType ==
            'CURRENT' &&
        destinationType ==
            'SAVINGS') {
      return currentToSavingsDarkGreen;
    }

    // ---------------------------------------------
    // ÉPARGNE → COURANT
    // ---------------------------------------------

    if (sourceType ==
            'SAVINGS' &&
        destinationType ==
            'CURRENT') {
      return savingsToCurrentDarkGreen;
    }

    return currentToSavingsDarkGreen;
  }

  // =========================================================
  // AFFICHER BANDEAU
  // =========================================================

  void _showNotificationBanner(
    Map<String, dynamic>
        notification,
  ) {
    if (!mounted) return;

    // =======================================================
    // PROTECTION ABSOLUE
    // =======================================================

    final notificationType =
        (notification['type'] ?? '')
            .toString()
            .trim()
            .toUpperCase();

    final internal =
        _isInternalTransfer(
      notification,
    );

    final incoming =
        _isIncomingTransfer(
      notification,
    );

    final outgoing =
        _isOutgoingTransfer(
      notification,
    );

    // =======================================================
    // TRANSFERT SORTANT
    // =======================================================

    if (outgoing) {
      debugPrint(
        '[NOTIFICATIONS] 🚫 Bandeau ignoré : '
        'virement sortant '
        'type=$notificationType',
      );

      return;
    }

    // =======================================================
    // AUTORISER UNIQUEMENT :
    //
    // - TRANSFER_IN
    // - ancien TRANSFER reçu
    // - transfert interne
    // =======================================================

    if (!incoming &&
        !internal) {
      debugPrint(
        '[NOTIFICATIONS] 🚫 Bandeau ignoré : '
        'type=$notificationType '
        'title=${notification['title']}',
      );

      return;
    }

    final id =
        int.tryParse(
      (notification['id'] ?? '')
          .toString(),
    );

    if (id != null) {
      _lastDisplayedNotificationId =
          id;
    }

    _notificationBannerTimer
        ?.cancel();

    _notificationCountdownTimer
        ?.cancel();

    _bannerRemainingSeconds =
        bannerTotalSeconds;

    _notificationAnimationController
        .reset();

    setState(() {
      _visibleNotification =
          Map<String, dynamic>.from(
        notification,
      );
    });

    _notificationAnimationController
        .forward();

    // =======================================================
    // COMPTEUR 8 → 0
    // =======================================================

    _notificationCountdownTimer =
        Timer.periodic(
      const Duration(
        seconds: 1,
      ),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_bannerRemainingSeconds <=
            1) {
          timer.cancel();

          if (mounted) {
            setState(() {
              _bannerRemainingSeconds =
                  0;
            });
          }

          return;
        }

        setState(() {
          _bannerRemainingSeconds--;
        });
      },
    );

    // =======================================================
    // DISPARITION APRÈS 8 SECONDES
    // =======================================================

    _notificationBannerTimer =
        Timer(
      bannerDuration,
      () async {
        if (!mounted) {
          return;
        }

        await _notificationAnimationController
            .reverse();

        if (!mounted) {
          return;
        }

        _notificationCountdownTimer
            ?.cancel();

        setState(() {
          _visibleNotification =
              null;

          _bannerRemainingSeconds =
              0;
        });
      },
    );

    debugPrint(
      '[NOTIFICATIONS] ✅ Bandeau affiché '
      'id=$id '
      'type=$notificationType '
      'incoming=$incoming '
      'internal=$internal '
      'amount=${notification['amount']}',
    );
  }

  // =========================================================
  // CACHER BANDEAU
  // =========================================================

  Future<void>
      _hideNotificationBanner() async {
    _notificationBannerTimer
        ?.cancel();

    _notificationCountdownTimer
        ?.cancel();

    if (!mounted) return;

    await _notificationAnimationController
        .reverse();

    if (!mounted) return;

    setState(() {
      _visibleNotification =
          null;

      _bannerRemainingSeconds =
          0;
    });
  }

  // =========================================================
  // SESSION
  // =========================================================

  void _handleSessionInvalidation() {
    if (!mounted) return;

    DeviceSessionService()
        .stopHeartbeat();

    Navigator.of(context)
        .pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            LoginScreen(
          onThemeChanged:
              widget.onThemeChanged,
        ),
      ),
      (route) => false,
    );
  }

  // =========================================================
  // SOLDE COURANT
  // =========================================================

  void _updateCourantBalance(
    double newBalance,
  ) {
    if (!mounted) return;

    setState(() {
      _courantBalance =
          newBalance;
    });
  }

  // =========================================================
  // SOLDE ÉPARGNE
  // =========================================================

  void _updateEpargneBalance(
    double newBalance,
  ) {
    if (!mounted) return;

    setState(() {
      _epargneBalance =
          newBalance;
    });
  }

  // =========================================================
  // APRÈS VIREMENT
  // =========================================================

  void _updateBalances(
    double newCourant,
    double newEpargne,
    TransferRecord newRecord,
  ) {
    if (!mounted) return;

    setState(() {
      _courantBalance =
          newCourant;

      _epargneBalance =
          newEpargne;

      _transferHistory.insert(
        0,
        newRecord,
      );
    });

    _checkNotifications();
  }

  // =========================================================
  // OUVRIR VIREMENTS
  // =========================================================

  Future<void> _openTransfersTab() async {
    if (!mounted) return;

    setState(() {
      _currentIndex = 2;
    });

    await Future.delayed(
      const Duration(
        milliseconds: 50,
      ),
    );

    if (!mounted) return;

    await _transfersScreenKey
        .currentState
        ?.refreshFromParent();
  }

  // =========================================================
  // NAVIGATION
  // =========================================================

  void _navigateToTab(
    int index,
  ) {
    if (index < 0 ||
        index >= 5) {
      return;
    }

    if (index == 2) {
      _openTransfersTab();
      return;
    }

    setState(() {
      _currentIndex =
          index;
    });
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final screens =
        <Widget>[
      // =====================================================
      // ACCUEIL
      // =====================================================

      HomeScreen(
        userId:
            widget.user.id,
        firstName:
            widget.user.firstName,
        balance:
            _courantBalance,
        epargneBalance:
            _epargneBalance,
        onBalanceChanged:
            _updateCourantBalance,
        onEpargneBalanceChanged:
            _updateEpargneBalance,
        onNavigateTab:
            _navigateToTab,
      ),

      // =====================================================
      // COMPTES
      // =====================================================

      AccountsScreen(
        userId:
            widget.user.id,
        courantBalance:
            _courantBalance,
        epargneBalance:
            _epargneBalance,
        onCourantBalanceChanged:
            _updateCourantBalance,
        onEpargneBalanceChanged:
            _updateEpargneBalance,
      ),

      // =====================================================
      // VIREMENTS
      // =====================================================

      TransfersScreen(
        key:
            _transfersScreenKey,
        userId:
            widget.user.id,
        courantBalance:
            _courantBalance,
        epargneBalance:
            _epargneBalance,
        transferHistory:
            _transferHistory,
        onBalancesUpdated:
            _updateBalances,
      ),

      // =====================================================
      // CARTES
      // =====================================================

      CardsScreen(
        userId: widget.user.id,
        firstName: widget.user.firstName,
        courantBalance: _courantBalance,
        onCourantBalanceChanged:
            _updateCourantBalance,
      ),

      // =====================================================
      // PROFIL
      // =====================================================

      ProfileScreen(
        user:
            widget.user,
        onThemeChanged:
            widget.onThemeChanged,
      ),
    ];

    return Stack(
      clipBehavior:
          Clip.none,
      children: [
        // =====================================================
        // APPLICATION PRINCIPALE
        // =====================================================

        Scaffold(
          body:
              IndexedStack(
            index:
                _currentIndex,
            children:
                screens,
          ),

          // ===================================================
          // NAVIGATION BAS
          // ===================================================

          bottomNavigationBar:
              BottomNavigationBar(
            currentIndex:
                _currentIndex,

            onTap:
                (index) {
              if (index ==
                  2) {
                _openTransfersTab();
                return;
              }

              setState(() {
                _currentIndex =
                    index;
              });
            },

            type:
                BottomNavigationBarType
                    .fixed,

            items: const [
              BottomNavigationBarItem(
                icon:
                    Icon(
                  Icons
                      .home_outlined,
                ),
                activeIcon:
                    Icon(
                  Icons.home,
                ),
                label:
                    'Accueil',
              ),

              BottomNavigationBarItem(
                icon:
                    Icon(
                  Icons
                      .account_balance_wallet_outlined,
                ),
                activeIcon:
                    Icon(
                  Icons
                      .account_balance_wallet,
                ),
                label:
                    'Comptes',
              ),

              BottomNavigationBarItem(
                icon:
                    Icon(
                  Icons
                      .swap_horiz_outlined,
                ),
                activeIcon:
                    Icon(
                  Icons.swap_horiz,
                ),
                label:
                    'Virements',
              ),

              BottomNavigationBarItem(
                icon:
                    Icon(
                  Icons
                      .credit_card_outlined,
                ),
                activeIcon:
                    Icon(
                  Icons.credit_card,
                ),
                label:
                    'Cartes',
              ),

              BottomNavigationBarItem(
                icon:
                    Icon(
                  Icons
                      .person_outline,
                ),
                activeIcon:
                    Icon(
                  Icons.person,
                ),
                label:
                    'Profil',
              ),
            ],
          ),
        ),

        // =====================================================
        // UNE SEULE FENÊTRE DE NOTIFICATION
        // =====================================================

        if (_visibleNotification !=
            null)
          SafeArea(
            child:
                Align(
              alignment:
                  Alignment.topCenter,
              child:
                  Padding(
                padding:
                    const EdgeInsets.only(
                  top:
                      10,
                  left:
                      12,
                  right:
                      12,
                ),
                child:
                    SlideTransition(
                  position:
                      _notificationSlideAnimation,
                  child:
                      FadeTransition(
                    opacity:
                        _notificationFadeAnimation,
                    child:
                        _buildNotificationBanner(),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // =========================================================
  // DESIGN DU BANDEAU
  // =========================================================

  Widget _buildNotificationBanner() {
    final notification =
        _visibleNotification;

    if (notification ==
        null) {
      return const SizedBox
          .shrink();
    }

    // =======================================================
    // PROTECTION SUPPLÉMENTAIRE
    // =======================================================

    final notificationType =
        (notification['type'] ?? '')
            .toString()
            .trim()
            .toUpperCase();

    final internal =
        _isInternalTransfer(
      notification,
    );

    final incoming =
        _isIncomingTransfer(
      notification,
    );

    final outgoing =
        _isOutgoingTransfer(
      notification,
    );

    // =======================================================
    // SORTANT : JAMAIS DE BANDEAU
    // =======================================================

    if (outgoing) {
      return const SizedBox
          .shrink();
    }

    // =======================================================
    // SEULS LES ENTRANTS ET INTERNES SONT AUTORISÉS
    // =======================================================

    if (!incoming &&
        !internal) {
      return const SizedBox
          .shrink();
    }

    // =======================================================
    // DÉTECTION
    // =======================================================

    final isIncoming =
        incoming;

    final isOutgoing =
        outgoing;

    // =======================================================
    // TITRE
    // =======================================================

    final title =
        (notification['title'] ??
                (internal
                    ? 'Transfert entre vos comptes'
                    : isIncoming
                        ? 'Virement reçu'
                        : isOutgoing
                            ? 'Virement envoyé'
                            : 'Virement'))
            .toString();

    // =======================================================
    // MESSAGE
    // =======================================================

    final message =
        _buildBannerMessage(
      notification,
    );

    // =======================================================
    // DONNÉES
    // =======================================================

    final amount =
        _formatAmount(
      notification['amount'],
    );

    final senderName =
        (notification['senderName'] ?? '')
            .toString()
            .trim();

    final senderAccount =
        _maskAccountNumber(
      notification[
          'senderAccountNumber'],
    );

    final sourceType =
        _accountTypeLabel(
      notification[
          'sourceAccountType'],
    );

    final destinationType =
        _accountTypeLabel(
      notification[
          'destinationAccountType'],
    );

    // =======================================================
    // COULEURS
    // =======================================================

    final bannerPrimary =
        _getBannerPrimaryColor(
      notification,
    );

    final bannerDark =
        _getBannerDarkColor(
      notification,
    );

    // =======================================================
    // ICÔNE
    // =======================================================

    final IconData bannerIcon =
        internal
            ? Icons
                .swap_vertical_circle_outlined
            : Icons
                .account_balance_wallet_outlined;

    return Material(
      color:
          Colors.transparent,

      child:
          Container(
        width:
            double.infinity,

        constraints:
            const BoxConstraints(
          maxWidth:
              520,
        ),

        decoration:
            BoxDecoration(
          gradient:
              LinearGradient(
            begin:
                Alignment.topLeft,
            end:
                Alignment.bottomRight,
            colors: [
              bannerPrimary,
              bannerDark,
            ],
          ),

          borderRadius:
              BorderRadius.circular(
            20,
          ),

          border:
              Border.all(
            color:
                Colors.white.withValues(
              alpha:
                  0.20,
            ),
          ),

          boxShadow: [
            BoxShadow(
              color:
                  bannerPrimary.withValues(
                alpha:
                    0.30,
              ),
              blurRadius:
                  28,
              offset:
                  const Offset(
                0,
                10,
              ),
            ),

            const BoxShadow(
              color:
                  Colors.black26,
              blurRadius:
                  8,
              offset:
                  Offset(
                0,
                2,
              ),
            ),
          ],
        ),

        child:
            ClipRRect(
          borderRadius:
              BorderRadius.circular(
            20,
          ),

          child:
              Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              // =================================================
              // CONTENU
              // =================================================

              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  14,
                  13,
                  10,
                  12,
                ),

                child:
                    Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    // ==========================================
                    // ICÔNE
                    // ==========================================

                    Container(
                      width:
                          50,
                      height:
                          50,
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white,
                        shape:
                            BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withValues(
                              alpha:
                                  0.14,
                            ),
                            blurRadius:
                                12,
                          ),
                        ],
                      ),
                      child:
                          Icon(
                        bannerIcon,
                        color:
                            bannerPrimary,
                        size:
                            27,
                      ),
                    ),

                    const SizedBox(
                      width:
                          12,
                    ),

                    // ==========================================
                    // TEXTE
                    // ==========================================

                    Expanded(
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          // ==================================
                          // TITRE + TIMER
                          // ==================================

                          Row(
                            children: [
                              Expanded(
                                child:
                                    Text(
                                  title,
                                  maxLines:
                                      1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.white,
                                    fontSize:
                                        15.5,
                                    fontWeight:
                                        FontWeight.w800,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                width:
                                    5,
                              ),

                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal:
                                      7,
                                  vertical:
                                      3,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color:
                                      Colors.white.withValues(
                                    alpha:
                                        0.16,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                    20,
                                  ),
                                ),
                                child:
                                    Text(
                                  '$_bannerRemainingSeconds s',
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.white,
                                    fontSize:
                                        10.5,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height:
                                7,
                          ),

                          // ==================================
                          // EXTERNE : NOM
                          // ==================================

                          if (!internal &&
                              senderName.isNotEmpty)
                            Text(
                              senderName,
                              maxLines:
                                  1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                                fontSize:
                                    13.5,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),

                          // ==================================
                          // EXTERNE : COMPTE
                          // ==================================

                          if (!internal &&
                              senderAccount.isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.only(
                                top:
                                    2,
                              ),
                              child:
                                  Text(
                                senderAccount,
                                style:
                                    TextStyle(
                                  color:
                                      Colors.white.withValues(
                                    alpha:
                                        0.82,
                                  ),
                                  fontSize:
                                    11.5,
                                ),
                              ),
                            ),

                          const SizedBox(
                            height:
                                4,
                          ),

                          // ==================================
                          // MESSAGE / MONTANT
                          // ==================================

                          Text(
                            internal
                                ? message
                                : isOutgoing
                                    ? 'Montant envoyé : $amount'
                                    : 'Montant reçu : $amount',
                            maxLines:
                                3,
                            overflow:
                                TextOverflow.ellipsis,
                            style:
                                TextStyle(
                              color:
                                  Colors.white.withValues(
                                alpha:
                                    0.94,
                              ),
                              fontSize:
                                  12.5,
                              height:
                                  1.28,
                            ),
                          ),

                          // ==================================
                          // TRANSFERT INTERNE
                          // ==================================

                          if (internal)
                            Padding(
                              padding:
                                  const EdgeInsets.only(
                                top:
                                    7,
                              ),
                              child:
                                  Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal:
                                      9,
                                  vertical:
                                      5,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color:
                                      Colors.white.withValues(
                                    alpha:
                                        0.15,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                    9,
                                  ),
                                ),
                                child:
                                    Text(
                                      '${sourceType.toUpperCase()}  →  ${destinationType.toUpperCase()}',
                                      style:
                                          TextStyle(
                                        color:
                                            Colors.white.withValues(
                                          alpha:
                                              0.90,
                                        ),
                                        fontSize:
                                            9.5,
                                        fontWeight:
                                            FontWeight.w800,
                                        letterSpacing:
                                            0.25,
                                      ),
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      width:
                          3,
                    ),

                    // ==========================================
                    // X
                    // ==========================================

                    SizedBox(
                      width:
                          34,
                      height:
                          34,
                      child:
                          IconButton(
                        padding:
                            EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(
                          minWidth:
                              34,
                          minHeight:
                              34,
                        ),
                        splashRadius:
                            18,
                        tooltip:
                            'Fermer',
                        onPressed:
                            _hideNotificationBanner,
                        icon:
                            Icon(
                              Icons.close,
                              color:
                                  Colors.white.withValues(
                                alpha:
                                    0.95,
                                ),
                              size:
                                  19,
                            ),
                      ),
                    ),
                  ],
                ),
              ),

              // =================================================
              // BARRE DE PROGRESSION
              // =================================================

              TweenAnimationBuilder<double>(
                key:
                    ValueKey(
                  notification[
                      'id'],
                ),

                tween:
                    Tween<double>(
                  begin:
                      1.0,
                  end:
                      0.0,
                ),

                duration:
                    bannerDuration,

                builder:
                    (
                  context,
                  value,
                  child,
                ) {
                  return Stack(
                    children: [
                      Container(
                        height:
                            4,
                        width:
                            double.infinity,
                        color:
                            Colors.white.withValues(
                          alpha:
                              0.12,
                        ),
                      ),

                      FractionallySizedBox(
                        widthFactor:
                            value,
                        child:
                            Container(
                          height:
                              4,
                          color:
                              Colors.white,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _notificationTimer?.cancel();

    _notificationBannerTimer
        ?.cancel();

    _notificationCountdownTimer
        ?.cancel();

    _sessionInvalidationSubscription
        ?.cancel();

    _notificationAnimationController
        .dispose();

    _apiService.dispose();

    super.dispose();
  }
}