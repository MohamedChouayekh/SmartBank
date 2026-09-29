import 'dart:async';

import 'package:flutter/material.dart';

import '../models/account.dart';
import '../services/api_service.dart';

class AccountsScreen extends StatefulWidget {
  final int userId;
  final bool isDark;
  final VoidCallback? onThemeChanged;

  // =========================================================
  // SYNCHRONISATION DES SOLDES
  // =========================================================

  final double? courantBalance;
  final double? epargneBalance;

  final ValueChanged<double>?
      onCourantBalanceChanged;

  final ValueChanged<double>?
      onEpargneBalanceChanged;

  const AccountsScreen({
    super.key,
    required this.userId,
    this.isDark = false,
    this.onThemeChanged,

    this.courantBalance,
    this.epargneBalance,

    this.onCourantBalanceChanged,
    this.onEpargneBalanceChanged,
  });

  @override
  State<AccountsScreen> createState() =>
      _AccountsScreenState();
}

class _AccountsScreenState
    extends State<AccountsScreen> {
  final ApiService _apiService =
      ApiService();

  List<Account> _accounts = [];
  bool _isLoading = true;
  String? _errorMessage;

  static const Color _darkBlue =
      Color(0xFF0B1F3A);

  static const Color _blue =
      Color(0xFF1565C0);

  static const Color _green =
      Color(0xFF2E7D32);

  static const Color _lightGreen =
      Color(0xFF43A047);

  static const Color _lightBackground =
      Color(0xFFF5F7FB);

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  // =========================================================
  // IMPORTANT :
  // SYNCHRONISATION DEPUIS MAIN NAVIGATION
  //
  // Lorsque le transfert est effectué depuis Virements,
  // MainNavigation change ses soldes.
  //
  // Comme AccountsScreen est dans un IndexedStack,
  // son état reste conservé.
  //
  // On met donc à jour ici les soldes locaux.
  // =========================================================

  @override
  void didUpdateWidget(
    covariant AccountsScreen oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final courantChanged =
        widget.courantBalance !=
            oldWidget.courantBalance;

    final epargneChanged =
        widget.epargneBalance !=
            oldWidget.epargneBalance;

    if (!courantChanged &&
        !epargneChanged) {
      return;
    }

    if (_accounts.isEmpty) {
      return;
    }

    bool changed = false;

    final updatedAccounts =
        _accounts.map(
      (account) {
        final type = account.accountType
            .trim()
            .toUpperCase();

        if (type == 'CURRENT' &&
            widget.courantBalance !=
                null &&
            widget.courantBalance !=
                account.balance) {
          changed = true;

          return Account(
            id: account.id,
            accountNumber:
                account.accountNumber,
            accountType:
                account.accountType,
            balance:
                widget.courantBalance!,
            currency:
                account.currency,
          );
        }

        if (type == 'SAVINGS' &&
            widget.epargneBalance !=
                null &&
            widget.epargneBalance !=
                account.balance) {
          changed = true;

          return Account(
            id: account.id,
            accountNumber:
                account.accountNumber,
            accountType:
                account.accountType,
            balance:
                widget.epargneBalance!,
            currency:
                account.currency,
          );
        }

        return account;
      },
    ).toList();

    if (changed) {
      _accounts =
          updatedAccounts;
    }
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  // =========================================================
  // CHARGER LES COMPTES
  // =========================================================

  Future<void> _loadAccounts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response =
          await _apiService.get(
        '/api/accounts/user/${widget.userId}',
      );

      if (response.statusCode !=
          200) {
        throw Exception(
          _apiService.getErrorMessage(
            response,
          ),
        );
      }

      final decoded =
          _apiService.decodeResponse(
        response,
      );

      if (decoded is! List) {
        throw Exception(
          'Format de réponse invalide pour les comptes.',
        );
      }

      final List<Account> accounts =
          [];

      for (final item in decoded) {
        if (item is! Map) continue;

        final map =
            Map<String, dynamic>.from(
          item,
        );

        final int? id =
            _parseInt(
          map['id'],
        );

        final double? balance =
            _parseDouble(
          map['balance'],
        );

        final String accountNumber =
            (map['accountNumber'] ??
                    '')
                .toString();

        final String accountType =
            (map['type'] ??
                    map['accountType'] ??
                    '')
                .toString();

        final String currency =
            (map['currency'] ??
                    'TND')
                .toString();

        if (id == null ||
            balance == null ||
            accountNumber.isEmpty) {
          continue;
        }

        accounts.add(
          Account(
            id: id,
            accountNumber:
                accountNumber,
            accountType:
                accountType,
            balance:
                balance,
            currency:
                currency,
          ),
        );
      }

      // =====================================================
      // RÉCUPÉRER LES NOUVEAUX SOLDES
      // =====================================================

      double? newCourantBalance;
      double? newEpargneBalance;

      for (final account in accounts) {
        final type =
            account.accountType
                .trim()
                .toUpperCase();

        if (type == 'CURRENT') {
          newCourantBalance =
              account.balance;
        } else if (type ==
            'SAVINGS') {
          newEpargneBalance =
              account.balance;
        }
      }

      if (!mounted) return;

      setState(() {
        _accounts =
            accounts;
        _isLoading =
            false;
      });

      // =====================================================
      // SYNCHRONISER VERS MAIN NAVIGATION
      // =====================================================

      if (newCourantBalance !=
          null) {
        widget.onCourantBalanceChanged
            ?.call(
          newCourantBalance,
        );
      }

      if (newEpargneBalance !=
          null) {
        widget.onEpargneBalanceChanged
            ?.call(
          newEpargneBalance,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading =
            false;
        _errorMessage =
            _cleanErrorMessage(e);
      });
    }
  }

  // =========================================================
  // UTILITAIRES
  // =========================================================

  int? _parseInt(
    dynamic value,
  ) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }

  double? _parseDouble(
    dynamic value,
  ) {
    if (value == null) return null;
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value
          .toString()
          .replaceAll(',', '.'),
    );
  }

  String _cleanErrorMessage(
    Object error,
  ) {
    final message =
        error.toString();

    if (message.startsWith(
        'Exception: ')) {
      return message.substring(11);
    }

    return message;
  }

  Account? _findAccountByType(
    String type,
  ) {
    for (final account
        in _accounts) {
      if (account.accountType
              .trim()
              .toUpperCase() ==
          type.toUpperCase()) {
        return account;
      }
    }

    return null;
  }

  double get _totalBalance {
    return _accounts.fold(
      0.0,
      (sum, account) =>
          sum + account.balance,
    );
  }

  // =========================================================
  // TRANSFERT ENTRE MES COMPTES
  // =========================================================

  Future<void>
      _showTransferDialog() async {
    final currentAccount =
        _findAccountByType(
      'CURRENT',
    );

    final savingsAccount =
        _findAccountByType(
      'SAVINGS',
    );

    if (currentAccount ==
            null ||
        savingsAccount ==
            null) {
      _showMessage(
        'Les comptes courant et épargne sont nécessaires pour effectuer un transfert.',
        isError: true,
      );
      return;
    }

    bool currentToSavings =
        true;

    bool isProcessing =
        false;

    String? localError;

    final amountController =
        TextEditingController();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (
        dialogContext,
      ) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            final sourceAccount =
                currentToSavings
                    ? currentAccount
                    : savingsAccount;

            final destinationAccount =
                currentToSavings
                    ? savingsAccount
                    : currentAccount;

            final sourceTitle =
                currentToSavings
                    ? 'Compte courant'
                    : 'Compte épargne';

            final destinationTitle =
                currentToSavings
                    ? 'Compte épargne'
                    : 'Compte courant';

            Future<void>
                executeTransfer() async {
              if (isProcessing) {
                return;
              }

              final amountText =
                  amountController
                      .text
                      .trim()
                      .replaceAll(
                        ',',
                        '.',
                      );

              final amount =
                  double.tryParse(
                amountText,
              );

              if (amount ==
                      null ||
                  amount <= 0) {
                setDialogState(() {
                  localError =
                      'Veuillez saisir un montant valide.';
                });
                return;
              }

              if (amount >
                  sourceAccount
                      .balance) {
                setDialogState(() {
                  localError =
                      'Le solde disponible du compte source est insuffisant.';
                });
                return;
              }

              setDialogState(() {
                isProcessing =
                    true;
                localError =
                    null;
              });

              try {
                final response =
                    await _apiService
                        .post(
                  '/api/transactions/transfer',
                  body: {
                    'userId':
                        widget.userId,
                    'fromAccountNumber':
                        sourceAccount
                            .accountNumber,
                    'toAccountNumber':
                        destinationAccount
                            .accountNumber,
                    'amount':
                        amount,
                  },
                );

                if (response.statusCode <
                        200 ||
                    response.statusCode >=
                        300) {
                  throw Exception(
                    _apiService
                        .getErrorMessage(
                      response,
                    ),
                  );
                }

                if (!mounted) return;

                Navigator.of(
                  dialogContext,
                ).pop();

                // =================================================
                // RECHARGEMENT BACKEND
                //
                // Cette méthode met également à jour
                // MainNavigation grâce aux callbacks.
                // =================================================

                await _loadAccounts();

                if (!mounted) return;

                await _showTransferConfirmation(
                  amount:
                      amount,
                  currentToSavings:
                      currentToSavings,
                );
              } catch (e) {
                setDialogState(() {
                  isProcessing =
                      false;
                  localError =
                      _cleanErrorMessage(
                    e,
                  );
                });
              }
            }

            return AlertDialog(
              insetPadding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  24,
                ),
              ),
              titlePadding:
                  const EdgeInsets.fromLTRB(
                24,
                24,
                24,
                8,
              ),
              contentPadding:
                  const EdgeInsets.fromLTRB(
                24,
                10,
                24,
                10,
              ),
              actionsPadding:
                  const EdgeInsets.fromLTRB(
                24,
                4,
                24,
                20,
              ),
              title: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration:
                        BoxDecoration(
                      color:
                          _blue.withOpacity(
                        0.10,
                      ),
                      shape:
                          BoxShape.circle,
                    ),
                    child:
                        const Icon(
                      Icons
                          .swap_horiz_rounded,
                      color:
                          _blue,
                      size:
                          25,
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  const Expanded(
                    child: Text(
                      'Transférer entre mes comptes',
                      style:
                          TextStyle(
                        fontSize:
                            19,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content:
                  SingleChildScrollView(
                child:
                    Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Container(
                      width:
                          double.infinity,
                      padding:
                          const EdgeInsets.all(
                        14,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            widget.isDark
                                ? const Color(
                                    0xFF172033,
                                  )
                                : const Color(
                                    0xFFF1F5FA,
                                  ),
                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                      ),
                      child:
                          Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons
                                .info_outline_rounded,
                            color:
                                _blue,
                            size:
                                21,
                          ),
                          const SizedBox(
                            width:
                                10,
                          ),
                          Expanded(
                            child:
                                Text(
                              'Déplacez facilement de l’argent entre votre compte courant et votre compte épargne.',
                              style:
                                  TextStyle(
                                fontSize:
                                    13,
                                height:
                                    1.4,
                                color: widget.isDark
                                    ? Colors.white70
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child:
                              _buildTransferDirectionCard(
                            title:
                                'Courant',
                            subtitle:
                                '→ Épargne',
                            balance:
                                currentAccount
                                    .balance,
                            currency:
                                currentAccount
                                    .currency,
                            icon:
                                Icons
                                    .account_balance_wallet_rounded,
                            selected:
                                currentToSavings,
                            selectedColor:
                                _green,
                            onTap:
                                isProcessing
                                    ? null
                                    : () {
                                        setDialogState(() {
                                          currentToSavings =
                                              true;
                                          localError =
                                              null;
                                        });
                                      },
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child:
                              _buildTransferDirectionCard(
                            title:
                                'Épargne',
                            subtitle:
                                '→ Courant',
                            balance:
                                savingsAccount
                                    .balance,
                            currency:
                                savingsAccount
                                    .currency,
                            icon:
                                Icons
                                    .savings_rounded,
                            selected:
                                !currentToSavings,
                            selectedColor:
                                _lightGreen,
                            onTap:
                                isProcessing
                                    ? null
                                    : () {
                                        setDialogState(() {
                                          currentToSavings =
                                              false;
                                          localError =
                                              null;
                                        });
                                      },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    Container(
                      width:
                          double.infinity,
                      padding:
                          const EdgeInsets.all(
                        15,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            currentToSavings
                                ? _green.withOpacity(
                                    0.07,
                                  )
                                : Colors.grey.withOpacity(
                                    0.08,
                                  ),
                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                        border:
                            Border.all(
                          color:
                              currentToSavings
                                  ? _green.withOpacity(
                                      0.25,
                                    )
                                  : Colors.grey.withOpacity(
                                      0.25,
                                    ),
                        ),
                      ),
                      child:
                          Row(
                        children: [
                          Expanded(
                            child:
                                _transferAccountMiniInfo(
                              'Depuis',
                              sourceTitle,
                              sourceAccount
                                  .balance,
                              sourceAccount
                                  .currency,
                            ),
                          ),
                          const Icon(
                            Icons
                                .arrow_forward_rounded,
                            size:
                                22,
                            color:
                                Colors.grey,
                          ),
                          Expanded(
                            child:
                                _transferAccountMiniInfo(
                              'Vers',
                              destinationTitle,
                              destinationAccount
                                  .balance,
                              destinationAccount
                                  .currency,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    TextField(
                      controller:
                          amountController,
                      enabled:
                          !isProcessing,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal:
                            true,
                      ),
                      textInputAction:
                          TextInputAction.done,
                      decoration:
                          InputDecoration(
                        labelText:
                            'Montant à transférer',
                        hintText:
                            'Ex. 100.00',
                        prefixIcon:
                            const Icon(
                          Icons
                              .payments_outlined,
                        ),
                        suffixText:
                            'TND',
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                        enabledBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                          borderSide:
                              BorderSide(
                            color:
                                Colors.grey.withOpacity(
                              0.35,
                            ),
                          ),
                        ),
                        focusedBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                          borderSide:
                              BorderSide(
                            color:
                                currentToSavings
                                    ? _green
                                    : _blue,
                            width:
                                2,
                          ),
                        ),
                      ),
                    ),

                    if (localError !=
                        null) ...[
                      const SizedBox(
                        height: 12,
                      ),
                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets.all(
                          12,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.red.withOpacity(
                            0.08,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                        child:
                            Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons
                                  .error_outline,
                              color:
                                  Colors.red,
                              size:
                                  20,
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child:
                                  Text(
                                localError!,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.red,
                                  fontSize:
                                      13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isProcessing
                          ? null
                          : () {
                              Navigator.of(
                                dialogContext,
                              ).pop();
                            },
                  child:
                      const Text(
                    'Annuler',
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      isProcessing
                          ? null
                          : executeTransfer,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        currentToSavings
                            ? _green
                            : _blue,
                    foregroundColor:
                        Colors.white,
                    elevation:
                        0,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal:
                          22,
                      vertical:
                          13,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                  child:
                      isProcessing
                          ? const SizedBox(
                              width:
                                  20,
                              height:
                                  20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                                valueColor:
                                    AlwaysStoppedAnimation<
                                        Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Valider',
                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                ),
              ],
            );
          },
        );
      },
    );

    amountController.dispose();
  }

  // =========================================================
  // CARTE DIRECTION TRANSFERT
  // =========================================================

  Widget _buildTransferDirectionCard({
    required String title,
    required String subtitle,
    required double balance,
    required String currency,
    required IconData icon,
    required bool selected,
    required Color selectedColor,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child:
          AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 180,
        ),
        padding:
            const EdgeInsets.all(
          13,
        ),
        decoration:
            BoxDecoration(
          color:
              selected
                  ? selectedColor.withOpacity(
                      0.10,
                    )
                  : widget.isDark
                      ? const Color(
                          0xFF172033,
                        )
                      : Colors.white,
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          border:
              Border.all(
            color:
                selected
                    ? selectedColor
                    : widget.isDark
                        ? Colors.white12
                        : Colors.black12,
            width:
                selected
                    ? 2
                    : 1,
          ),
        ),
        child:
            Column(
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width:
                      38,
                  height:
                      38,
                  decoration:
                      BoxDecoration(
                    color:
                        selected
                            ? selectedColor
                            : Colors.grey.withOpacity(
                                0.12,
                              ),
                    borderRadius:
                        BorderRadius.circular(
                      11,
                    ),
                  ),
                  child:
                      Icon(
                    icon,
                    size:
                        20,
                    color:
                        selected
                            ? Colors.white
                            : Colors.grey,
                  ),
                ),
                if (selected)
                  Icon(
                    Icons
                        .check_circle_rounded,
                    color:
                        selectedColor,
                    size:
                        21,
                  ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              title,
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize:
                    14,
                fontWeight:
                    FontWeight.bold,
                color:
                    widget.isDark
                        ? Colors.white
                        : _darkBlue,
              ),
            ),
            const SizedBox(
              height: 2,
            ),
            Text(
              subtitle,
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize:
                    13,
                fontWeight:
                    FontWeight.w600,
                color:
                    selected
                        ? selectedColor
                        : Colors.grey,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              '${balance.toStringAsFixed(2)} $currency',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize:
                    12,
                color:
                    widget.isDark
                        ? Colors.white60
                        : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // MINI INFORMATIONS COMPTE
  // =========================================================

  Widget _transferAccountMiniInfo(
    String label,
    String accountName,
    double balance,
    String currency,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style:
              TextStyle(
            fontSize:
                11,
            color:
                widget.isDark
                    ? Colors.white54
                    : Colors.black45,
          ),
        ),
        const SizedBox(
          height: 3,
        ),
        Text(
          accountName,
          textAlign:
              TextAlign.center,
          style:
              TextStyle(
            fontSize:
                12,
            fontWeight:
                FontWeight.bold,
            color:
                widget.isDark
                    ? Colors.white
                    : _darkBlue,
          ),
        ),
        const SizedBox(
          height: 2,
        ),
        Text(
          '${balance.toStringAsFixed(2)} $currency',
          textAlign:
              TextAlign.center,
          style:
              TextStyle(
            fontSize:
                11,
            color:
                widget.isDark
                    ? Colors.white60
                    : Colors.black54,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // CONFIRMATION TRANSFERT
  // =========================================================

  Future<void>
      _showTransferConfirmation({
    required double amount,
    required bool currentToSavings,
  }) async {
    final Color green =
        _green;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (
        dialogContext,
      ) {
        if (currentToSavings) {
          return AlertDialog(
            backgroundColor:
                green,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                24,
              ),
            ),
            contentPadding:
                const EdgeInsets.fromLTRB(
              25,
              28,
              25,
              20,
            ),
            content:
                Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width:
                      72,
                  height:
                      72,
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white.withOpacity(
                      0.16,
                    ),
                    shape:
                        BoxShape.circle,
                  ),
                  child:
                      const Icon(
                    Icons.check_rounded,
                    color:
                        Colors.white,
                    size:
                        43,
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),
                const Text(
                  'Transfert réussi',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        22,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'Votre compte épargne a été crédité avec succès.',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        Colors.white70,
                    fontSize:
                        14,
                    height:
                        1.4,
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),
                Text(
                  '${amount.toStringAsFixed(2)} TND',
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        28,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                const Text(
                  'Courant → Épargne',
                  style:
                      TextStyle(
                    color:
                        Colors.white70,
                    fontSize:
                        13,
                  ),
                ),
                const SizedBox(
                  height: 22,
                ),
                SizedBox(
                  width:
                      double.infinity,
                  child:
                      ElevatedButton(
                    onPressed:
                        () {
                      Navigator.of(
                        dialogContext,
                      ).pop();
                    },
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.white,
                      foregroundColor:
                          green,
                      elevation:
                          0,
                      padding:
                          const EdgeInsets.symmetric(
                        vertical:
                            13,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          13,
                        ),
                      ),
                    ),
                    child:
                        const Text(
                      'Fermer',
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return AlertDialog(
          backgroundColor:
              widget.isDark
                  ? const Color(
                      0xFF172033,
                    )
                  : Colors.white,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              24,
            ),
            side:
                BorderSide(
              color:
                  green,
              width:
                  1.5,
            ),
          ),
          contentPadding:
              const EdgeInsets.fromLTRB(
            25,
            28,
            25,
            20,
          ),
          content:
              Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Container(
                width:
                    72,
                height:
                    72,
                decoration:
                    BoxDecoration(
                  color:
                      green.withOpacity(
                    0.10,
                  ),
                  shape:
                      BoxShape.circle,
                ),
                child:
                    Icon(
                  Icons.check_rounded,
                  color:
                      green,
                  size:
                      43,
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              Text(
                'Transfert réussi',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  color:
                      widget.isDark
                          ? Colors.white
                          : _darkBlue,
                  fontSize:
                      22,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                'Votre compte courant a été crédité avec succès.',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  color:
                      widget.isDark
                          ? Colors.white70
                          : Colors.black54,
                  fontSize:
                      14,
                  height:
                      1.4,
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              Text(
                '${amount.toStringAsFixed(2)} TND',
                style:
                    TextStyle(
                  color:
                      green,
                  fontSize:
                      28,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              Text(
                'Épargne → Courant',
                style:
                    TextStyle(
                  color:
                      widget.isDark
                          ? Colors.white60
                          : Colors.black54,
                  fontSize:
                      13,
                ),
              ),
              const SizedBox(
                height: 22,
              ),
              SizedBox(
                width:
                    double.infinity,
                child:
                    ElevatedButton(
                  onPressed:
                      () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        green,
                    foregroundColor:
                        Colors.white,
                    elevation:
                        0,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical:
                          13,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        13,
                      ),
                    ),
                  ),
                  child:
                      const Text(
                    'Fermer',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(message),
        backgroundColor:
            isError
                ? Colors.red.shade700
                : _green,
        behavior:
            SnackBarBehavior.floating,
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
  // DÉTAILS COMPTE
  // =========================================================

  Future<void>
      _showAccountDetails(
    Account account,
  ) async {
    Timer? timer;

    final future =
        showDialog<void>(
      context: context,
      barrierDismissible:
          true,
      builder: (
        dialogContext,
      ) {
        timer = Timer(
          const Duration(
            seconds: 8,
          ),
          () {
            if (Navigator.of(
              dialogContext,
            ).canPop()) {
              Navigator.of(
                dialogContext,
              ).pop();
            }
          },
        );

        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),
          title:
              Row(
            children: [
              Container(
                width:
                    44,
                height:
                    44,
                decoration:
                    BoxDecoration(
                  color:
                      _blue.withOpacity(
                    0.10,
                  ),
                  shape:
                      BoxShape.circle,
                ),
                child:
                    const Icon(
                  Icons
                      .account_balance_rounded,
                  color:
                      _blue,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child:
                    Text(
                  account.accountType
                              .trim()
                              .toUpperCase() ==
                          'CURRENT'
                      ? 'Compte courant'
                      : 'Compte épargne',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content:
              Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              _detailRow(
                'Numéro de compte',
                account.accountNumber,
              ),
              const Divider(
                height: 24,
              ),
              _detailRow(
                'Solde',
                account.formattedBalance,
              ),
              const Divider(
                height: 24,
              ),
              _detailRow(
                'Devise',
                account.currency,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed:
                  () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child:
                  const Text(
                'Fermer',
              ),
            ),
          ],
        );
      },
    );

    await future;
    timer?.cancel();
  }

  Widget _detailRow(
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          child:
              Text(
            label,
            style:
                TextStyle(
              color:
                  widget.isDark
                      ? Colors.white70
                      : Colors.black54,
            ),
          ),
        ),
        const SizedBox(
          width: 12,
        ),
        Flexible(
          child:
              Text(
            value,
            textAlign:
                TextAlign.end,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // CARTE COMPTE
  // =========================================================

  Widget _buildAccountCard(
    Account account,
  ) {
    final isCurrent =
        account.accountType
                .trim()
                .toUpperCase() ==
            'CURRENT';

    final Color cardColor =
        isCurrent
            ? _darkBlue
            : _blue;

    final String title =
        isCurrent
            ? 'Compte courant'
            : 'Compte épargne';

    final IconData icon =
        isCurrent
            ? Icons
                .account_balance_wallet_rounded
            : Icons
                .savings_rounded;

    return GestureDetector(
      onTap:
          () => _showAccountDetails(
        account,
      ),
      child:
          Container(
        width:
            double.infinity,
        margin:
            const EdgeInsets.only(
          bottom: 18,
        ),
        padding:
            const EdgeInsets.all(
          22,
        ),
        decoration:
            BoxDecoration(
          color:
              cardColor,
          borderRadius:
              BorderRadius.circular(
            24,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius:
                  16,
              offset:
                  const Offset(
                0,
                8,
              ),
              color:
                  Colors.black.withOpacity(
                0.12,
              ),
            ),
          ],
        ),
        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width:
                      46,
                  height:
                      46,
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white.withOpacity(
                      0.14,
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
                        Colors.white,
                    size:
                        24,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize:
                              18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        account.accountNumber,
                        style:
                            TextStyle(
                          color:
                              Colors.white.withOpacity(
                            0.72,
                          ),
                          fontSize:
                              12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons
                      .chevron_right_rounded,
                  color:
                      Colors.white70,
                ),
              ],
            ),
            const SizedBox(
              height: 30,
            ),
            Text(
              'Solde disponible',
              style:
                  TextStyle(
                color:
                    Colors.white.withOpacity(
                  0.72,
                ),
                fontSize:
                    13,
              ),
            ),
            const SizedBox(
              height: 7,
            ),
            Text(
              account.formattedBalance,
              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontSize:
                    29,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal:
                        10,
                    vertical:
                        6,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white.withOpacity(
                      0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                  child:
                      Text(
                    account.currency,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize:
                          12,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Voir les détails',
                  style:
                      TextStyle(
                    color:
                        Colors.white.withOpacity(
                      0.82,
                    ),
                    fontSize:
                        12,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // SECTION INTÉRÊTS
  // =========================================================

  Widget _buildInterestSection() {
    final savingsAccount =
        _findAccountByType(
      'SAVINGS',
    );

    final savingsBalance =
        savingsAccount?.balance ??
            0.0;

    final estimatedInterest =
        savingsBalance * 0.02;

    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        20,
      ),
      decoration:
          BoxDecoration(
        color:
            widget.isDark
                ? const Color(
                    0xFF172033,
                  )
                : Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border:
            Border.all(
          color:
              widget.isDark
                  ? Colors.white10
                  : Colors.black.withOpacity(
                      0.06,
                    ),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius:
                12,
            offset:
                const Offset(
              0,
              5,
            ),
            color:
                Colors.black.withOpacity(
              0.05,
            ),
          ),
        ],
      ),
      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width:
                48,
            height:
                48,
            decoration:
                BoxDecoration(
              color:
                  _green.withOpacity(
                0.10,
              ),
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child:
                const Icon(
              Icons
                  .trending_up_rounded,
              color:
                  _green,
            ),
          ),
          const SizedBox(
            width: 14,
          ),
          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Épargne',
                  style:
                      TextStyle(
                    fontSize:
                        16,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        widget.isDark
                            ? Colors.white
                            : _darkBlue,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  'Taux indicatif annuel : 2,0 %',
                  style:
                      TextStyle(
                    fontSize:
                        12,
                    color:
                        widget.isDark
                            ? Colors.white60
                            : Colors.black54,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  'Intérêts estimés : '
                  '${estimatedInterest.toStringAsFixed(2)} TND',
                  style:
                      const TextStyle(
                    color:
                        _green,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Mes comptes',
                style:
                    TextStyle(
                  fontSize:
                      27,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      widget.isDark
                          ? Colors.white
                          : _darkBlue,
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              Text(
                'Gérez vos comptes et consultez vos soldes.',
                style:
                    TextStyle(
                  fontSize:
                      13,
                  color:
                      widget.isDark
                          ? Colors.white60
                          : Colors.black54,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip:
              'Actualiser',
          onPressed:
              _isLoading
                  ? null
                  : _loadAccounts,
          icon:
              const Icon(
            Icons
                .refresh_rounded,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // TOTAL
  // =========================================================

  Widget _buildTotalBalance() {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        20,
      ),
      margin:
          const EdgeInsets.only(
        top: 20,
        bottom: 22,
      ),
      decoration:
          BoxDecoration(
        color:
            widget.isDark
                ? const Color(
                    0xFF172033,
                  )
                : const Color(
                    0xFFEFF4FB,
                  ),
        borderRadius:
            BorderRadius.circular(
          20,
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
                  _blue.withOpacity(
                0.10,
              ),
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child:
                const Icon(
              Icons
                  .account_balance_rounded,
              color:
                  _blue,
            ),
          ),
          const SizedBox(
            width: 14,
          ),
          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Solde total',
                  style:
                      TextStyle(
                    fontSize:
                        13,
                    color:
                        widget.isDark
                            ? Colors.white60
                            : Colors.black54,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  '${_totalBalance.toStringAsFixed(2)} TND',
                  style:
                      TextStyle(
                    fontSize:
                        23,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        widget.isDark
                            ? Colors.white
                            : _darkBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BOUTON TRANSFERT
  // =========================================================

  Widget _buildTransferButton() {
    final hasCurrent =
        _findAccountByType(
              'CURRENT',
            ) !=
            null;

    final hasSavings =
        _findAccountByType(
              'SAVINGS',
            ) !=
            null;

    if (!hasCurrent ||
        !hasSavings) {
      return const SizedBox
          .shrink();
    }

    return SizedBox(
      width:
          double.infinity,
      height:
          54,
      child:
          ElevatedButton.icon(
        onPressed:
            _showTransferDialog,
        icon:
            const Icon(
          Icons
              .swap_horiz_rounded,
        ),
        label:
            const Text(
          'Transférer entre mes comptes',
          style:
              TextStyle(
            fontWeight:
                FontWeight.w600,
          ),
        ),
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              _darkBlue,
          foregroundColor:
              Colors.white,
          elevation:
              0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // ERROR
  // =========================================================

  Widget _buildError() {
    return Center(
      child:
          Padding(
        padding:
            const EdgeInsets.all(
          30,
        ),
        child:
            Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width:
                  70,
              height:
                  70,
              decoration:
                  BoxDecoration(
                color:
                    Colors.red.withOpacity(
                  0.08,
                ),
                shape:
                    BoxShape.circle,
              ),
              child:
                  const Icon(
                Icons
                    .cloud_off_rounded,
                color:
                    Colors.red,
                size:
                    34,
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            Text(
              'Impossible de charger les comptes',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize:
                    18,
                fontWeight:
                    FontWeight.bold,
                color:
                    widget.isDark
                        ? Colors.white
                        : _darkBlue,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              _errorMessage ??
                  'Une erreur est survenue.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    widget.isDark
                        ? Colors.white60
                        : Colors.black54,
                fontSize:
                    13,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton.icon(
              onPressed:
                  _loadAccounts,
              icon:
                  const Icon(
                Icons
                    .refresh_rounded,
              ),
              label:
                  const Text(
                'Réessayer',
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    _darkBlue,
                foregroundColor:
                    Colors.white,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // LOADING
  // =========================================================

  Widget _buildLoading() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.all(
        20,
      ),
      children: [
        Container(
          height:
              45,
          width:
              180,
          decoration:
              BoxDecoration(
            color:
                Colors.grey.withOpacity(
              0.15,
            ),
            borderRadius:
                BorderRadius.circular(
              10,
            ),
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        Container(
          height:
              100,
          decoration:
              BoxDecoration(
            color:
                Colors.grey.withOpacity(
              0.15,
            ),
            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),
        ),
        const SizedBox(
          height: 18,
        ),
        Container(
          height:
              220,
          decoration:
              BoxDecoration(
            color:
                Colors.grey.withOpacity(
              0.15,
            ),
            borderRadius:
                BorderRadius.circular(
              24,
            ),
          ),
        ),
        const SizedBox(
          height: 18,
        ),
        Container(
          height:
              220,
          decoration:
              BoxDecoration(
            color:
                Colors.grey.withOpacity(
              0.15,
            ),
            borderRadius:
                BorderRadius.circular(
              24,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final backgroundColor =
        widget.isDark
            ? const Color(
                0xFF0D1422,
              )
            : _lightBackground;

    return Scaffold(
      backgroundColor:
          backgroundColor,
      body:
          SafeArea(
        child:
            _isLoading
                ? _buildLoading()
                : _errorMessage !=
                        null
                    ? RefreshIndicator(
                        onRefresh:
                            _loadAccounts,
                        child:
                            ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height *
                                      0.65,
                              child:
                                  _buildError(),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh:
                            _loadAccounts,
                        child:
                            ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(
                            20,
                            20,
                            20,
                            30,
                          ),
                          children: [
                            _buildHeader(),
                            _buildTotalBalance(),
                            if (_accounts.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(
                                  vertical:
                                      50,
                                ),
                                child:
                                    Column(
                                  children: [
                                    Icon(
                                      Icons
                                          .account_balance_wallet_outlined,
                                      size:
                                          60,
                                      color:
                                          widget.isDark
                                              ? Colors.white30
                                              : Colors.black26,
                                    ),
                                    const SizedBox(
                                      height:
                                          15,
                                    ),
                                    Text(
                                      'Aucun compte disponible.',
                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight.w600,
                                        color:
                                            widget.isDark
                                                ? Colors.white70
                                                : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else ...[
                              ..._accounts.map(
                                _buildAccountCard,
                              ),
                              const SizedBox(
                                height:
                                    2,
                              ),
                              _buildTransferButton(),
                              const SizedBox(
                                height:
                                    22,
                              ),
                              _buildInterestSection(),
                            ],
                          ],
                        ),
                      ),
      ),
    );
  }
}