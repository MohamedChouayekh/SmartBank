import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/account.dart';

class AccountsScreen extends StatefulWidget {
  final int userId;
  final double courantBalance;
  final double epargneBalance;

  final ValueChanged<double>? onCourantBalanceChanged;
  final ValueChanged<double>? onEpargneBalanceChanged;

  const AccountsScreen({
    super.key,
    required this.userId,
    this.courantBalance = 0.0,
    this.epargneBalance = 0.0,
    this.onCourantBalanceChanged,
    this.onEpargneBalanceChanged,
  });

  @override
  State<AccountsScreen> createState() =>
      _AccountsScreenState();
}

class _AccountsScreenState
    extends State<AccountsScreen> {
  static const String baseUrl =
      'http://192.168.1.155:8080';

  static const Color blue =
      Color(0xFF0B5AA6);

  static const Color darkBlue =
      Color(0xFF06457E);

  static const Color green =
      Color(0xFF087A5B);

  static const double interestRate =
      0.02;

  bool _isLoading = true;
  bool _isTransferring = false;

  String? _courantAccountNumber;
  String? _epargneAccountNumber;

  double _courant = 0.0;
  double _epargne = 0.0;

  @override
  void initState() {
    super.initState();

    _courant = widget.courantBalance;
    _epargne = widget.epargneBalance;

    _loadAccounts();
  }

  @override
  void didUpdateWidget(
    covariant AccountsScreen oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.userId != widget.userId) {
      _loadAccounts();
      return;
    }

    if (oldWidget.courantBalance !=
            widget.courantBalance &&
        widget.courantBalance != _courant) {
      setState(() {
        _courant = widget.courantBalance;
      });
    }

    if (oldWidget.epargneBalance !=
            widget.epargneBalance &&
        widget.epargneBalance != _epargne) {
      setState(() {
        _epargne = widget.epargneBalance;
      });
    }
  }

  // =========================================================
  // CHARGEMENT
  // =========================================================

  Future<void> _loadAccounts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/api/accounts/user/${widget.userId}',
            ),
          )
          .timeout(
            const Duration(seconds: 10),
          );

      if (!mounted) return;

      if (response.statusCode != 200) {
        throw Exception(
          'Impossible de récupérer les comptes.',
        );
      }

      final decoded =
          jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception(
          'Réponse des comptes invalide.',
        );
      }

      String? courantNumber;
      String? epargneNumber;

      double courantBalance = 0.0;
      double epargneBalance = 0.0;

      for (final item in decoded) {
        if (item is! Map) continue;

        final map =
            Map<String, dynamic>.from(item);

        final type =
            (map['type'] ?? '')
                .toString()
                .trim()
                .toUpperCase();

        final number =
            (map['accountNumber'] ?? '')
                .toString()
                .trim();

        final rawBalance =
            map['balance'];

        final balance =
            rawBalance is num
                ? rawBalance.toDouble()
                : double.tryParse(
                      rawBalance?.toString() ??
                          '',
                    ) ??
                    0.0;

        if (type == 'CURRENT') {
          courantBalance = balance;
          courantNumber = number;
        } else if (type == 'SAVINGS') {
          epargneBalance = balance;
          epargneNumber = number;
        }
      }

      if (!mounted) return;

      setState(() {
        _courant = courantBalance;
        _epargne = epargneBalance;
        _courantAccountNumber =
            courantNumber;
        _epargneAccountNumber =
            epargneNumber;
        _isLoading = false;
      });

      widget.onCourantBalanceChanged
          ?.call(courantBalance);

      widget.onEpargneBalanceChanged
          ?.call(epargneBalance);
    } catch (e) {
      debugPrint(
        'Erreur chargement comptes : $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de charger vos comptes.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // COPIER
  // =========================================================

  Future<void> _copyAccountNumber(
    String number,
    String title,
  ) async {
    if (number.trim().isEmpty) return;

    await Clipboard.setData(
      ClipboardData(text: number),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text('$title copié.'),
        behavior:
            SnackBarBehavior.floating,
        margin:
            const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
      ),
    );
  }

  // =========================================================
  // NUMÉRO COMPTE
  // =========================================================

  Widget _buildAccountNumberCard({
    required String title,
    required String? accountNumber,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    final number =
        accountNumber?.trim() ?? '';

    final hasNumber = number.isNotEmpty;

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(bottom: 18),
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF182236)
            : Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(
            alpha: 0.12,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark
                  ? 0.16
                  : 0.045,
            ),
            blurRadius: 12,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration:
                BoxDecoration(
              color:
                  color.withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  hasNumber
                      ? number
                      : 'Numéro indisponible',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                    letterSpacing:
                        0.4,
                    color:
                        hasNumber
                            ? null
                            : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip:
                'Copier le numéro',
            onPressed: hasNumber
                ? () {
                    _copyAccountNumber(
                      number,
                      title,
                    );
                  }
                : null,
            icon:
                const Icon(
              Icons.copy_outlined,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CARTE COMPTE
  // =========================================================

  Widget _buildPremiumAccountCard({
    required String title,
    required String number,
    required double balance,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            color,
            color.withValues(
              alpha: 0.76,
            ),
          ],
        ),
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color:
                color.withValues(
              alpha: 0.24,
            ),
            blurRadius: 20,
            offset:
                const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -45,
            child:
                Container(
              width: 145,
              height: 145,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color:
                    Colors.white.withValues(
                  alpha: 0.06,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        13,
                      ),
                    ),
                    child:
                        Icon(
                      icon,
                      color:
                          Colors.white,
                      size: 23,
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          title,
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize:
                                16,
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          number.isEmpty
                              ? 'Compte SmartBank'
                              : number,
                          style:
                              TextStyle(
                            color:
                                Colors.white
                                    .withValues(
                              alpha:
                                  0.72,
                            ),
                            fontSize:
                                11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 24,
              ),
              Text(
                'Solde disponible',
                style:
                    TextStyle(
                  color:
                      Colors.white.withValues(
                    alpha: 0.72,
                  ),
                  fontSize: 12,
                ),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                '${balance.toStringAsFixed(3)} TND',
                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontSize:
                      29,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DIALOGUE TRANSFERT INTERNE
  // =========================================================

  Future<void> _executeInternalTransfer({
    required String fromAccountNumber,
    required String toAccountNumber,
    required double amount,
    required String label,
  }) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/api/transactions/transfer',
      ),
      headers: {
        'Content-Type':
            'application/json',
      },
      body: jsonEncode({
        'fromAccountNumber':
            fromAccountNumber,
        'toAccountNumber':
            toAccountNumber,
        'amount': amount,
        'label': label,
      }),
    );

    Map<String, dynamic> data = {};

    try {
      final decoded =
          jsonDecode(response.body);

      if (decoded
          is Map<String, dynamic>) {
        data = decoded;
      }
    } catch (_) {}

    if (response.statusCode != 200) {
      throw Exception(
        (data['message'] ??
                'Impossible d’effectuer le virement.')
            .toString(),
      );
    }
  }

  void _showInternalTransferDialog() {
    if (_courantAccountNumber ==
            null ||
        _epargneAccountNumber ==
            null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Vous devez avoir un compte courant et un compte épargne.',
          ),
          backgroundColor:
              Colors.orange,
        ),
      );
      return;
    }

    final amountController =
        TextEditingController();

    bool fromCourantToEpargne =
        true;

    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            final theme =
                Theme.of(context);

            final isDark =
                theme.brightness ==
                    Brightness.dark;

            final sourceBalance =
                fromCourantToEpargne
                    ? _courant
                    : _epargne;

            final destinationBalance =
                fromCourantToEpargne
                    ? _epargne
                    : _courant;

            final accent =
                fromCourantToEpargne
                    ? const Color(
                        0xFF087A5B,
                      )
                    : const Color(
                        0xFF32B67A,
                      );

            return AlertDialog(
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  22,
                ),
              ),
              title:
                  Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration:
                        BoxDecoration(
                      color:
                          accent.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    child:
                        Icon(
                      Icons
                          .swap_horiz_rounded,
                      color:
                          accent,
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  const Expanded(
                    child: Text(
                      'Virement entre mes comptes',
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
                        13,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            isDark
                                ? const Color(
                                    0xFF182236,
                                  )
                                : const Color(
                                    0xFFF2F7FC,
                                  ),
                        borderRadius:
                            BorderRadius.circular(
                          13,
                        ),
                      ),
                      child:
                          Text(
                        'Transférez de l’argent entre votre compte courant et votre compte épargne.',
                        style:
                            TextStyle(
                          fontSize:
                              12.5,
                          color:
                              isDark
                                  ? Colors.white70
                                  : const Color(
                                      0xFF476579,
                                    ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child:
                              ChoiceChip(
                            label:
                                const Text(
                              'Courant → Épargne',
                              style:
                                  TextStyle(
                                fontSize:
                                    11,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                            selected:
                                fromCourantToEpargne,
                            selectedColor:
                                const Color(
                                  0xFF087A5B,
                                ).withValues(
                              alpha:
                                  0.16,
                            ),
                            onSelected:
                                isSubmitting
                                    ? null
                                    : (selected) {
                                        if (selected) {
                                          setDialogState(() {
                                            fromCourantToEpargne =
                                                true;
                                          });
                                        }
                                      },
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          child:
                              ChoiceChip(
                            label:
                                const Text(
                              'Épargne → Courant',
                              style:
                                  TextStyle(
                                fontSize:
                                    11,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                            selected:
                                !fromCourantToEpargne,
                            selectedColor:
                                const Color(
                                  0xFF32B67A,
                                ).withValues(
                              alpha:
                                  0.16,
                            ),
                            onSelected:
                                isSubmitting
                                    ? null
                                    : (selected) {
                                        if (selected) {
                                          setDialogState(() {
                                            fromCourantToEpargne =
                                                false;
                                          });
                                        }
                                      },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    _buildTransferAccountBox(
                      title:
                          'Compte source',
                      accountName:
                          fromCourantToEpargne
                              ? 'Compte courant'
                              : 'Compte épargne',
                      accountNumber:
                          fromCourantToEpargne
                              ? _courantAccountNumber!
                              : _epargneAccountNumber!,
                      balance:
                          sourceBalance,
                      color:
                          accent,
                      isDark:
                          isDark,
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    _buildTransferAccountBox(
                      title:
                          'Compte destination',
                      accountName:
                          fromCourantToEpargne
                              ? 'Compte épargne'
                              : 'Compte courant',
                      accountNumber:
                          fromCourantToEpargne
                              ? _epargneAccountNumber!
                              : _courantAccountNumber!,
                      balance:
                          destinationBalance,
                      color:
                          isDark
                              ? Colors.white54
                              : Colors.grey,
                      isDark:
                          isDark,
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    TextField(
                      controller:
                          amountController,
                      enabled:
                          !isSubmitting,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal:
                            true,
                      ),
                      decoration:
                          InputDecoration(
                        labelText:
                            'Montant (TND)',
                        prefixIcon:
                            const Icon(
                          Icons
                              .payments_outlined,
                        ),
                        filled:
                            true,
                        fillColor:
                            isDark
                                ? const Color(
                                    0xFF182236,
                                  )
                                : const Color(
                                    0xFFF8FAFC,
                                  ),
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                          borderSide:
                              BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSubmitting
                          ? null
                          : () {
                              Navigator.pop(
                                dialogContext,
                              );
                            },
                  child:
                      const Text(
                    'Annuler',
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      isSubmitting
                          ? null
                          : () async {
                              final amount =
                                  double.tryParse(
                                amountController
                                    .text
                                    .trim()
                                    .replaceAll(
                                      ',',
                                      '.',
                                    ),
                              );

                              if (amount ==
                                      null ||
                                  amount <=
                                      0) {
                                ScaffoldMessenger
                                        .of(
                                  context,
                                )
                                    .showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text(
                                      'Veuillez saisir un montant valide.',
                                    ),
                                    backgroundColor:
                                        Colors.red,
                                  ),
                                );
                                return;
                              }

                              if (amount >
                                  sourceBalance) {
                                ScaffoldMessenger
                                        .of(
                                  context,
                                )
                                    .showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text(
                                      'Solde insuffisant.',
                                    ),
                                    backgroundColor:
                                        Colors.red,
                                  ),
                                );
                                return;
                              }

                              setDialogState(() {
                                isSubmitting =
                                    true;
                              });

                              setState(() {
                                _isTransferring =
                                    true;
                              });

                              try {
                                await _executeInternalTransfer(
                                  fromAccountNumber:
                                      fromCourantToEpargne
                                          ? _courantAccountNumber!
                                          : _epargneAccountNumber!,
                                  toAccountNumber:
                                      fromCourantToEpargne
                                          ? _epargneAccountNumber!
                                          : _courantAccountNumber!,
                                  amount:
                                      amount,
                                  label:
                                      fromCourantToEpargne
                                          ? 'Virement vers compte épargne'
                                          : 'Virement vers compte courant',
                                );

                                await _loadAccounts();

                                if (!mounted)
                                  return;

                                Navigator.pop(
                                  dialogContext,
                                );

                                ScaffoldMessenger
                                        .of(
                                  context,
                                )
                                    .showSnackBar(
                                  SnackBar(
                                    content:
                                        Text(
                                      'Virement de ${amount.toStringAsFixed(3)} TND effectué avec succès.',
                                    ),
                                    backgroundColor:
                                        accent,
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
                              } catch (e) {
                                if (!mounted)
                                  return;

                                setDialogState(() {
                                  isSubmitting =
                                      false;
                                });

                                ScaffoldMessenger
                                        .of(
                                  context,
                                )
                                    .showSnackBar(
                                  SnackBar(
                                    content:
                                        Text(
                                      e.toString().replaceFirst(
                                            'Exception: ',
                                            '',
                                          ),
                                    ),
                                    backgroundColor:
                                        Colors.red,
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isTransferring =
                                        false;
                                  });
                                }
                              }
                            },
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        accent,
                    foregroundColor:
                        Colors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                  child:
                      isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                                color:
                                    Colors.white,
                              ),
                            )
                          : const Text(
                              'Valider',
                            ),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(
      amountController.dispose,
    );
  }

  Widget _buildTransferAccountBox({
    required String title,
    required String accountName,
    required String accountNumber,
    required double balance,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(13),
      decoration:
          BoxDecoration(
        color: isDark
            ? const Color(0xFF182236)
            : const Color(0xFFF8FAFC),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              color.withValues(
            alpha: 0.15,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: color,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      TextStyle(
                    fontSize: 11,
                    color:
                        isDark
                            ? Colors.white54
                            : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  accountName,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  accountNumber,
                  style:
                      TextStyle(
                    fontSize: 11,
                    color:
                        isDark
                            ? Colors.white54
                            : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  'Solde : ${balance.toStringAsFixed(3)} TND',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                    fontSize:
                        12,
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

    final currentAccount =
        Account(
      id: 1,
      accountNumber:
          _courantAccountNumber ??
              'Chargement...',
      accountType:
          'Compte courant',
      balance:
          _courant,
      currency:
          'TND',
    );

    final savingsAccount =
        Account(
      id: 2,
      accountNumber:
          _epargneAccountNumber ??
              'Chargement...',
      accountType:
          'Compte épargne',
      balance:
          _epargne,
      currency:
          'TND',
    );

    final annualInterest =
        _epargne * interestRate;

    final monthlyInterest =
        annualInterest / 12;

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
          'Mes comptes',
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
                        _isTransferring
                    ? null
                    : _loadAccounts,
            icon:
                const Icon(
              Icons.refresh_rounded,
            ),
          ),
          const SizedBox(
            width: 6,
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
                      _loadAccounts,
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
                        Text(
                          'Mes comptes bancaires',
                          style:
                              theme.textTheme.headlineSmall?.copyWith(
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        Text(
                          'Consultez vos soldes, vos comptes et votre épargne.',
                          style:
                              theme.textTheme.bodyMedium?.copyWith(
                            color:
                                theme.textTheme.bodyMedium?.color?.withValues(
                              alpha:
                                  0.68,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),

                        // ------------------------------------
                        // TRANSFERT
                        // ------------------------------------

                        SizedBox(
                          width:
                              double.infinity,
                          height:
                              54,
                          child:
                              ElevatedButton.icon(
                            onPressed:
                                _isTransferring
                                    ? null
                                    : _showInternalTransferDialog,
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
                                    FontWeight.w700,
                              ),
                            ),
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  blue,
                              foregroundColor:
                                  Colors.white,
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

                        const SizedBox(
                          height: 24,
                        ),

                        _buildPremiumAccountCard(
                          title:
                              'Compte courant',
                          number:
                              currentAccount.accountNumber,
                          balance:
                              _courant,
                          icon:
                              Icons
                                  .account_balance_outlined,
                          color:
                              blue,
                          isDark:
                              isDark,
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        _buildAccountNumberCard(
                          title:
                              'Numéro du compte courant',
                          accountNumber:
                              _courantAccountNumber,
                          icon:
                              Icons
                                  .account_balance_outlined,
                          color:
                              blue,
                          isDark:
                              isDark,
                        ),

                        _buildPremiumAccountCard(
                          title:
                              'Compte épargne',
                          number:
                              savingsAccount.accountNumber,
                          balance:
                              _epargne,
                          icon:
                              Icons
                                  .savings_outlined,
                          color:
                              green,
                          isDark:
                              isDark,
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        _buildAccountNumberCard(
                          title:
                              'Numéro du compte épargne',
                          accountNumber:
                              _epargneAccountNumber,
                          icon:
                              Icons
                                  .savings_outlined,
                          color:
                              green,
                          isDark:
                              isDark,
                        ),

                        // ------------------------------------
                        // RENDEMENT
                        // ------------------------------------

                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets.all(
                            18,
                          ),
                          margin:
                              const EdgeInsets.only(
                            bottom: 16,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                isDark
                                    ? const Color(
                                        0xFF182236,
                                      )
                                    : Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                              18,
                            ),
                            border:
                                Border.all(
                              color:
                                  green.withValues(
                                alpha:
                                    0.12,
                              ),
                            ),
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
                                        40,
                                    height:
                                        40,
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          green.withValues(
                                        alpha:
                                            0.10,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(
                                        12,
                                      ),
                                    ),
                                    child:
                                        const Icon(
                                      Icons
                                          .trending_up_rounded,
                                      color:
                                          green,
                                    ),
                                  ),
                                  const SizedBox(
                                    width:
                                        11,
                                  ),
                                  const Expanded(
                                    child:
                                        Text(
                                      'Rendement Épargne',
                                      style:
                                          TextStyle(
                                        fontSize:
                                            16,
                                        fontWeight:
                                            FontWeight.w800,
                                      ),
                                    ),
                                  ),
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
                                          green.withValues(
                                        alpha:
                                            0.10,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(
                                        10,
                                      ),
                                    ),
                                    child:
                                        const Text(
                                      '2,0 % / an',
                                      style:
                                          TextStyle(
                                        color:
                                            green,
                                        fontWeight:
                                            FontWeight.w800,
                                        fontSize:
                                            11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height:
                                    17,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Intérêts estimés',
                                    style:
                                        TextStyle(
                                      color:
                                          isDark
                                              ? Colors.white70
                                              : Colors.grey.shade700,
                                      fontSize:
                                          13,
                                    ),
                                  ),
                                  Text(
                                    '+${annualInterest.toStringAsFixed(2)} TND',
                                    style:
                                        const TextStyle(
                                      color:
                                          green,
                                      fontWeight:
                                          FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height:
                                    7,
                              ),
                              Text(
                                '≈ ${monthlyInterest.toStringAsFixed(2)} TND / mois',
                                style:
                                    TextStyle(
                                  color:
                                      isDark
                                          ? Colors.white54
                                          : Colors.grey.shade600,
                                  fontSize:
                                      11.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ------------------------------------
                        // INFO
                        // ------------------------------------

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
                                        0xFF221F16,
                                      )
                                    : const Color(
                                        0xFFFFF8E7,
                                      ),
                            borderRadius:
                                BorderRadius.circular(
                              18,
                            ),
                            border:
                                Border.all(
                              color:
                                  const Color(
                                0xFFF4C542,
                              ).withValues(
                                alpha:
                                    0.30,
                              ),
                            ),
                          ),
                          child:
                              Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Container(
                                width:
                                    38,
                                height:
                                    38,
                                decoration:
                                    const BoxDecoration(
                                  color:
                                      Color(
                                    0xFFF4C542,
                                  ),
                                  shape:
                                      BoxShape.circle,
                                ),
                                child:
                                    const Icon(
                                  Icons
                                      .lightbulb_outline_rounded,
                                  color:
                                      darkBlue,
                                  size:
                                      20,
                                ),
                              ),
                              const SizedBox(
                                width:
                                    11,
                              ),
                              Expanded(
                                child:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Virement entre vos comptes',
                                      style:
                                          TextStyle(
                                        color:
                                            isDark
                                                ? const Color(
                                                    0xFFF7D96A,
                                                  )
                                                : const Color(
                                                    0xFF765B00,
                                                  ),
                                        fontWeight:
                                            FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(
                                      height:
                                          5,
                                    ),
                                    Text(
                                      'Le transfert interne permet de déplacer votre argent entre le compte courant et le compte épargne.',
                                      style:
                                          TextStyle(
                                        color:
                                            isDark
                                                ? Colors.white70
                                                : const Color(
                                                    0xFF765B00,
                                                  ),
                                        fontSize:
                                            12,
                                        height:
                                            1.35,
                                      ),
                                    ),
                                  ],
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
}