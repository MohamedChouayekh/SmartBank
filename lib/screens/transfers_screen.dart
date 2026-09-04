import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TransferRecord {
  final int id;
  final String beneficiary;
  final String beneficiaryAccountNumber;
  final double amount;
  final DateTime date;
  final bool isIncoming;

  TransferRecord({
    required this.id,
    required this.beneficiary,
    required this.beneficiaryAccountNumber,
    required this.amount,
    required this.date,
    required this.isIncoming,
  });
}

class OwnedAccount {
  final int id;
  final String accountNumber;
  final String type;
  final double balance;

  OwnedAccount({
    required this.id,
    required this.accountNumber,
    required this.type,
    required this.balance,
  });

  factory OwnedAccount.fromJson(Map<String, dynamic> json) {
    return OwnedAccount(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      accountNumber: (json['accountNumber'] ?? '').toString().trim(),
      type: (json['type'] ?? '').toString().trim().toUpperCase(),
      balance: json['balance'] is num
          ? (json['balance'] as num).toDouble()
          : double.tryParse(
                (json['balance'] ?? '0').toString(),
              ) ??
              0.0,
    );
  }

  String get displayType {
    if (type == 'CURRENT') {
      return 'Compte courant';
    }

    if (type == 'SAVINGS') {
      return 'Compte épargne';
    }

    return type.isEmpty ? 'Compte' : type;
  }
}

class TransfersScreen extends StatefulWidget {
  final int userId;
  final double courantBalance;
  final double epargneBalance;
  final List<TransferRecord> transferHistory;

  final Function(
    double newCourant,
    double newEpargne,
    TransferRecord newRecord,
  )? onBalancesUpdated;

  const TransfersScreen({
    super.key,
    required this.userId,
    this.courantBalance = 0.0,
    this.epargneBalance = 0.0,
    this.transferHistory = const [],
    this.onBalancesUpdated,
  });

  @override
  State<TransfersScreen> createState() => TransfersScreenState();
}

