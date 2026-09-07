import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../services/api_service.dart';
import '../widgets/transaction_item.dart';

class TransactionsScreen extends StatefulWidget {
  final int userId;

  const TransactionsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState
    extends State<TransactionsScreen> {
  final ApiService _apiService = ApiService();

  String _selectedFilter = 'Toutes';

  bool _isLoading = true;

  String? _errorMessage;

  List<BankTransaction> _transactions = [];

  @override
  void initState() {
    super.initState();

    _loadTransactions();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.get(
        '/api/transactions/user/${widget.userId}',
      );

      if (!mounted) return;

      if (response.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Impossible de récupérer l\'historique '
              '(code ${response.statusCode}).';
        });

        return;
      }

      final dynamic decoded =
          _apiService.decodeResponse(response);

      if (decoded is! List) {
        throw Exception(
          'Format de réponse invalide.',
        );
      }

      final List<BankTransaction>
          loadedTransactions = [];

      for (final item in decoded) {
        if (item is Map) {
          try {
            loadedTransactions.add(
              _bankTransactionFromJson(
                Map<String, dynamic>.from(item),
              ),
            );
          } catch (e) {
            debugPrint(
              'Transaction ignorée : $e',
            );
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _transactions = loadedTransactions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Impossible de contacter le serveur.\n'
            'Vérifiez que Spring Boot est démarré.';
      });

      debugPrint(
        'Erreur chargement transactions : $e',
      );
    }
  }

  BankTransaction _bankTransactionFromJson(
      Map<String, dynamic> json) {
    final int id =
        _parseInt(json['id']);

    final double amount =
        _parseDouble(json['amount']);

    final String type =
        (json['type'] ?? '')
            .toString()
            .trim()
            .toUpperCase();

    final String label =
        (json['label'] ?? '')
            .toString()
            .trim();

    final String reference =
        (json['reference'] ?? '')
            .toString()
            .trim();

    final String relatedAccountNumber =
        (json['relatedAccountNumber'] ?? '')
            .toString()
            .trim();

    final DateTime date =
        _parseDate(json['createdAt']);

    final bool isIncome =
        type == 'TRANSFER_IN';

    String title;

    switch (type) {
      case 'TRANSFER_IN':
        title = 'Virement reçu';
        break;

      case 'TRANSFER_OUT':
        title = 'Virement envoyé';
        break;

      case 'PAYMENT':
        title = label.isNotEmpty
            ? label
            : 'Paiement';
        break;

      case 'RECHARGE':
        title = 'Recharge';
        break;

      default:
        title = label.isNotEmpty
            ? label
            : 'Transaction';
    }

    String description;

    if (type == 'TRANSFER_IN') {
      if (relatedAccountNumber.isNotEmpty) {
        description =
            'Virement reçu de '
            '$relatedAccountNumber';
      } else {
        description =
            'Virement bancaire reçu';
      }
    } else if (type == 'TRANSFER_OUT') {
      if (relatedAccountNumber.isNotEmpty) {
        description =
            'Virement vers '
            '$relatedAccountNumber';
      } else {
        description =
            'Virement bancaire envoyé';
      }
    } else if (type == 'PAYMENT') {
      if (reference.isNotEmpty) {
        description =
            '$label • Référence : $reference';
      } else {
        description =
            label.isNotEmpty
                ? label
                : 'Paiement';
      }
    } else {
      description =
          label.isNotEmpty
              ? label
              : 'Transaction';
    }

    String category;

    switch (type) {
      case 'TRANSFER_IN':
      case 'TRANSFER_OUT':
        category = 'Virement';
        break;

      case 'PAYMENT':
        category = 'Paiement';
        break;

      case 'RECHARGE':
        category = 'Recharge';
        break;

      default:
        category =
            type.isNotEmpty
                ? type
                : 'Autre';
    }

    return BankTransaction(
      id: id,
      title: title,
      description: description,
      amount: amount,
      currency: 'TND',
      date: date,
      type: isIncome
          ? TransactionType.income
          : TransactionType.expense,
      category: category,
      relatedAccountNumber:
          relatedAccountNumber.isNotEmpty
              ? relatedAccountNumber
              : null,
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

  double _parseDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    final parsed =
        DateTime.tryParse(
      value?.toString() ?? '',
    );

    return parsed ?? DateTime.now();
  }

  List<BankTransaction>
      get _filteredTransactions {
    if (_selectedFilter == 'Entrées') {
      return _transactions
          .where(
            (transaction) =>
                transaction.type ==
                TransactionType.income,
          )
          .toList();
    }

    if (_selectedFilter == 'Sorties') {
      return _transactions
          .where(
            (transaction) =>
                transaction.type ==
                TransactionType.expense,
          )
          .toList();
    }

    return _transactions;
  }

  void _showTransactionDetails(
      BankTransaction transaction) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final bool isIncome =
            transaction.type ==
                TransactionType.income;

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            24,
            10,
            24,
            30,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Détail de la transaction',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight:
                          FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 24),

              Center(
                child: CircleAvatar(
                  radius: 32,
                  child: Icon(
                    isIncome
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    size: 30,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: Text(
                  transaction.title,
                  textAlign:
                      TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight:
                            FontWeight.bold,
                      ),
                ),
              ),

              const SizedBox(height: 24),

              _DetailRow(
                label: 'Description',
                value:
                    transaction.description,
              ),

              _DetailRow(
                label: 'Catégorie',
                value:
                    transaction.category,
              ),

              _DetailRow(
                label: 'Montant',
                value:
                    '${isIncome ? '+' : '-'}'
                    ' ${transaction.amount.toStringAsFixed(2)} '
                    '${transaction.currency}',
              ),

              _DetailRow(
                label: 'Date',
                value:
                    _formatDateTime(
                      transaction.date,
                    ),
              ),

              _DetailRow(
                label: 'Type',
                value:
                    isIncome
                        ? 'Entrée'
                        : 'Sortie',
              ),

              if (transaction
                      .relatedAccountNumber !=
                  null)
                _DetailRow(
                  label:
                      isIncome
                          ? 'Compte émetteur'
                          : 'Compte bénéficiaire',
                  value:
                      transaction
                          .relatedAccountNumber!,
                ),

              _DetailRow(
                label: 'Identifiant',
                value:
                    '#${transaction.id}',
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateTime(
      DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        'à '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final List<BankTransaction>
        transactions =
        _filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transactions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed:
                _isLoading
                    ? null
                    : _loadTransactions,
            icon:
                const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh:
            _loadTransactions,
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Historique des transactions',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      fontWeight:
                          FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 8),

              Text(
                'Consultez toutes les opérations '
                'de vos comptes.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium,
              ),

              const SizedBox(height: 24),

              SingleChildScrollView(
                scrollDirection:
                    Axis.horizontal,
                child: Row(
                  children: [
                    _FilterButton(
                      label: 'Toutes',
                      selected:
                          _selectedFilter ==
                              'Toutes',
                      onPressed: () {
                        setState(() {
                          _selectedFilter =
                              'Toutes';
                        });
                      },
                    ),

                    const SizedBox(width: 10),

                    _FilterButton(
                      label: 'Entrées',
                      selected:
                          _selectedFilter ==
                              'Entrées',
                      onPressed: () {
                        setState(() {
                          _selectedFilter =
                              'Entrées';
                        });
                      },
                    ),

                    const SizedBox(width: 10),

                    _FilterButton(
                      label: 'Sorties',
                      selected:
                          _selectedFilter ==
                              'Sorties',
                      onPressed: () {
                        setState(() {
                          _selectedFilter =
                              'Sorties';
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (_isLoading)
                const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 60,
                  ),
                  child: Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                )
              else if (_errorMessage != null)
                Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 40,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_off,
                          size: 55,
                          color:
                              Colors.grey.shade500,
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        Text(
                          _errorMessage!,
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            color:
                                Colors.grey.shade700,
                          ),
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        ElevatedButton.icon(
                          onPressed:
                              _loadTransactions,
                          icon:
                              const Icon(
                            Icons.refresh,
                          ),
                          label:
                              const Text(
                            'Réessayer',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (transactions.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 50,
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 60,
                          color:
                              Colors.grey.shade400,
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        const Text(
                          'Aucune transaction trouvée.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        Text(
                          'Vos opérations apparaîtront '
                          'ici automatiquement.',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            color:
                                Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...transactions.map(
                  (transaction) {
                    return Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 8,
                      ),
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                        onTap: () {
                          _showTransactionDetails(
                            transaction,
                          );
                        },
                        child:
                            TransactionItem(
                          transaction:
                              transaction,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterButton
    extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(
      BuildContext context) {
    return FilterChip(
      label:
          Text(label),
      selected:
          selected,
      onSelected: (_) {
        onPressed();
      },
    );
  }
}

class _DetailRow
    extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(
      BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 20),

          Expanded(
            child: Text(
              value,
              textAlign:
                  TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}