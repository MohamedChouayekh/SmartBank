import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NotificationsScreen extends StatefulWidget {
  final int userId;

  const NotificationsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen>
    with WidgetsBindingObserver {
  static const String baseUrl =
      'http://192.168.1.155:8080';

  static const Color blue =
      Color(0xFF0B5AA6);

  static const Color darkBlue =
      Color(0xFF06457E);

  static const Color green =
      Color(0xFF087A5B);

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isRefreshing = false;

  bool _generalNotifications = true;
  bool _transfers = true;
  bool _cardPayments = true;
  bool _withdrawals = true;
  bool _securityAlerts = true;
  bool _promotions = false;

  List<Map<String, dynamic>> _notifications = [];

  String _selectedFilter = 'ALL';

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addObserver(this);

    _loadEverything();
    _startAutoRefresh();
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state ==
        AppLifecycleState.resumed) {
      _loadEverything();
      _startAutoRefresh();
    } else if (state ==
            AppLifecycleState.paused ||
        state ==
            AppLifecycleState.inactive ||
        state ==
            AppLifecycleState.detached) {
      _stopAutoRefresh();
    }
  }

  // =========================================================
  // TIMER
  // =========================================================

  void _startAutoRefresh() {
    _refreshTimer?.cancel();

    _refreshTimer =
        Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshInBackground(),
    );
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _refreshInBackground() async {
    if (!mounted ||
        _isRefreshing ||
        _isSaving) {
      return;
    }

    _isRefreshing = true;

    try {
      await Future.wait([
        _loadPreferences(
          showError: false,
        ),
        _loadNotifications(
          showError: false,
        ),
      ]);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _loadEverything() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadPreferences(
          showError: true,
        ),
        _loadNotifications(
          showError: true,
        ),
      ]);
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  // =========================================================
  // PRÉFÉRENCES
  // =========================================================

  Future<void> _loadPreferences({
    required bool showError,
  }) async {
    try {
      final response =
          await http
              .get(
                Uri.parse(
                  '$baseUrl/api/notification-preferences/${widget.userId}',
                ),
              )
              .timeout(
                const Duration(seconds: 10),
              );

      if (response.statusCode !=
          200) {
        throw Exception();
      }

      final decoded =
          jsonDecode(response.body);

      if (decoded
          is! Map<String, dynamic>) {
        throw Exception();
      }

      if (!mounted) return;

      setState(() {
        _generalNotifications =
            decoded[
                    'generalNotifications'] ==
                true;

        _transfers =
            decoded['transfers'] ==
                true;

        _cardPayments =
            decoded['cardPayments'] ==
                true;

        _withdrawals =
            decoded['withdrawals'] ==
                true;

        _securityAlerts =
            decoded[
                    'securityAlerts'] ==
                true;

        _promotions =
            decoded['promotions'] ==
                true;
      });
    } catch (e) {
      debugPrint(
        'Erreur préférences : $e',
      );

      if (showError &&
          mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content:
                Text(
              'Impossible de charger les préférences.',
            ),
            backgroundColor:
                Colors.red,
          ),
        );
      }
    }
  }

  // =========================================================
  // NOTIFICATIONS
  // =========================================================

  Future<void> _loadNotifications({
    required bool showError,
  }) async {
    try {
      final response =
          await http
              .get(
                Uri.parse(
                  '$baseUrl/api/notifications/user/${widget.userId}',
                ),
              )
              .timeout(
                const Duration(seconds: 10),
              );

      if (response.statusCode !=
          200) {
        throw Exception();
      }

      final decoded =
          jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception();
      }

      final loaded =
          <Map<String, dynamic>>[];

      for (final item in decoded) {
        if (item is Map) {
          loaded.add(
            Map<String, dynamic>.from(
              item,
            ),
          );
        }
      }

      loaded.sort(
        (a, b) {
          final aDate =
              DateTime.tryParse(
                    (a['createdAt'] ??
                            '')
                        .toString(),
                  ) ??
                  DateTime
                      .fromMillisecondsSinceEpoch(
                    0,
                  );

          final bDate =
              DateTime.tryParse(
                    (b['createdAt'] ??
                            '')
                        .toString(),
                  ) ??
                  DateTime
                      .fromMillisecondsSinceEpoch(
                    0,
                  );

          return bDate.compareTo(
            aDate,
          );
        },
      );

      if (!mounted) return;

      setState(() {
        _notifications = loaded;
      });
    } catch (e) {
      debugPrint(
        'Erreur notifications : $e',
      );

      if (showError &&
          mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content:
                Text(
              'Impossible de charger les notifications.',
            ),
            backgroundColor:
                Colors.red,
          ),
        );
      }
    }
  }

  // =========================================================
  // SAUVEGARDE
  // =========================================================

  Future<void> _savePreferences() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final response =
          await http
              .put(
                Uri.parse(
                  '$baseUrl/api/notification-preferences/${widget.userId}',
                ),
                headers: {
                  'Content-Type':
                      'application/json',
                  'Accept':
                      'application/json',
                },
                body:
                    jsonEncode({
                  'generalNotifications':
                      _generalNotifications,
                  'transfers':
                      _transfers,
                  'cardPayments':
                      _cardPayments,
                  'withdrawals':
                      _withdrawals,
                  'securityAlerts':
                      _securityAlerts,
                  'promotions':
                      _promotions,
                }),
              )
              .timeout(
                const Duration(seconds: 10),
              );

      if (response.statusCode !=
          200) {
        throw Exception();
      }

      await _loadNotifications(
        showError: false,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text(
            'Préférences enregistrées.',
          ),
          backgroundColor:
              green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text(
            'Impossible d’enregistrer les préférences.',
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // =========================================================
  // MARK READ
  // =========================================================

  Future<void> _markAsRead(
    int notificationId,
  ) async {
    try {
      final response =
          await http
              .put(
                Uri.parse(
                  '$baseUrl/api/notifications/$notificationId/read',
                ),
                headers: {
                  'Accept':
                      'application/json',
                },
              )
              .timeout(
                const Duration(seconds: 10),
              );

      if (response.statusCode !=
          200) {
        throw Exception();
      }

      await _loadNotifications(
        showError: false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text(
            'Impossible de marquer la notification comme lue.',
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // TYPE
  // =========================================================

  String _normalizeType(
    String type,
  ) {
    final value =
        type.trim().toUpperCase();

    if (value == 'TRANSFER' ||
        value == 'TRANSFER_IN' ||
        value == 'TRANSFER_OUT') {
      return 'TRANSFER';
    }

    if (value == 'PAYMENT' ||
        value == 'CARD_PAYMENT') {
      return 'PAYMENT';
    }

    if (value == 'WITHDRAWAL' ||
        value == 'ATM_WITHDRAWAL') {
      return 'WITHDRAWAL';
    }

    if (value == 'SECURITY' ||
        value == 'SECURITY_ALERT') {
      return 'SECURITY';
    }

    if (value == 'PROMOTION' ||
        value == 'PROMOTIONS') {
      return 'PROMOTION';
    }

    if (value == 'CARD') {
      return 'CARD';
    }

    return value;
  }

  bool _isNotificationAllowed(
    String type,
  ) {
    if (!_generalNotifications) {
      return false;
    }

    switch (_normalizeType(type)) {
      case 'TRANSFER':
        return _transfers;

      case 'PAYMENT':
      case 'CARD':
        return _cardPayments;

      case 'WITHDRAWAL':
        return _withdrawals;

      case 'SECURITY':
        return _securityAlerts;

      case 'PROMOTION':
        return _promotions;

      default:
        return true;
    }
  }

  bool _matchesSelectedFilter(
    String type,
  ) {
    if (_selectedFilter ==
        'ALL') {
      return true;
    }

    return _normalizeType(type) ==
        _selectedFilter;
  }

  List<Map<String, dynamic>>
      get _visibleNotifications {
    return _notifications
        .where(
          (notification) {
        final type =
            (notification['type'] ??
                    '')
                .toString();

        return _isNotificationAllowed(
              type,
            ) &&
            _matchesSelectedFilter(
              type,
            );
      },
        )
        .toList();
  }

  // =========================================================
  // ICÔNE / COULEUR
  // =========================================================

  IconData _getNotificationIcon(
    String type,
  ) {
    switch (_normalizeType(type)) {
      case 'TRANSFER':
        return Icons.swap_horiz_rounded;

      case 'PAYMENT':
        return Icons.payment_rounded;

      case 'CARD':
        return Icons.credit_card_rounded;

      case 'WITHDRAWAL':
        return Icons.atm_rounded;

      case 'SECURITY':
        return Icons.security_rounded;

      case 'PROMOTION':
        return Icons.local_offer_rounded;

      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(
    String type,
  ) {
    switch (_normalizeType(type)) {
      case 'TRANSFER':
        return blue;

      case 'PAYMENT':
        return Colors.orange;

      case 'CARD':
        return Colors.purple;

      case 'WITHDRAWAL':
        return Colors.teal;

      case 'SECURITY':
        return Colors.red;

      case 'PROMOTION':
        return const Color(
          0xFFD49A00,
        );

      default:
        return Colors.grey;
    }
  }

  // =========================================================
  // CARTE NOTIFICATION
  // =========================================================

  Widget _buildNotificationCard(
    Map<String, dynamic> notification,
  ) {
    final id =
        int.tryParse(
      (notification['id'] ??
              '')
          .toString(),
    );

    final type =
        (notification['type'] ??
                '')
            .toString();

    final title =
        (notification['title'] ??
                'Notification')
            .toString();

    final message =
        (notification['message'] ??
                '')
            .toString();

    final read =
        notification['read'] == true;

    final date =
        DateTime.tryParse(
      (notification[
                  'createdAt'] ??
              '')
          .toString(),
    );

    final color =
        _getNotificationColor(
      type,
    );

    final icon =
        _getNotificationIcon(
      type,
    );

    return Container(
      width:
          double.infinity,
      margin:
          const EdgeInsets.only(
        bottom:
            10,
      ),
      decoration:
          BoxDecoration(
        color:
            Theme.of(context).cardColor,
        borderRadius:
            BorderRadius.circular(
          17,
        ),
        border:
            Border.all(
          color:
              read
                  ? Colors.grey.withValues(
                      alpha:
                          0.10,
                    )
                  : color.withValues(
                      alpha:
                          0.25,
                    ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha:
                  read
                      ? 0.035
                      : 0.06,
            ),
            blurRadius:
                12,
            offset:
                const Offset(
              0,
              4,
            ),
          ),
        ],
      ),
      child:
          InkWell(
        borderRadius:
            BorderRadius.circular(
          17,
        ),
        onTap:
            (!read &&
                    id != null)
                ? () => _markAsRead(
                      id,
                    )
                : null,
        child:
            Padding(
          padding:
              const EdgeInsets.all(
            15,
          ),
          child:
              Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width:
                    46,
                height:
                    46,
                decoration:
                    BoxDecoration(
                  color:
                      color.withValues(
                    alpha:
                        0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child:
                    Icon(
                  icon,
                  color:
                      color,
                ),
              ),
              const SizedBox(
                width:
                    12,
              ),
              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child:
                              Text(
                            title,
                            style:
                                TextStyle(
                              fontWeight:
                                  read
                                      ? FontWeight.w600
                                      : FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!read)
                          Container(
                            width:
                                9,
                            height:
                                9,
                            decoration:
                                BoxDecoration(
                              color:
                                  color,
                              shape:
                                  BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(
                      height:
                          6,
                    ),
                    Text(
                      message,
                      style:
                          TextStyle(
                        fontSize:
                            12.5,
                        height:
                            1.35,
                        color:
                            Theme.of(
                              context,
                            )
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withValues(
                                  alpha:
                                      0.78,
                                ),
                      ),
                    ),
                    if (date != null)
                      Padding(
                        padding:
                            const EdgeInsets.only(
                          top:
                              7,
                        ),
                        child:
                            Text(
                          _formatDate(
                            date,
                          ),
                          style:
                              TextStyle(
                            fontSize:
                                10.5,
                            color:
                                Colors.grey.shade500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // SWITCH
  // =========================================================

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool>
        onChanged,
  }) {
    return Container(
      width:
          double.infinity,
      margin:
          const EdgeInsets.only(
        bottom:
            8,
      ),
      decoration:
          BoxDecoration(
        color:
            Theme.of(context)
                .cardColor,
        borderRadius:
            BorderRadius.circular(
          15,
        ),
      ),
      child:
          SwitchListTile(
        value:
            value,
        onChanged:
            _isSaving
                ? null
                : onChanged,
        secondary:
            Container(
          width:
              40,
          height:
              40,
          decoration:
              BoxDecoration(
            color:
                blue.withValues(
              alpha:
                  0.10,
            ),
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
          child:
              Icon(
            icon,
            color:
                blue,
          ),
        ),
        title:
            Text(
          title,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
        subtitle:
            Text(
          subtitle,
          style:
              const TextStyle(
            fontSize:
                11.5,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // FILTRE
  // =========================================================

  Widget _buildFilterChip({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final selected =
        _selectedFilter ==
            value;

    return ChoiceChip(
      selected:
          selected,
      avatar:
          Icon(
        icon,
        size:
            16,
        color:
            selected
                ? Colors.white
                : blue,
      ),
      label:
          Text(
        label,
        style:
            TextStyle(
          fontWeight:
              FontWeight.w600,
          color:
              selected
                  ? Colors.white
                  : null,
        ),
      ),
      selectedColor:
          blue,
      onSelected:
          (_) {
        setState(() {
          _selectedFilter =
              value;
        });
      },
    );
  }

  String _formatDate(
    DateTime date,
  ) {
    final local =
        date.toLocal();

    final day =
        local.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    final month =
        local.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    final hour =
        local.hour
            .toString()
            .padLeft(
              2,
              '0',
            );

    final minute =
        local.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$day/$month/${local.year} • $hour:$minute';
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final visible =
        _visibleNotifications;

    final unreadCount =
        _notifications
            .where(
              (n) =>
                  n['read'] !=
                  true,
            )
            .length;

    final isDark =
        Theme.of(context)
            .brightness ==
        Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark
              ? const Color(0xFF0F1723)
              : const Color(0xFFF5F7FA),

      appBar:
          AppBar(
        backgroundColor:
            Colors.transparent,
        elevation: 0,
        title:
            const Text(
          'Notifications',
          style:
              TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip:
                'Actualiser',
            onPressed:
                _isLoading ||
                        _isSaving
                    ? null
                    : _loadEverything,
            icon:
                const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),

      body:
          _isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(),
                )
              : RefreshIndicator(
                  color:
                      blue,
                  onRefresh:
                      _loadEverything,
                  child:
                      SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      30,
                    ),
                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // ----------------------------------
                        // HEADER
                        // ----------------------------------

                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets.all(
                            18,
                          ),
                          decoration:
                              BoxDecoration(
                            gradient:
                                const LinearGradient(
                              colors: [
                                blue,
                                darkBlue,
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              19,
                            ),
                          ),
                          child:
                              Row(
                            children: [
                              Container(
                                width:
                                    48,
                                height:
                                    48,
                                decoration:
                                    BoxDecoration(
                                  color:
                                      Colors.white.withValues(
                                    alpha:
                                        0.14,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                    14,
                                  ),
                                ),
                                child:
                                    const Icon(
                                  Icons
                                      .notifications_active_rounded,
                                  color:
                                      Colors.white,
                                ),
                              ),
                              const SizedBox(
                                width:
                                    12,
                              ),
                              Expanded(
                                child:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Centre de notifications',
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
                                    const SizedBox(
                                      height:
                                          3,
                                    ),
                                    Text(
                                      '$unreadCount notification(s) non lue(s)',
                                      style:
                                          TextStyle(
                                        color:
                                            Colors.white.withValues(
                                          alpha:
                                              0.75,
                                        ),
                                        fontSize:
                                            12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          height:
                              22,
                        ),

                        Text(
                          'Notifications reçues',
                          style:
                              Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                fontWeight:
                                    FontWeight.w800,
                              ),
                        ),

                        const SizedBox(
                          height:
                              12,
                        ),

                        SingleChildScrollView(
                          scrollDirection:
                              Axis.horizontal,
                          child:
                              Row(
                            children: [
                              _buildFilterChip(
                                value:
                                    'ALL',
                                label:
                                    'Toutes',
                                icon:
                                    Icons
                                        .notifications_rounded,
                              ),
                              const SizedBox(
                                width:
                                    7,
                              ),
                              _buildFilterChip(
                                value:
                                    'TRANSFER',
                                label:
                                    'Virements',
                                icon:
                                    Icons
                                        .swap_horiz_rounded,
                              ),
                              const SizedBox(
                                width:
                                    7,
                              ),
                              _buildFilterChip(
                                value:
                                    'PAYMENT',
                                label:
                                    'Paiements',
                                icon:
                                    Icons
                                        .payment_rounded,
                              ),
                              const SizedBox(
                                width:
                                    7,
                              ),
                              _buildFilterChip(
                                value:
                                    'WITHDRAWAL',
                                label:
                                    'Retraits',
                                icon:
                                    Icons
                                        .atm_rounded,
                              ),
                              const SizedBox(
                                width:
                                    7,
                              ),
                              _buildFilterChip(
                                value:
                                    'SECURITY',
                                label:
                                    'Sécurité',
                                icon:
                                    Icons
                                        .security_rounded,
                              ),
                              const SizedBox(
                                width:
                                    7,
                              ),
                              _buildFilterChip(
                                value:
                                    'PROMOTION',
                                label:
                                    'Promotions',
                                icon:
                                    Icons
                                        .local_offer_rounded,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          height:
                              18,
                        ),

                        if (!_generalNotifications)
                          Container(
                            width:
                                double.infinity,
                            padding:
                                const EdgeInsets.all(
                              16,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  isDark
                                      ? const Color(
                                          0xFF2A2117,
                                        )
                                      : const Color(
                                          0xFFFFF7E8,
                                        ),
                              borderRadius:
                                  BorderRadius.circular(
                                17,
                              ),
                            ),
                            child:
                                Row(
                              children: [
                                const Icon(
                                  Icons
                                      .notifications_off_rounded,
                                  color:
                                      Colors.orange,
                                ),
                                const SizedBox(
                                  width:
                                      10,
                                ),
                                const Expanded(
                                  child:
                                      Text(
                                    'Les notifications sont désactivées. Elles restent enregistrées dans SmartBank.',
                                    style:
                                        TextStyle(
                                      fontSize:
                                          12.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (_generalNotifications &&
                            visible.isEmpty)
                          Container(
                            width:
                                double.infinity,
                            padding:
                                const EdgeInsets.symmetric(
                              vertical:
                                  36,
                              horizontal:
                                  20,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  Theme.of(context)
                                      .cardColor,
                              borderRadius:
                                  BorderRadius.circular(
                                17,
                              ),
                            ),
                            child:
                                Column(
                              children: [
                                Icon(
                                  Icons
                                      .notifications_none_rounded,
                                  size:
                                      52,
                                  color:
                                      Colors.grey.shade400,
                                ),
                                const SizedBox(
                                  height:
                                      12,
                                ),
                                const Text(
                                  'Aucune notification dans cette catégorie.',
                                  textAlign:
                                      TextAlign.center,
                                  style:
                                      TextStyle(
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (_generalNotifications)
                          ...visible.map(
                            _buildNotificationCard,
                          ),

                        const SizedBox(
                          height:
                              30,
                        ),

                        // ----------------------------------
                        // PRÉFÉRENCES
                        // ----------------------------------

                        Text(
                          'Préférences',
                          style:
                              Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                fontWeight:
                                    FontWeight.w800,
                              ),
                        ),

                        const SizedBox(
                          height:
                              6,
                        ),

                        Text(
                          'Personnalisez l’affichage des notifications SmartBank.',
                          style:
                              TextStyle(
                            color:
                                Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(
                                      alpha:
                                          0.68,
                                    ),
                            fontSize:
                                12.5,
                          ),
                        ),

                        const SizedBox(
                          height:
                              14,
                        ),

                        _buildSwitch(
                          title:
                              'Notifications générales',
                          subtitle:
                              'Afficher les notifications SmartBank.',
                          icon:
                              Icons
                                  .notifications_active_outlined,
                          value:
                              _generalNotifications,
                          onChanged:
                              (value) {
                            setState(() {
                              _generalNotifications =
                                  value;
                            });
                            _savePreferences();
                          },
                        ),

                        _buildSwitch(
                          title:
                              'Virements',
                          subtitle:
                              'Afficher les notifications de virements.',
                          icon:
                              Icons.swap_horiz_rounded,
                          value:
                              _transfers,
                          onChanged:
                              (value) {
                            setState(() {
                              _transfers =
                                  value;
                            });
                            _savePreferences();
                          },
                        ),

                        _buildSwitch(
                          title:
                              'Paiements par carte',
                          subtitle:
                              'Afficher les notifications de paiements.',
                          icon:
                              Icons
                                  .credit_card_outlined,
                          value:
                              _cardPayments,
                          onChanged:
                              (value) {
                            setState(() {
                              _cardPayments =
                                  value;
                            });
                            _savePreferences();
                          },
                        ),

                        _buildSwitch(
                          title:
                              'Retraits',
                          subtitle:
                              'Afficher les notifications de retraits.',
                          icon:
                              Icons.atm_rounded,
                          value:
                              _withdrawals,
                          onChanged:
                              (value) {
                            setState(() {
                              _withdrawals =
                                  value;
                            });
                            _savePreferences();
                          },
                        ),

                        _buildSwitch(
                          title:
                              'Alertes de sécurité',
                          subtitle:
                              'Afficher les alertes de sécurité.',
                          icon:
                              Icons.security_outlined,
                          value:
                              _securityAlerts,
                          onChanged:
                              (value) {
                            setState(() {
                              _securityAlerts =
                                  value;
                            });
                            _savePreferences();
                          },
                        ),

                        _buildSwitch(
                          title:
                              'Promotions',
                          subtitle:
                              'Afficher les offres et promotions SmartBank.',
                          icon:
                              Icons
                                  .local_offer_outlined,
                          value:
                              _promotions,
                          onChanged:
                              (value) {
                            setState(() {
                              _promotions =
                                  value;
                            });
                            _savePreferences();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  @override
  void dispose() {
    _stopAutoRefresh();

    WidgetsBinding.instance
        .removeObserver(this);

    super.dispose();
  }
}