class TransfersScreenState extends State<TransfersScreen>
    with WidgetsBindingObserver {
  static const String baseUrl = 'http://192.168.1.155:8080';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _beneficiaryAccountController =
      TextEditingController();

  final TextEditingController _amountController =
      TextEditingController();

  bool _isLoading = false;
  bool _isLoadingAccounts = true;
  bool _isLoadingHistory = true;
  bool _isVerifyingBeneficiary = false;

  List<OwnedAccount> _accounts = [];

  OwnedAccount? _currentAccount;

  String? _beneficiaryName;
  String? _beneficiaryAccountType;

  List<TransferRecord> _transferHistory = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _loadData();
  }

  @override
  void didUpdateWidget(
    covariant TransfersScreen oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.userId != widget.userId) {
      _loadData();
    }
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _beneficiaryAccountController.dispose();
    _amountController.dispose();

    super.dispose();
  }

  // =========================================================
  // MÉTHODE PUBLIQUE APPELÉE PAR MainNavigation
  // =========================================================

  Future<void> refreshFromParent() async {
    await _loadData();
  }

  // =========================================================
  // CHARGEMENT GLOBAL
  // =========================================================

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoadingAccounts = true;
      _isLoadingHistory = true;
    });

    try {
      await _loadCurrentAccount();
      await _loadTransferHistory();
    } catch (e) {
      debugPrint(
        'Erreur chargement écran virement : $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de charger les informations du virement.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // CHARGEMENT DES COMPTES
  // =========================================================

  Future<void> _loadCurrentAccount() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/accounts/user/${widget.userId}',
        ),
      );

      if (!mounted) return;

      if (response.statusCode != 200) {
        throw Exception(
          'Impossible de récupérer les comptes.',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception(
          'Réponse des comptes invalide.',
        );
      }

      final accounts = decoded
          .whereType<Map<String, dynamic>>()
          .map(OwnedAccount.fromJson)
          .toList();

      final currentAccounts = accounts
          .where(
            (account) => account.type == 'CURRENT',
          )
          .toList();

      setState(() {
        _accounts = accounts;

        _currentAccount = currentAccounts.isEmpty
            ? null
            : currentAccounts.first;

        _isLoadingAccounts = false;
      });
    } catch (e) {
      debugPrint(
        'Erreur chargement compte courant : $e',
      );

      if (!mounted) return;

      setState(() {
        _accounts = [];
        _currentAccount = null;
        _isLoadingAccounts = false;
      });

      rethrow;
    }
  }

  // =========================================================
  // HISTORIQUE DES VIREMENTS
  // =========================================================

  Future<void> _loadTransferHistory() async {
    if (!mounted) return;

    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/transactions/user/${widget.userId}',
        ),
      );

      if (!mounted) return;

      if (response.statusCode != 200) {
        throw Exception(
          'Erreur HTTP ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception(
          'Réponse historique invalide.',
        );
      }

      final transfers = <TransferRecord>[];

      for (final item in decoded) {
        if (item is! Map<String, dynamic>) {
          continue;
        }

        final type = (item['type'] ?? '')
            .toString()
            .trim()
            .toUpperCase();

        if (type != 'TRANSFER_OUT' &&
            type != 'TRANSFER_IN') {
          continue;
        }

        final id = int.tryParse(
              (item['id'] ?? '').toString(),
            ) ??
            0;

        final amount = item['amount'] is num
            ? (item['amount'] as num).toDouble()
            : double.tryParse(
                  (item['amount'] ?? '0').toString(),
                ) ??
                0.0;

        final label =
            (item['label'] ?? '').toString().trim();

        final relatedAccount =
            (item['relatedAccountNumber'] ?? '')
                .toString()
                .trim();

        final createdAt =
            (item['createdAt'] ?? '').toString();

        DateTime date;

        try {
          date = DateTime.parse(createdAt);
        } catch (_) {
          date = DateTime.now();
        }

        if (type == 'TRANSFER_OUT') {
          transfers.add(
            TransferRecord(
              id: id,
              beneficiary: _cleanTransferLabel(
                label,
                relatedAccount,
                true,
              ),
              beneficiaryAccountNumber:
                  relatedAccount,
              amount: amount,
              date: date,
              isIncoming: false,
            ),
          );
        } else {
          transfers.add(
            TransferRecord(
              id: id,
              beneficiary: _cleanTransferLabel(
                label,
                relatedAccount,
                false,
              ),
              beneficiaryAccountNumber:
                  relatedAccount,
              amount: amount,
              date: date,
              isIncoming: true,
            ),
          );
        }
      }

      transfers.sort(
        (a, b) => b.date.compareTo(a.date),
      );

      if (!mounted) return;

      setState(() {
        _transferHistory = transfers;
        _isLoadingHistory = false;
      });
    } catch (e) {
      debugPrint(
        'Erreur historique : $e',
      );

      if (!mounted) return;

      setState(() {
        _transferHistory = [];
        _isLoadingHistory = false;
      });
    }
  }

  String _cleanTransferLabel(
    String label,
    String relatedAccount,
    bool outgoing,
  ) {
    if (label.isNotEmpty) {
      final lower = label.toLowerCase();

      if (lower.startsWith('virement vers ')) {
        return label
            .substring('Virement vers '.length)
            .trim();
      }

      if (lower.startsWith('virement de ')) {
        return label
            .substring('Virement de '.length)
            .trim();
      }

      return label;
    }

    if (relatedAccount.isNotEmpty) {
      return relatedAccount;
    }

    return outgoing
        ? 'Bénéficiaire'
        : 'Expéditeur';
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  // =========================================================
  // VALIDATION BÉNÉFICIAIRE
  // =========================================================

  String? _validateBeneficiaryAccount(
    String? value,
  ) {
    final text =
        value?.trim().toUpperCase() ?? '';

    if (text.isEmpty) {
      return 'Veuillez entrer le numéro de compte du bénéficiaire.';
    }

    if (!RegExp(
      r'^TN[A-Z0-9]{6,}$',
    ).hasMatch(text)) {
      return 'Numéro de compte invalide.';
    }

    for (final account in _accounts) {
      if (account.accountNumber.toUpperCase() ==
          text) {
        return 'Impossible de faire un virement vers votre propre compte.';
      }
    }

    return null;
  }

  // =========================================================
  // VÉRIFICATION DU BÉNÉFICIAIRE
  // =========================================================

  Future<void> _verifyBeneficiary() async {
    final accountNumber =
        _beneficiaryAccountController.text
            .trim()
            .toUpperCase();

    if (accountNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Entrez d’abord un numéro de compte.',
          ),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    if (!RegExp(
      r'^TN[A-Z0-9]{6,}$',
    ).hasMatch(accountNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Numéro de compte invalide.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final isOwnAccount = _accounts.any(
      (account) =>
          account.accountNumber.toUpperCase() ==
          accountNumber,
    );

    if (isOwnAccount) {
      setState(() {
        _beneficiaryName = null;
        _beneficiaryAccountType = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de faire un virement vers votre propre compte. '
            'Pour transférer entre vos comptes, utilisez la page « Mes comptes ».',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    setState(() {
      _isVerifyingBeneficiary = true;
      _beneficiaryName = null;
      _beneficiaryAccountType = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/accounts/lookup/$accountNumber',
        ),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          final fullName =
              (decoded['fullName'] ?? '')
                  .toString()
                  .trim();

          final accountType =
              (decoded['type'] ?? '')
                  .toString()
                  .trim()
                  .toUpperCase();

          if (accountType != 'CURRENT') {
            setState(() {
              _beneficiaryName = null;
              _beneficiaryAccountType =
                  accountType;
            });

            ScaffoldMessenger.of(context)
                .showSnackBar(
              const SnackBar(
                content: Text(
                  'Le compte du bénéficiaire doit être un compte courant.',
                ),
                backgroundColor: Colors.red,
              ),
            );

            return;
          }

          if (fullName.isEmpty) {
            ScaffoldMessenger.of(context)
                .showSnackBar(
              const SnackBar(
                content: Text(
                  'Les informations du titulaire sont introuvables.',
                ),
                backgroundColor: Colors.red,
              ),
            );

            return;
          }

          setState(() {
            _beneficiaryName = fullName;
            _beneficiaryAccountType = 'CURRENT';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Compte courant vérifié : $fullName',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _beneficiaryName = null;
          _beneficiaryAccountType = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Aucun compte trouvé avec ce numéro.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'Erreur vérification bénéficiaire : $e',
      );

      if (!mounted) return;

      setState(() {
        _beneficiaryName = null;
        _beneficiaryAccountType = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de vérifier ce compte. Vérifiez que Spring Boot est démarré.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingBeneficiary = false;
        });
      }
    }
  }

  // =========================================================
  // EXÉCUTION VIREMENT EXTERNE
  // =========================================================

  Future<void> _executeTransfer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final sourceAccount = _currentAccount;

    if (sourceAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aucun compte courant disponible.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    if (_beneficiaryName == null ||
        _beneficiaryName!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez vérifier le bénéficiaire avant de continuer.',
          ),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    if (_beneficiaryAccountType != 'CURRENT') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Le compte du bénéficiaire doit être un compte courant.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final beneficiaryAccount =
        _beneficiaryAccountController.text
            .trim()
            .toUpperCase();

    if (_accounts.any(
      (account) =>
          account.accountNumber.toUpperCase() ==
          beneficiaryAccount,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ce compte appartient à votre utilisateur. '
            'Utilisez la page « Mes comptes » pour un virement interne.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final amount =
        double.tryParse(
          _amountController.text
              .trim()
              .replaceAll(',', '.'),
        ) ??
        0.0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Montant invalide.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    if (amount > sourceAccount.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solde insuffisant sur votre compte courant.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final label =
        'Virement vers ${_beneficiaryName!.trim()}';

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/api/transactions/transfer',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fromAccountNumber':
              sourceAccount.accountNumber,
          'toAccountNumber':
              beneficiaryAccount,
          'amount': amount,
          'label': label,
        }),
      );

      if (!mounted) return;

      Map<String, dynamic> data = {};

      try {
        final decoded =
            jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {}

      if (response.statusCode == 200) {
        await _loadCurrentAccount();
        await _loadTransferHistory();

        if (!mounted) return;

        final newCourant =
            _currentAccount?.balance ??
                double.tryParse(
                  (data['newSourceBalance'] ?? '')
                      .toString(),
                ) ??
                0.0;

        final savingsAccounts = _accounts
            .where(
              (account) =>
                  account.type == 'SAVINGS',
            )
            .toList();

        final newEpargne =
            savingsAccounts.isNotEmpty
                ? savingsAccounts.first.balance
                : widget.epargneBalance;

        final record = TransferRecord(
          id: int.tryParse(
                (data['transactionId'] ?? '')
                    .toString(),
              ) ??
              DateTime.now()
                  .millisecondsSinceEpoch,
          beneficiary:
              (data['beneficiaryName'] ??
                      _beneficiaryName ??
                      beneficiaryAccount)
                  .toString(),
          beneficiaryAccountNumber:
              (data['beneficiaryAccountNumber'] ??
                      beneficiaryAccount)
                  .toString(),
          amount: amount,
          date: DateTime.now(),
          isIncoming: false,
        );

        widget.onBalancesUpdated?.call(
          newCourant,
          newEpargne,
          record,
        );

        final successName =
            (data['beneficiaryName'] ??
                    _beneficiaryName ??
                    '')
                .toString();

        final successAccount =
            (data['beneficiaryAccountNumber'] ??
                    beneficiaryAccount)
                .toString();

        setState(() {
          _amountController.clear();
          _beneficiaryAccountController.clear();
          _beneficiaryName = null;
          _beneficiaryAccountType = null;
        });

        _showSuccessDialog(
          amount: amount,
          beneficiaryName: successName,
          beneficiaryAccountNumber:
              successAccount,
        );
      } else {
        final message =
            (data['message'] ??
                    'Impossible d\'effectuer le virement.')
                .toString();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'Erreur virement : $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de contacter le serveur. Vérifiez que Spring Boot est démarré.',
          ),
          backgroundColor: Colors.red,
        ),
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
  // DIALOGUE SUCCÈS
  // =========================================================

  void _showSuccessDialog({
    required double amount,
    required String beneficiaryName,
    required String beneficiaryAccountNumber,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Virement effectué',
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text('Montant'),
              Text(
                '${amount.toStringAsFixed(3)} TND',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 14),
              const Text('Bénéficiaire'),
              Text(
                beneficiaryName.isNotEmpty
                    ? beneficiaryName
                    : 'Bénéficiaire',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              const Text('Compte courant'),
              Text(
                beneficiaryAccountNumber,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} à '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  // =========================================================
  // INTERFACE
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Virement',
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed:
                _isLoading ? null : _refreshData,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius:
                        BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.blue.shade200,
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.person_outline,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Cette page permet uniquement d’envoyer de l’argent vers le compte courant d’un autre utilisateur.',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Compte à débiter',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                if (_isLoadingAccounts)
                  const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                else if (_currentAccount == null)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Aucun compte courant disponible pour effectuer un virement.',
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons
                              .account_balance_outlined,
                          size: 30,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              const Text(
                                'Compte courant',
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _currentAccount!
                                    .accountNumber,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors
                                      .grey
                                      .shade600,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Solde disponible : ${_currentAccount!.balance.toStringAsFixed(3)} TND',
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                const Text(
                  'Compte du bénéficiaire',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller:
                      _beneficiaryAccountController,
                  enabled: !_isLoading,
                  textCapitalization:
                      TextCapitalization.characters,
                  onChanged: (value) {
                    if (_beneficiaryName != null ||
                        _beneficiaryAccountType !=
                            null) {
                      setState(() {
                        _beneficiaryName = null;
                        _beneficiaryAccountType =
                            null;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    labelText:
                        'Numéro de compte',
                    hintText:
                        'Ex. TN807FCE267DEC',
                    helperText:
                        'Uniquement un compte courant appartenant à un autre utilisateur',
                    border:
                        const OutlineInputBorder(),
                    prefixIcon: const Icon(
                      Icons
                          .account_balance_wallet_outlined,
                    ),
                    suffixIcon: TextButton(
                      onPressed:
                          _isVerifyingBeneficiary
                              ? null
                              : _verifyBeneficiary,
                      child:
                          _isVerifyingBeneficiary
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Vérifier',
                                ),
                    ),
                  ),
                  validator:
                      _validateBeneficiaryAccount,
                ),
                if (_beneficiaryName != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius:
                          BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            Colors.green.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color:
                              Colors.green.shade700,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                _beneficiaryName!,
                                style: TextStyle(
                                  color: Colors
                                      .green
                                      .shade900,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                  height: 3),
                              const Text(
                                'Compte courant vérifié',
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                const Text(
                  'Montant',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  enabled: !_isLoading,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      const InputDecoration(
                    labelText: 'Montant (TND)',
                    border:
                        OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons
                          .account_balance_wallet,
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Saisissez le montant.';
                    }

                    final amount =
                        double.tryParse(
                      value
                          .trim()
                          .replaceAll(
                            ',',
                            '.',
                          ),
                    );

                    if (amount == null ||
                        amount <= 0) {
                      return 'Montant invalide.';
                    }

                    if (_currentAccount !=
                            null &&
                        amount >
                            _currentAccount!
                                .balance) {
                      return 'Solde insuffisant.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed:
                        _isLoading ||
                                _currentAccount ==
                                    null
                            ? null
                            : _executeTransfer,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                          ),
                    label: Text(
                      _isLoading
                          ? 'Virement en cours...'
                          : 'Effectuer le virement',
                      style:
                          const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 35),
                const Divider(),
                const SizedBox(height: 15),
                Text(
                  'Historique des virements récents',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight:
                            FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                if (_isLoadingHistory)
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(
                      vertical: 25,
                    ),
                    child: Center(
                      child:
                          CircularProgressIndicator(),
                    ),
                  )
                else if (_transferHistory.isEmpty)
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(
                      vertical: 10,
                    ),
                    child: Text(
                      'Aucun virement effectué ou reçu pour le moment.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle:
                            FontStyle.italic,
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount:
                        _transferHistory.length,
                    itemBuilder:
                        (context, index) {
                      final item =
                          _transferHistory[index];

                      final sign =
                          item.isIncoming
                              ? '+'
                              : '-';

                      final amountColor =
                          item.isIncoming
                              ? Colors.green
                              : Colors.red;

                      return Card(
                        elevation: 1,
                        margin:
                            const EdgeInsets.only(
                          bottom: 10,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            8,
                          ),
                        ),
                        child: ListTile(
                          leading:
                              CircleAvatar(
                            backgroundColor:
                                item.isIncoming
                                    ? Colors
                                        .green
                                        .shade100
                                    : Colors
                                        .red
                                        .shade100,
                            child: Icon(
                              item.isIncoming
                                  ? Icons
                                      .arrow_downward
                                  : Icons
                                      .arrow_upward,
                              color:
                                  amountColor,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            item.isIncoming
                                ? 'Virement reçu'
                                : 'Virement envoyé',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle:
                              Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                item.isIncoming
                                    ? 'Depuis : ${item.beneficiary}'
                                    : 'Vers : ${item.beneficiary}',
                                style:
                                    const TextStyle(
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                _formatDate(
                                  item.date,
                                ),
                                style:
                                    const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                              if (item
                                  .beneficiaryAccountNumber
                                  .isNotEmpty)
                                Text(
                                  item
                                      .beneficiaryAccountNumber,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors
                                        .grey
                                        .shade600,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Text(
                            '$sign${item.amount.toStringAsFixed(2)} TND',
                            style: TextStyle(
                              color:
                                  amountColor,
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}