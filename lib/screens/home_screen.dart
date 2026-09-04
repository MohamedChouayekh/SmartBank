import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/transaction.dart';
import '../widgets/smartbank_brand.dart';

import 'payments_screen.dart';
import 'transactions_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  final int userId;
  final String firstName;
  final double balance;
  final double epargneBalance;

  final ValueChanged<int>? onNavigateTab;
  final ValueChanged<double>? onBalanceChanged;
  final ValueChanged<double>? onEpargneBalanceChanged;

  const HomeScreen({
    super.key,
    required this.userId,
    required this.firstName,
    this.balance = 0.0,
    this.epargneBalance = 0.0,
    this.onNavigateTab,
    this.onBalanceChanged,
    this.onEpargneBalanceChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  // ============================================================
  // CONFIGURATION
  // ============================================================

  static const String baseUrl = 'http://192.168.1.155:8080';

  static const Color _blue = Color(0xFF0B5AA6);
  static const Color _darkBlue = Color(0xFF06457E);

  // ============================================================
  // DONNÉES
  // ============================================================

  List<BankTransaction> _transactions = [];

  final List<dynamic> _paymentsHistory = [];

  bool _isLoadingTransactions = true;

  int? _currentAccountId;

  // ============================================================
  // ACTUALISATION
  // ============================================================

  Timer? _refreshTimer;

  bool _isRefreshing = false;

  // ============================================================
  // UI
  // ============================================================

  bool _balanceVisible = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _loadAccountAndTransactions();

    _startAutoRefresh();
  }

  // ============================================================
  // CYCLE DE VIE
  // ============================================================

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      _loadAccountAndTransactions();
      _startAutoRefresh();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _stopAutoRefresh();
    }
  }

  // ============================================================
  // TIMER
  // ============================================================

  void _startAutoRefresh() {
    _refreshTimer?.cancel();

    _refreshTimer = Timer.periodic(
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
        _isLoadingTransactions) {
      return;
    }

    await _loadAccountAndTransactions(
      silent: true,
    );
  }

  // ============================================================
  // CHARGEMENT COMPTES + TRANSACTIONS
  // ============================================================

  Future<void> _loadAccountAndTransactions({
    bool silent = false,
  }) async {
    if (!mounted) return;

    if (!silent) {
      setState(() {
        _isLoadingTransactions = true;
      });
    }

    if (_isRefreshing) {
      return;
    }

    _isRefreshing = true;

    try {
      // ========================================================
      // 1. COMPTES
      // ========================================================

      final accountsResponse = await http
          .get(
            Uri.parse(
              '$baseUrl/api/accounts/user/${widget.userId}',
            ),
          )
          .timeout(
            const Duration(seconds: 10),
          );

      if (!mounted) return;

      if (accountsResponse.statusCode != 200) {
        throw Exception(
          'Impossible de récupérer les comptes.',
        );
      }

      final decodedAccounts = jsonDecode(
        accountsResponse.body,
      );

      if (decodedAccounts is! List) {
        throw Exception(
          'Réponse comptes invalide.',
        );
      }

      Map<String, dynamic>? currentAccount;

      Map<String, dynamic>? savingsAccount;

      for (final account in decodedAccounts) {
        if (account is! Map<String, dynamic>) {
          continue;
        }

        final type = (account['type'] ?? '')
            .toString()
            .trim()
            .toUpperCase();

        if (type == 'CURRENT' &&
            currentAccount == null) {
          currentAccount = account;
        }

        if (type == 'SAVINGS' &&
            savingsAccount == null) {
          savingsAccount = account;
        }
      }

      // ========================================================
      // 2. COMPTE COURANT
      // ========================================================

      if (currentAccount == null) {
        if (!mounted) return;

        setState(() {
          _transactions = [];
          _currentAccountId = null;
          _isLoadingTransactions = false;
        });

        widget.onBalanceChanged?.call(0.0);

        return;
      }

      // ========================================================
      // 3. ID COMPTE COURANT
      // ========================================================

      final accountId = currentAccount['id'];

      if (accountId == null) {
        throw Exception(
          'ID du compte courant introuvable.',
        );
      }

      final parsedAccountId = int.tryParse(
        accountId.toString(),
      );

      if (parsedAccountId == null) {
        throw Exception(
          'ID du compte courant invalide.',
        );
      }

      _currentAccountId = parsedAccountId;

      // ========================================================
      // 4. SOLDE COURANT
      // ========================================================

      final dynamic rawCurrentBalance =
          currentAccount['balance'];

      final double currentBalance =
          rawCurrentBalance is num
              ? rawCurrentBalance.toDouble()
              : double.tryParse(
                    rawCurrentBalance?.toString() ?? '',
                  ) ??
                  0.0;

      // ========================================================
      // 5. SOLDE ÉPARGNE
      // ========================================================

      double savingsBalance =
          widget.epargneBalance;

      if (savingsAccount != null) {
        final dynamic rawSavingsBalance =
            savingsAccount['balance'];

        savingsBalance = rawSavingsBalance is num
            ? rawSavingsBalance.toDouble()
            : double.tryParse(
                  rawSavingsBalance?.toString() ?? '',
                ) ??
                0.0;
      }

      // ========================================================
      // REMONTER LES SOLDES
      // ========================================================

      widget.onBalanceChanged?.call(
        currentBalance,
      );

      widget.onEpargneBalanceChanged?.call(
        savingsBalance,
      );

      // ========================================================
      // 6. TRANSACTIONS
      // ========================================================

      final transactionsResponse = await http
          .get(
            Uri.parse(
              '$baseUrl/api/transactions/account/$_currentAccountId',
            ),
          )
          .timeout(
            const Duration(seconds: 10),
          );

      if (!mounted) return;

      if (transactionsResponse.statusCode != 200) {
        throw Exception(
          'Impossible de récupérer l\'historique.',
        );
      }

      final decodedTransactions = jsonDecode(
        transactionsResponse.body,
      );

      if (decodedTransactions is! List) {
        throw Exception(
          'Réponse historique invalide.',
        );
      }

      final List<BankTransaction> loadedTransactions =
          [];

      for (final item in decodedTransactions) {
        if (item is! Map<String, dynamic>) {
          continue;
        }

        final transaction =
            _convertTransaction(item);

        if (transaction != null) {
          loadedTransactions.add(transaction);
        }
      }

      loadedTransactions.sort(
        (a, b) => b.date.compareTo(a.date),
      );

      if (!mounted) return;

      setState(() {
        _transactions = loadedTransactions;
        _isLoadingTransactions = false;
      });
    } catch (e) {
      debugPrint(
        'Erreur chargement HomeScreen : $e',
      );

      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Impossible de charger les informations du compte.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }

      if (mounted && !silent) {
        setState(() {
          _transactions = [];
          _isLoadingTransactions = false;
        });
      }
    } finally {
      _isRefreshing = false;
    }
  }

  // ============================================================
  // CONVERSION TRANSACTION
  // ============================================================

  BankTransaction? _convertTransaction(
    Map<String, dynamic> json,
  ) {
    try {
      final int id =
          int.tryParse(
            (json['id'] ?? '').toString(),
          ) ??
          DateTime.now().millisecondsSinceEpoch;

      final String type =
          (json['type'] ?? '')
              .toString()
              .toUpperCase();

      final dynamic rawAmount =
          json['amount'];

      final double amount =
          rawAmount is num
              ? rawAmount.toDouble()
              : double.tryParse(
                    rawAmount?.toString() ?? '',
                  ) ??
                  0.0;

      final String label =
          (json['label'] ?? '')
              .toString()
              .trim();

      final String reference =
          (json['reference'] ?? '')
              .toString()
              .trim();

      final String relatedAccount =
          (json['relatedAccountNumber'] ?? '')
              .toString()
              .trim();

      final String createdAt =
          (json['createdAt'] ?? '')
              .toString();

      DateTime date;

      try {
        date = DateTime.parse(
          createdAt,
        );
      } catch (_) {
        date = DateTime.now();
      }

      // ========================================================
      // VIREMENT SORTANT
      // ========================================================

      if (type == 'TRANSFER_OUT') {
        return BankTransaction(
          id: id,
          title: label.isNotEmpty
              ? label
              : 'Virement envoyé',
          description: relatedAccount.isNotEmpty
              ? 'Vers : $relatedAccount'
              : 'Virement envoyé',
          amount: amount,
          currency: 'TND',
          date: date,
          type: TransactionType.expense,
          category: 'Virement',
        );
      }

      // ========================================================
      // VIREMENT ENTRANT
      // ========================================================

      if (type == 'TRANSFER_IN') {
        return BankTransaction(
          id: id,
          title: label.isNotEmpty
              ? label
              : 'Virement reçu',
          description: relatedAccount.isNotEmpty
              ? 'Depuis : $relatedAccount'
              : 'Virement reçu',
          amount: amount,
          currency: 'TND',
          date: date,
          type: TransactionType.income,
          category: 'Virement',
        );
      }

      // ========================================================
      // PAIEMENT
      // ========================================================

      if (type == 'PAYMENT') {
        return BankTransaction(
          id: id,
          title: label.isNotEmpty
              ? label
              : 'Paiement',
          description: reference.isNotEmpty
              ? 'Réf : $reference'
              : 'Paiement',
          amount: amount,
          currency: 'TND',
          date: date,
          type: TransactionType.expense,
          category: 'Paiement',
        );
      }

      // ========================================================
      // RECHARGE
      // ========================================================

      if (type == 'RECHARGE') {
        return BankTransaction(
          id: id,
          title: label.isNotEmpty
              ? label
              : 'Recharge',
          description: reference.isNotEmpty
              ? 'Réf : $reference'
              : 'Recharge',
          amount: amount,
          currency: 'TND',
          date: date,
          type: TransactionType.expense,
          category: 'Recharge',
        );
      }

      // ========================================================
      // AUTRE
      // ========================================================

      return BankTransaction(
        id: id,
        title: label.isNotEmpty
            ? label
            : 'Transaction',
        description: reference.isNotEmpty
            ? 'Réf : $reference'
            : 'Opération bancaire',
        amount: amount,
        currency: 'TND',
        date: date,
        type: TransactionType.expense,
        category: type.isNotEmpty
            ? type
            : 'Autre',
      );
    } catch (e) {
      debugPrint(
        'Erreur conversion transaction : $e',
      );

      return null;
    }
  }

  // ============================================================
  // REFRESH MANUEL
  // ============================================================

  Future<void> _refreshTransactions() async {
    await _loadAccountAndTransactions();
  }

  // ============================================================
  // SALUTATION
  // ============================================================

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Bonjour';
    }

    if (hour < 18) {
      return 'Bon après-midi';
    }

    return 'Bonsoir';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    final isDark =
        theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F1723)
          : const Color(0xFFF5F7FA),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF0F1723)
            : const Color(0xFFF5F7FA),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: const SmartBankBrand(
          iconSize: 34,
        ),
        actions: [
          // Notifications
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      NotificationsScreen(
                    userId: widget.userId,
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.notifications_none_rounded,
            ),
          ),

          // Profil
          IconButton(
            tooltip: 'Profil',
            onPressed: () {
              widget.onNavigateTab?.call(4);
            },
            icon: const Icon(
              Icons.person_outline_rounded,
            ),
          ),

          const SizedBox(
            width: 6,
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: RefreshIndicator(
        onRefresh: _refreshTransactions,
        color: _blue,
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // CARTE HÉROS
              // ==================================================

              _buildHeroCard(isDark),

              // ==================================================
              // CONTENU
              // ==================================================

              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  24,
                  20,
                  0,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // ACTIONS RAPIDES
                    // ==================================================

                    Text(
                      'Actions rapides',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                        color: isDark
                            ? Colors.white
                            : const Color(
                                0xFF1A2340,
                              ),
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    _buildQuickActions(
                      context,
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    // ==================================================
                    // TRANSACTIONS
                    // ==================================================

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Dernières transactions',
                            style: theme
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                              fontWeight:
                                  FontWeight
                                      .w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(
                                      0xFF1A2340,
                                    ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        TransactionsScreen(
                                  userId:
                                      widget
                                          .userId,
                                ),
                              ),
                            );
                          },
                          style:
                              TextButton.styleFrom(
                            foregroundColor:
                                _blue,
                          ),
                          child:
                              const Text(
                            'Voir tout',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    _buildTransactionsList(
                      isDark,
                    ),

                    const SizedBox(
                      height: 30,
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

  // ============================================================
  // CARTE HÉROS SOLDE
  // ============================================================

  Widget _buildHeroCard(
    bool isDark,
  ) {
    final balance =
        widget.balance;

    final epargne =
        widget.epargneBalance;

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        0,
      ),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            Color(0xFF0B5AA6),
            Color(0xFF06457E),
          ],
        ),
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(
              alpha: 0.35,
            ),
            blurRadius: 24,
            offset:
                const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Cercle décoratif 1
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color: Colors.white
                    .withValues(
                  alpha: 0.05,
                ),
              ),
            ),
          ),

          // Cercle décoratif 2
          Positioned(
            right: 30,
            bottom: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color: Colors.white
                    .withValues(
                  alpha: 0.04,
                ),
              ),
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.all(
              24,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                // ==================================================
                // SALUTATION
                // ==================================================

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          '${_getGreeting()}, ${widget.firstName} 👋',
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize:
                                16,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        Text(
                          'Compte courant',
                          style:
                              TextStyle(
                            color: Colors
                                .white
                                .withValues(
                              alpha:
                                  0.70,
                            ),
                            fontSize:
                                13,
                          ),
                        ),
                      ],
                    ),

                    // Oeil
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _balanceVisible =
                              !_balanceVisible;
                        });
                      },
                      child: Container(
                        padding:
                            const EdgeInsets
                                .all(
                          8,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors
                              .white
                              .withValues(
                            alpha:
                                0.12,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),
                        ),
                        child: Icon(
                          _balanceVisible
                              ? Icons
                                  .visibility_outlined
                              : Icons
                                  .visibility_off_outlined,
                          color:
                              Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // SOLDE PRINCIPAL
                // ==================================================

                Text(
                  _balanceVisible
                      ? '${balance.toStringAsFixed(2)} TND'
                      : '•••••• TND',
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        34,
                    fontWeight:
                        FontWeight
                            .w800,
                    letterSpacing:
                        -0.5,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  'Solde disponible',
                  style:
                      TextStyle(
                    color: Colors
                        .white
                        .withValues(
                      alpha:
                          0.70,
                    ),
                    fontSize:
                        13,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // SÉPARATEUR
                // ==================================================

                Container(
                  height: 1,
                  color: Colors
                      .white
                      .withValues(
                    alpha: 0.15,
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                // ==================================================
                // ÉPARGNE
                // ==================================================

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          'Épargne',
                          style:
                              TextStyle(
                            color: Colors
                                .white
                                .withValues(
                              alpha:
                                  0.70,
                            ),
                            fontSize:
                                12,
                          ),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          _balanceVisible
                              ? '${epargne.toStringAsFixed(2)} TND'
                              : '•••••• TND',
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize:
                                18,
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),
                      ],
                    ),

                    // Voir comptes
                    GestureDetector(
                      onTap: () {
                        widget
                            .onNavigateTab
                            ?.call(1);
                      },
                      child:
                          Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal:
                              14,
                          vertical:
                              8,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors
                              .white
                              .withValues(
                            alpha:
                                0.15,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                          border:
                              Border.all(
                            color: Colors
                                .white
                                .withValues(
                              alpha:
                                  0.25,
                            ),
                          ),
                        ),
                        child:
                            const Text(
                          'Voir comptes →',
                          style:
                              TextStyle(
                            color:
                                Colors.white,
                            fontSize:
                                12,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIONS RAPIDES
  // ============================================================

  Widget _buildQuickActions(
    BuildContext context,
  ) {
    final isDark =
        Theme.of(context)
                .brightness ==
            Brightness.dark;

    final actions = [
      _QuickActionData(
        icon:
            Icons.swap_horiz_rounded,
        label:
            'Virement',
        color: _blue,
        onTap: () {
          widget
              .onNavigateTab
              ?.call(2);
        },
      ),

      _QuickActionData(
        icon:
            Icons.payment_rounded,
        label:
            'Paiement',
        color:
            const Color(
          0xFF7C3AED,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      PaymentsScreen(
                userId:
                    widget.userId,
                courantBalance:
                    widget.balance,
                paymentsHistory:
                    _paymentsHistory,
                onPaymentSuccess:
                    (
                  accountName,
                  amount,
                  item,
                ) {
                  widget
                      .onBalanceChanged
                      ?.call(
                    widget.balance -
                        amount,
                  );

                  _refreshTransactions();
                },
              ),
            ),
          );
        },
      ),

      _QuickActionData(
        icon:
            Icons.credit_card_rounded,
        label:
            'Cartes',
        color:
            const Color(
          0xFF0891B2,
        ),
        onTap: () {
          widget
              .onNavigateTab
              ?.call(3);
        },
      ),

      _QuickActionData(
        icon:
            Icons.account_balance_wallet_rounded,
        label:
            'Comptes',
        color:
            const Color(
          0xFF059669,
        ),
        onTap: () {
          widget
              .onNavigateTab
              ?.call(1);
        },
      ),
    ];

    return Row(
      children: actions
          .map(
            (action) =>
                Expanded(
              child:
                  Padding(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal:
                      4,
                ),
                child:
                    _buildQuickActionItem(
                  action,
                  isDark,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  // ============================================================
  // ITEM ACTION RAPIDE
  // ============================================================

  Widget _buildQuickActionItem(
    _QuickActionData action,
    bool isDark,
  ) {
    return GestureDetector(
      onTap:
          action.onTap,
      child:
          Container(
        padding:
            const EdgeInsets
                .symmetric(
          vertical: 14,
        ),
        decoration:
            BoxDecoration(
          color: isDark
              ? const Color(
                  0xFF1A2340,
                )
              : Colors.white,
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(
                alpha:
                    isDark
                        ? 0.20
                        : 0.06,
              ),
              blurRadius: 10,
              offset:
                  const Offset(
                0,
                3,
              ),
            ),
          ],
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration:
                  BoxDecoration(
                color: action
                    .color
                    .withValues(
                  alpha: 0.12,
                ),
                borderRadius:
                    BorderRadius
                        .circular(
                  14,
                ),
              ),
              child: Icon(
                action.icon,
                color:
                    action.color,
                size: 24,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              action.label,
              style: TextStyle(
                fontSize:
                    12,
                fontWeight:
                    FontWeight
                        .w600,
                color: isDark
                    ? Colors
                        .white70
                    : const Color(
                        0xFF374151,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LISTE TRANSACTIONS
  // ============================================================

  Widget _buildTransactionsList(
    bool isDark,
  ) {
    if (_isLoadingTransactions) {
      return const Padding(
        padding:
            EdgeInsets.symmetric(
          vertical: 30,
        ),
        child: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Container(
        width:
            double.infinity,
        padding:
            const EdgeInsets
                .symmetric(
          vertical: 40,
        ),
        decoration:
            BoxDecoration(
          color: isDark
              ? const Color(
                  0xFF1A2340,
                )
              : Colors.white,
          borderRadius:
              BorderRadius.circular(
            16,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons
                  .receipt_long_outlined,
              size: 48,
              color: isDark
                  ? Colors.white24
                  : Colors.grey.shade300,
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              'Aucune transaction',
              style:
                  TextStyle(
                color: isDark
                    ? Colors
                        .white38
                    : Colors
                        .grey
                        .shade400,
                fontStyle:
                    FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    final visibleTransactions =
        _transactions
            .take(5)
            .toList();

    return Container(
      decoration:
          BoxDecoration(
        color: isDark
            ? const Color(
                0xFF1A2340,
              )
            : Colors.white,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: isDark
                  ? 0.20
                  : 0.05,
            ),
            blurRadius: 10,
            offset:
                const Offset(
              0,
              3,
            ),
          ),
        ],
      ),
      child: Column(
        children: visibleTransactions
            .asMap()
            .entries
            .map(
              (entry) {
                final index =
                    entry.key;

                final tx =
                    entry.value;

                final isLast =
                    index ==
                        visibleTransactions
                                .length -
                            1;

                return Column(
                  children: [
                    _buildTransactionTile(
                      tx,
                      isDark,
                    ),

                    if (!isLast)
                      Divider(
                        height: 1,
                        indent: 70,
                        endIndent: 16,
                        color: isDark
                            ? Colors
                                .white
                                .withValues(
                              alpha:
                                  0.06,
                            )
                            : Colors
                                .grey
                                .shade100,
                      ),
                  ],
                );
              },
            )
            .toList(),
      ),
    );
  }

  // ============================================================
  // TRANSACTION TILE
  // ============================================================

  Widget _buildTransactionTile(
    BankTransaction tx,
    bool isDark,
  ) {
    final isIncome =
        tx.type ==
            TransactionType
                .income;

    final color = isIncome
        ? const Color(
            0xFF059669,
          )
        : const Color(
            0xFFDC2626,
          );

    final bgColor = isIncome
        ? const Color(
                0xFF059669)
            .withValues(
            alpha: 0.10,
          )
        : const Color(
                0xFFDC2626)
            .withValues(
            alpha: 0.10,
          );

    // ==========================================================
    // ICÔNE SELON LE TYPE
    // ==========================================================

    IconData icon;

    if (tx.category ==
        'Virement') {
      icon = isIncome
          ? Icons
              .arrow_downward_rounded
          : Icons
              .arrow_upward_rounded;
    } else if (tx.category ==
        'Paiement') {
      icon =
          Icons.payment_rounded;
    } else if (tx.category ==
        'Recharge') {
      icon =
          Icons.phone_android_rounded;
    } else {
      icon =
          Icons.receipt_outlined;
    }

    // ==========================================================
    // DATE
    // ==========================================================

    final day = tx.date.day
        .toString()
        .padLeft(2, '0');

    final month = tx.date.month
        .toString()
        .padLeft(2, '0');

    final hour = tx.date.hour
        .toString()
        .padLeft(2, '0');

    final minute = tx.date.minute
        .toString()
        .padLeft(2, '0');

    // ==========================================================
    // TILE
    // ==========================================================

    return Padding(
      padding:
          const EdgeInsets
              .symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Row(
        children: [
          // Icône
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(
              color: bgColor,
              borderRadius:
                  BorderRadius
                      .circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          // Description
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  tx.title,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight
                            .w600,
                    fontSize:
                        14,
                    color: isDark
                        ? Colors
                            .white
                        : const Color(
                            0xFF111827,
                          ),
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  '$day/$month • $hour:$minute',
                  style:
                      TextStyle(
                    fontSize:
                        12,
                    color: isDark
                        ? Colors
                            .white38
                        : Colors
                            .grey
                            .shade500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          // Montant
          Flexible(
            child: Text(
              '${isIncome ? '+' : '-'} ${tx.amount.toStringAsFixed(2)} TND',
              maxLines: 1,
              overflow:
                  TextOverflow
                      .ellipsis,
              textAlign:
                  TextAlign.end,
              style:
                  TextStyle(
                color: color,
                fontWeight:
                    FontWeight
                        .w700,
                fontSize:
                    14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _stopAutoRefresh();

    WidgetsBinding.instance
        .removeObserver(this);

    super.dispose();
  }
}

// ================================================================
// MODÈLE ACTION RAPIDE
// ================================================================

class _QuickActionData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}