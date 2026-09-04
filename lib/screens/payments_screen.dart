import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PaymentItem {
  final String serviceName;
  final String reference;
  final double amount;
  final DateTime date;
  final String category;

  PaymentItem({
    required this.serviceName,
    required this.reference,
    required this.amount,
    required this.date,
    required this.category,
  });
}

/// Modèle correspondant à l'entité RadarFine du backend Spring Boot.
class RadarFine {
  final String reference;
  final String nature;
  final String immatriculation;
  final DateTime notificationDate;
  final double amount;
  bool paid;

  RadarFine({
    required this.reference,
    required this.nature,
    required this.immatriculation,
    required this.notificationDate,
    required this.amount,
    this.paid = false,
  });

  factory RadarFine.fromJson(
    Map<String, dynamic> json,
  ) {
    return RadarFine(
      reference:
          (json['reference'] ?? '').toString(),
      nature:
          (json['nature'] ?? '').toString(),
      immatriculation:
          (json['immatriculation'] ?? '').toString(),
      notificationDate:
          DateTime.parse(
        json['notificationDate'].toString(),
      ),
      amount:
          json['amount'] is num
              ? (json['amount'] as num).toDouble()
              : double.tryParse(
                    (json['amount'] ?? '0').toString(),
                  ) ??
                  0.0,
      paid:
          json['paid'] as bool? ?? false,
    );
  }
}

class PaymentsScreen extends StatefulWidget {
  final int userId;
  final double courantBalance;
  final List<dynamic> paymentsHistory;

  final Function(
    String accountName,
    double amount,
    PaymentItem item,
  ) onPaymentSuccess;

  const PaymentsScreen({
    super.key,
    required this.userId,
    required this.courantBalance,
    required this.paymentsHistory,
    required this.onPaymentSuccess,
  });

  @override
  State<PaymentsScreen> createState() =>
      _PaymentsScreenState();
}

class _PaymentsScreenState
    extends State<PaymentsScreen> {
  static const String baseUrl =
      'http://192.168.1.155:8080';

  // =========================================================
  // COULEURS SMARTBANK
  // =========================================================

  static const Color blue =
      Color(0xFF0B5AA6);

  static const Color darkBlue =
      Color(0xFF06457E);

  static const Color yellow =
      Color(0xFFF4C542);

  static const Color green =
      Color(0xFF087A5B);

  static const Color orange =
      Color(0xFFE58A00);

  // =========================================================
  // SÉLECTION
  // =========================================================

  String? _selectedCategory;
  String? _selectedBiller;

  // =========================================================
  // FORMULAIRE
  // =========================================================

  final _formKey =
      GlobalKey<FormState>();

  final _referenceController =
      TextEditingController();

  final _amountController =
      TextEditingController();

  // =========================================================
  // COMPTE
  // =========================================================

  bool _isSubmittingPayment =
      false;

  bool _isLoadingAccount =
      true;

  String? _accountNumber;

  // =========================================================
  // AMENDES RADAR
  // =========================================================

  bool _radarSearched =
      false;

  RadarFine? _selectedRadarFine;

  List<RadarFine> _radarFines = [];

  bool _isSearchingRadar =
      false;

  bool _isPayingRadar =
      false;

  // =========================================================
  // LISTES
  // =========================================================

  final List<String> _facturesList = [
    'STEG',
    'SONEDE',
    'Tunisie Telecom',
  ];

  final List<String> _servicesList = [
    'Vignette',
    'Amendes Radar',
  ];

  final List<String> _rechargesList = [
    'Tunisie Telecom',
    'Ooredoo',
    'Orange',
  ];

  final Map<String, Set<String>>
      _operatorPrefixes = {
    'Ooredoo': {
      '20',
      '21',
      '22',
      '23',
      '24',
      '25',
      '26',
      '27',
      '28',
      '29',
    },
    'Orange': {
      '50',
      '51',
      '52',
      '53',
      '54',
      '55',
      '56',
      '57',
      '58',
      '59',
    },
    'Tunisie Telecom': {
      '40',
      '90',
      '91',
      '92',
      '93',
      '94',
      '95',
      '96',
      '97',
      '98',
      '99',
    },
  };

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();
    _loadCurrentAccountNumber();
  }

  // =========================================================
  // COMPTE COURANT
  // =========================================================

  Future<void>
      _loadCurrentAccountNumber() async {
    if (mounted) {
      setState(() {
        _isLoadingAccount =
            true;
      });
    }

    try {
      final response =
          await http
              .get(
                Uri.parse(
                  '$baseUrl/api/accounts/user/${widget.userId}',
                ),
              )
              .timeout(
                const Duration(
                  seconds: 10,
                ),
              );

      if (!mounted) return;

      if (response.statusCode ==
          200) {
        final data =
            jsonDecode(
          response.body,
        );

        if (data is List) {
          for (final acc in data) {
            if (acc is! Map) continue;

            final type =
                (acc['type'] ?? '')
                    .toString()
                    .trim()
                    .toUpperCase();

            if (type == 'CURRENT') {
              setState(() {
                _accountNumber =
                    (acc['accountNumber'] ??
                            '')
                        .toString();
              });
              break;
            }
          }
        }
      }
    } catch (e) {
      debugPrint(
        'Erreur chargement compte paiement : $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAccount =
              false;
        });
      }
    }
  }

  // =========================================================
  // BILLERS
  // =========================================================

  List<String> get _currentBillers {
    switch (_selectedCategory) {
      case 'Factures':
        return _facturesList;

      case 'Services':
        return _servicesList;

      case 'Recharges':
        return _rechargesList;

      default:
        return [];
    }
  }

  bool get _isRadar =>
      _selectedCategory ==
          'Services' &&
      _selectedBiller ==
          'Amendes Radar';

  bool get _isVignette =>
      _selectedCategory ==
          'Services' &&
      _selectedBiller ==
          'Vignette';

  // =========================================================
  // LABEL RÉFÉRENCE
  // =========================================================

  String get _referenceLabel {
    if (_selectedCategory ==
        'Factures') {
      switch (_selectedBiller) {
        case 'STEG':
          return 'Référence d’abonnement';

        case 'SONEDE':
          return 'Référence / numéro client';

        case 'Tunisie Telecom':
          return 'Numéro de ligne TT';

        default:
          return 'Référence de la facture';
      }
    }

    if (_isVignette) {
      return 'Immatriculation du véhicule';
    }

    if (_isRadar) {
      return 'Immatriculation du véhicule';
    }

    if (_selectedCategory ==
        'Recharges') {
      return 'Numéro de téléphone';
    }

    return 'Référence';
  }

  String? _getReferenceHint() {
    if (_selectedBiller ==
        'STEG') {
      return 'Ex. 123456789';
    }

    if (_selectedBiller ==
        'SONEDE') {
      return 'Ex. 12345678';
    }

    if (_selectedBiller ==
            'Tunisie Telecom' &&
        _selectedCategory ==
            'Factures') {
      return 'Ex. 71123456 ou 44123456';
    }

    if (_isVignette ||
        _isRadar) {
      return 'Ex. 123TUN4567';
    }

    if (_selectedCategory ==
        'Recharges') {
      return 'Ex. 98123456';
    }

    return null;
  }

  String? _getReferenceHelperText() {
    if (_selectedBiller ==
        'STEG') {
      return 'Exactement 9 chiffres';
    }

    if (_selectedBiller ==
        'SONEDE') {
      return 'Référence numérique';
    }

    if (_selectedBiller ==
            'Tunisie Telecom' &&
        _selectedCategory ==
            'Factures') {
      return 'Numéro TT à 8 chiffres';
    }

    if (_isVignette) {
      return 'Format : 1 à 3 chiffres + TUN + 1 à 4 chiffres';
    }

    if (_isRadar) {
      return 'Recherchez les infractions associées au véhicule';
    }

    if (_selectedCategory ==
        'Recharges') {
      return 'Numéro mobile tunisien à 8 chiffres';
    }

    return null;
  }

  // =========================================================
  // VALIDATION IMMATRICULATION
  // =========================================================

  String _normalizeImmatriculation(
    String value,
  ) {
    return value
        .trim()
        .toUpperCase()
        .replaceAll(
          RegExp(r'\s+'),
          '',
        );
  }

  bool _isValidTunisianRegistration(
    String value,
  ) {
    final matricule =
        _normalizeImmatriculation(
      value,
    );

    return RegExp(
      r'^[0-9]{1,3}TUN[0-9]{1,4}$',
    ).hasMatch(matricule);
  }

  String? _validateImmatriculation(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Saisissez l’immatriculation du véhicule';
    }

    if (!_isValidTunisianRegistration(
      value,
    )) {
      return 'Format invalide : ex. 123TUN4567';
    }

    return null;
  }

  // =========================================================
  // VALIDATION STEG
  // =========================================================

  String? _validateSteg(
    String value,
  ) {
    if (!RegExp(
      r'^[0-9]{9}$',
    ).hasMatch(value)) {
      return 'La référence STEG doit comporter exactement 9 chiffres';
    }

    return null;
  }

  // =========================================================
  // VALIDATION SONEDE
  // =========================================================

  String? _validateSonede(
    String value,
  ) {
    if (value.isEmpty) {
      return 'La référence SONEDE est obligatoire';
    }

    if (!RegExp(
      r'^[0-9]+$',
    ).hasMatch(value)) {
      return 'La référence SONEDE doit contenir uniquement des chiffres';
    }

    return null;
  }

  // =========================================================
  // TT FACTURE
  // =========================================================

  bool _isTtLineNumber(
    String number,
  ) {
    if (!RegExp(
      r'^[0-9]{8}$',
    ).hasMatch(number)) {
      return false;
    }

    final prefix =
        number.substring(0, 2);

    if (prefix.startsWith('7')) {
      return true;
    }

    const ttMobilePrefixes = {
      '40',
      '41',
      '42',
      '43',
      '44',
      '45',
      '47',
      '48',
      '49',
      '90',
      '91',
      '92',
      '93',
      '94',
      '95',
      '96',
      '97',
      '98',
      '99',
    };

    return ttMobilePrefixes
        .contains(prefix);
  }

  String? _validateTunisieTelecomFacture(
    String value,
  ) {
    if (!RegExp(
      r'^[0-9]{8}$',
    ).hasMatch(value)) {
      return 'Le numéro de ligne TT doit comporter exactement 8 chiffres';
    }

    if (!_isTtLineNumber(value)) {
      return 'Numéro de ligne TT non reconnu';
    }

    return null;
  }

  // =========================================================
  // RECHARGE MOBILE
  // =========================================================

  bool _isValidTunisianMobileNumber(
    String number,
  ) {
    if (!RegExp(
      r'^[0-9]{8}$',
    ).hasMatch(number)) {
      return false;
    }

    if (number.startsWith('7')) {
      return false;
    }

    const validMobilePrefixes = {
      '20',
      '21',
      '22',
      '23',
      '24',
      '25',
      '26',
      '27',
      '28',
      '29',
      '40',
      '41',
      '42',
      '43',
      '44',
      '45',
      '47',
      '48',
      '49',
      '90',
      '91',
      '92',
      '93',
      '94',
      '95',
      '96',
      '97',
      '98',
      '99',
      '50',
      '51',
      '52',
      '53',
      '54',
      '55',
      '56',
      '57',
      '58',
      '59',
    };

    return validMobilePrefixes
        .contains(
      number.substring(0, 2),
    );
  }

  String? _validateRechargePhone(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Ce champ est obligatoire';
    }

    final number =
        value
            .trim()
            .replaceAll(
              RegExp(r'\s+'),
              '',
            );

    if (!RegExp(
      r'^[0-9]{8}$',
    ).hasMatch(number)) {
      return 'Le numéro doit comporter exactement 8 chiffres';
    }

    if (number.startsWith('7')) {
      return 'Ce numéro correspond à une ligne fixe, pas à une ligne mobile';
    }

    if (!_isValidTunisianMobileNumber(
      number,
    )) {
      return 'Préfixe mobile tunisien non reconnu';
    }

    return null;
  }

  // =========================================================
  // PORTABILITÉ
  // =========================================================

  bool _isPrefixMismatchForRecharge() {
    if (_selectedCategory !=
            'Recharges' ||
        _selectedBiller == null) {
      return false;
    }

    final number =
        _referenceController.text
            .trim()
            .replaceAll(
              RegExp(r'\s+'),
              '',
            );

    if (!RegExp(
      r'^[0-9]{8}$',
    ).hasMatch(number)) {
      return false;
    }

    if (number.startsWith('7')) {
      return false;
    }

    final prefix =
        number.substring(0, 2);

    final isKnownPrefix =
        _operatorPrefixes.values.any(
      (set) => set.contains(prefix),
    );

    if (!isKnownPrefix) {
      return false;
    }

    final expectedPrefixes =
        _operatorPrefixes[
                _selectedBiller] ??
            {};

    return !expectedPrefixes
        .contains(prefix);
  }

  // =========================================================
  // VALIDATION RÉFÉRENCE
  // =========================================================

  String? _validateReference(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Ce champ est obligatoire';
    }

    final reference =
        value.trim();

    if (_selectedCategory ==
        'Factures') {
      if (_selectedBiller ==
          'STEG') {
        return _validateSteg(
          reference,
        );
      }

      if (_selectedBiller ==
          'SONEDE') {
        return _validateSonede(
          reference,
        );
      }

      if (_selectedBiller ==
          'Tunisie Telecom') {
        return _validateTunisieTelecomFacture(
          reference,
        );
      }
    }

    return null;
  }

  // =========================================================
  // VALIDATION MONTANT
  // =========================================================

  String? _validateAmount(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Saisissez le montant';
    }

    final amount =
        double.tryParse(
      value
          .trim()
          .replaceAll(',', '.'),
    );

    if (amount == null ||
        amount <= 0) {
      return 'Montant invalide';
    }

    return null;
  }

  // =========================================================
  // SNACK
  // =========================================================

  void _showSnack(
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
        duration:
            const Duration(
          seconds: 4,
        ),
      ),
    );
  }

  // =========================================================
  // RADAR
  // =========================================================

  Future<void> _searchRadarFines() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    final registration =
        _normalizeImmatriculation(
      _referenceController.text,
    );

    setState(() {
      _isSearchingRadar = true;
      _selectedRadarFine = null;
    });

    try {
      final response =
          await http
              .get(
                Uri.parse(
                  '$baseUrl/api/amendes?immatriculation=$registration',
                ),
              )
              .timeout(
                const Duration(seconds: 10),
              );

      if (!mounted) return;

      if (response.statusCode ==
          200) {
        final data =
            jsonDecode(
          response.body,
        );

        final List<RadarFine>
            fines = [];

        if (data is List) {
          for (final item in data) {
            if (item is Map) {
              fines.add(
                RadarFine.fromJson(
                  Map<String, dynamic>.from(
                    item,
                  ),
                ),
              );
            }
          }
        }

        setState(() {
          _radarFines =
              fines;
          _radarSearched =
              true;
        });
      } else {
        setState(() {
          _radarFines = [];
          _radarSearched =
              true;
        });

        _showSnack(
          'Erreur lors de la recherche des infractions.',
          error: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _radarFines = [];
        _radarSearched =
            true;
      });

      _showSnack(
        'Impossible de contacter le serveur.',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingRadar =
              false;
        });
      }
    }
  }

  List<RadarFine>
      get _matchingRadarFines {
    if (!_radarSearched) {
      return [];
    }

    return _radarFines;
  }

  void _selectRadarFine(
    RadarFine fine,
  ) {
    setState(() {
      _selectedRadarFine =
          fine;
      _amountController.text =
          fine.amount
              .toStringAsFixed(
        3,
      );
    });
  }

  // =========================================================
  // PAYER RADAR
  // =========================================================

  Future<void>
      _paySelectedRadarFine() async {
    final fine =
        _selectedRadarFine;

    if (fine == null) {
      _showSnack(
        'Sélectionnez une infraction à payer.',
      );
      return;
    }

    if (fine.amount >
        widget.courantBalance) {
      _showSnack(
        'Solde du compte courant insuffisant.',
        error: true,
      );
      return;
    }

    setState(() {
      _isPayingRadar = true;
    });

    try {
      final response =
          await http.post(
        Uri.parse(
          '$baseUrl/api/amendes/${fine.reference}/payer',
        ),
      );

      if (!mounted) return;

      if (response.statusCode ==
          200) {
        final now =
            DateTime.now();

        final transactionReference =
            'P${now.millisecondsSinceEpoch}';

        final authorizationNumber =
            (100000 +
                    now.millisecond *
                        1000 +
                    now.second)
                .toString()
                .padLeft(
                  6,
                  '0',
                )
                .substring(
                  0,
                  6,
                );

        final paymentItem =
            PaymentItem(
          serviceName:
              'Amendes Radar',
          reference:
              fine.reference,
          amount:
              fine.amount,
          date:
              now,
          category:
              'Services',
        );

        setState(() {
          fine.paid = true;

          _radarFines
              .removeWhere(
            (f) =>
                f.reference ==
                fine.reference,
          );

          _selectedRadarFine =
              null;
        });

        widget.onPaymentSuccess(
          'Compte courant',
          fine.amount,
          paymentItem,
        );

        _showRadarReceipt(
          fine,
          transactionReference,
          authorizationNumber,
          now,
        );
      } else {
        String message =
            'Impossible de payer cette amende.';

        if (response
            .body
            .isNotEmpty) {
          message =
              response.body;
        }

        _showSnack(
          message,
          error: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showSnack(
        'Impossible de contacter le serveur.',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPayingRadar =
              false;
        });
      }
    }
  }

  // =========================================================
  // REÇU RADAR
  // =========================================================

  void _showRadarReceipt(
    RadarFine fine,
    String transactionReference,
    String authorizationNumber,
    DateTime authorizationDate,
  ) {
    showDialog(
      context: context,
      barrierDismissible:
          false,
      builder: (dialogContext) {
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
                  Icons.check_circle_outline,
                  color:
                      green,
                ),
              ),
              const SizedBox(
                width:
                    10,
              ),
              const Expanded(
                child:
                    Text(
                  'Paiement confirmé',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content:
              SingleChildScrollView(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildReceiptRow(
                  'Référence transaction',
                  transactionReference,
                ),
                _buildReceiptRow(
                  'Montant',
                  '${fine.amount.toStringAsFixed(3)} TND',
                ),
                _buildReceiptRow(
                  'Autorisation',
                  authorizationNumber,
                ),
                _buildReceiptRow(
                  'Date',
                  _formatDateTime(
                    authorizationDate,
                  ),
                ),
                const SizedBox(
                  height:
                      14,
                ),
                const Text(
                  'Infraction payée',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height:
                      10,
                ),
                _buildReceiptRow(
                  'Référence',
                  fine.reference,
                ),
                _buildReceiptRow(
                  'Nature',
                  fine.nature,
                ),
                _buildReceiptRow(
                  'Immatriculation',
                  fine.immatriculation,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
                Navigator.pop(
                  context,
                );
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
  }

  Widget _buildReceiptRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom:
            8,
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                TextStyle(
              fontSize:
                  11,
              color:
                  Colors.grey.shade600,
            ),
          ),
          const SizedBox(
            height:
                2,
          ),
          Text(
            value,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TABLE RADAR
  // =========================================================

  Widget _buildRadarFineTable() {
    final fines =
        _matchingRadarFines;

    if (fines.isEmpty) {
      return Container(
        width:
            double.infinity,
        padding:
            const EdgeInsets.all(
          18,
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
                  .check_circle_outline,
              color:
                  green,
              size:
                  40,
            ),
            const SizedBox(
              height:
                  10,
            ),
            const Text(
              'Aucune infraction impayée trouvée.',
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
      );
    }

    return Container(
      width:
          double.infinity,
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
          ClipRRect(
        borderRadius:
            BorderRadius.circular(
          17,
        ),
        child:
            SingleChildScrollView(
          scrollDirection:
              Axis.horizontal,
          child:
              DataTable(
            headingRowColor:
                WidgetStatePropertyAll(
              blue.withValues(
                alpha:
                    0.07,
              ),
            ),
            columns: const [
              DataColumn(
                label:
                    Text(
                  'Référence',
                ),
              ),
              DataColumn(
                label:
                    Text(
                  'Nature',
                ),
              ),
              DataColumn(
                label:
                    Text(
                  'Immatriculation',
                ),
              ),
              DataColumn(
                label:
                    Text(
                  'Date',
                ),
              ),
              DataColumn(
                label:
                    Text(
                  'Montant',
                ),
              ),
              DataColumn(
                label:
                    Text(
                  'Payer',
                ),
              ),
            ],
            rows:
                fines.map(
              (fine) {
                final isSelected =
                    _selectedRadarFine
                            ?.reference ==
                        fine.reference;

                return DataRow(
                  selected:
                      isSelected,
                  cells: [
                    DataCell(
                      Text(
                        fine.reference,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        fine.nature,
                      ),
                    ),
                    DataCell(
                      Text(
                        fine.immatriculation,
                      ),
                    ),
                    DataCell(
                      Text(
                        _formatDate(
                          fine
                              .notificationDate,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${fine.amount.toStringAsFixed(3)} TND',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        tooltip:
                            'Sélectionner',
                        icon:
                            Icon(
                          isSelected
                              ? Icons
                                  .radio_button_checked
                              : Icons
                                  .credit_card_outlined,
                          color:
                              isSelected
                                  ? blue
                                  : null,
                        ),
                        onPressed:
                            _isPayingRadar
                                ? null
                                : () =>
                                    _selectRadarFine(
                                      fine,
                                    ),
                      ),
                    ),
                  ],
                );
              },
            ).toList(),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // PAIEMENT NORMAL
  // =========================================================

  Future<void> _submitPayment() async {
    if (_isRadar) {
      await _paySelectedRadarFine();
      return;
    }

    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    if (_accountNumber == null) {
      _showSnack(
        'Compte courant introuvable. Reconnectez-vous et réessayez.',
        error: true,
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

    if (amount >
        widget.courantBalance) {
      _showSnack(
        'Solde du compte courant insuffisant.',
        error: true,
      );
      return;
    }

    String reference =
        _referenceController.text
            .trim();

    if (_isVignette) {
      reference =
          _normalizeImmatriculation(
        reference,
      );
    }

    setState(() {
      _isSubmittingPayment =
          true;
    });

    try {
      final response =
          await http.post(
        Uri.parse(
          '$baseUrl/api/transactions/payment',
        ),
        headers: {
          'Content-Type':
              'application/json',
        },
        body:
            jsonEncode({
          'accountNumber':
              _accountNumber,
          'category':
              _selectedCategory,
          'biller':
              _selectedBiller,
          'reference':
              reference,
          'amount':
              amount,
        }),
      );

      if (!mounted) return;

      Map<String, dynamic>
          data = {};

      try {
        final decoded =
            jsonDecode(
          response.body,
        );

        if (decoded
            is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {}

      if (response.statusCode ==
          200) {
        final newItem =
            PaymentItem(
          serviceName:
              _selectedBiller ??
                  'Service',
          reference:
              reference,
          amount:
              amount,
          date:
              DateTime.now(),
          category:
              _selectedCategory!,
        );

        widget.onPaymentSuccess(
          'Compte courant',
          amount,
          newItem,
        );

        if (!mounted) return;

        Navigator.pop(
          context,
        );

        _showSnack(
          'Paiement de ${amount.toStringAsFixed(2)} TND effectué avec succès.',
        );
      } else {
        final message =
            (data['message'] ??
                    'Impossible d’effectuer le paiement.')
                .toString();

        _showSnack(
          message,
          error: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showSnack(
        'Impossible de contacter le serveur.',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingPayment =
              false;
        });
      }
    }
  }

  // =========================================================
  // RESET
  // =========================================================

  void _resetSelection() {
    setState(() {
      _selectedCategory =
          null;
      _selectedBiller =
          null;

      _referenceController.clear();
      _amountController.clear();

      _radarSearched =
          false;
      _selectedRadarFine =
          null;
      _radarFines = [];
    });
  }

  // =========================================================
  // DATES
  // =========================================================

  String _formatDate(
    DateTime date,
  ) {
    final day =
        date.day.toString().padLeft(
              2,
              '0',
            );

    final month =
        date.month.toString().padLeft(
              2,
              '0',
            );

    return '$day/$month/${date.year}';
  }

  String _formatDateTime(
    DateTime date,
  ) {
    final day =
        date.day.toString().padLeft(
              2,
              '0',
            );

    final month =
        date.month.toString().padLeft(
              2,
              '0',
            );

    final hour =
        date.hour.toString().padLeft(
              2,
              '0',
            );

    final minute =
        date.minute.toString().padLeft(
              2,
              '0',
            );

    final second =
        date.second.toString().padLeft(
              2,
              '0',
            );

    return '$day/$month/${date.year} $hour:$minute:$second';
  }

  // =========================================================
  // CARTE COMPTE
  // =========================================================

  Widget _buildAccountHeader(
    BuildContext context,
  ) {
    final isDark =
        Theme.of(context)
                .brightness ==
            Brightness.dark;

    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        20,
      ),
      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            blue,
            darkBlue,
          ],
        ),
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        boxShadow: [
          BoxShadow(
            color:
                blue.withValues(
              alpha:
                  0.25,
            ),
            blurRadius:
                20,
            offset:
                const Offset(
              0,
              8,
            ),
          ),
        ],
      ),
      child:
          Stack(
        children: [
          Positioned(
            right:
                -35,
            top:
                -45,
            child:
                Container(
              width:
                  150,
              height:
                  150,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color:
                    Colors.white.withValues(
                  alpha:
                      0.05,
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
                    width:
                        45,
                    height:
                        45,
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white.withValues(
                        alpha:
                            0.15,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        13,
                      ),
                    ),
                    child:
                        const Icon(
                      Icons
                          .account_balance_wallet_outlined,
                      color:
                          Colors.white,
                    ),
                  ),
                  const SizedBox(
                    width:
                        12,
                  ),
                  const Expanded(
                    child:
                        Text(
                      'Compte courant',
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
                  ),
                ],
              ),
              const SizedBox(
                height:
                    17,
              ),
              Text(
                _accountNumber == null
                    ? 'Numéro indisponible'
                    : _maskAccount(
                        _accountNumber!,
                      ),
                style:
                    TextStyle(
                  color:
                      Colors.white.withValues(
                    alpha:
                        0.72,
                  ),
                  fontSize:
                      12,
                  letterSpacing:
                      0.4,
                ),
              ),
              const SizedBox(
                height:
                    7,
              ),
              const Text(
                'Solde disponible',
                style:
                    TextStyle(
                  color:
                      Colors.white70,
                  fontSize:
                      12,
                ),
              ),
              const SizedBox(
                height:
                    3,
              ),
              Text(
                '${widget.courantBalance.toStringAsFixed(2)} TND',
                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontSize:
                      28,
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

  String _maskAccount(
    String account,
  ) {
    final clean =
        account.trim();

    if (clean.isEmpty) {
      return '';
    }

    if (clean.length <=
        4) {
      return clean;
    }

    return '•••• ${clean.substring(clean.length - 4)}';
  }

  // =========================================================
  // CARTE CATÉGORIE
  // =========================================================

  Widget _buildCategoryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isDark =
        Theme.of(context)
                .brightness ==
            Brightness.dark;

    return Material(
      color:
          Colors.transparent,
      child:
          InkWell(
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        onTap: () {
          setState(() {
            _selectedCategory =
                title;
            _selectedBiller =
                null;

            _referenceController
                .clear();

            _amountController
                .clear();

            _radarSearched =
                false;

            _selectedRadarFine =
                null;

            _radarFines = [];
          });
        },
        child:
            Container(
          width:
              double.infinity,
          padding:
              const EdgeInsets.all(
            17,
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
                  color.withValues(
                alpha:
                    0.12,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(
                  alpha:
                      isDark
                          ? 0.14
                          : 0.045,
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
              Row(
            children: [
              Container(
                width:
                    50,
                height:
                    50,
                decoration:
                    BoxDecoration(
                  color:
                      color.withValues(
                    alpha:
                        0.11,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
                child:
                    Icon(
                  icon,
                  color:
                      color,
                  size:
                      25,
                ),
              ),
              const SizedBox(
                width:
                    13,
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
                        fontSize:
                            15,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(
                      height:
                          4,
                    ),
                    Text(
                      subtitle,
                      style:
                          TextStyle(
                        color:
                            Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withValues(
                                  alpha:
                                      0.65,
                                ),
                        fontSize:
                            11.5,
                        height:
                            1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons
                    .chevron_right_rounded,
                color:
                    Theme.of(context)
                        .iconTheme
                        .color
                        ?.withValues(
                          alpha:
                              0.55,
                        ),
              ),
            ],
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

    // =======================================================
    // PAGE PRINCIPALE
    // =======================================================

    if (_selectedCategory ==
        null) {
      return Scaffold(
        backgroundColor:
            isDark
                ? const Color(
                    0xFF0F1723,
                  )
                : const Color(
                    0xFFF5F7FA,
                  ),

        appBar:
            AppBar(
          backgroundColor:
              Colors.transparent,
          elevation:
              0,
          title:
              const Text(
            'Paiements & Recharges',
            style:
                TextStyle(
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ),

        body:
            SafeArea(
          child:
              SingleChildScrollView(
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
                // ==========================================
                // COMPTE COURANT
                // ==========================================

                _buildAccountHeader(
                  context,
                ),

                const SizedBox(
                  height:
                      25,
                ),

                Text(
                  'Choisissez une opération',
                  style:
                      theme.textTheme.titleLarge?.copyWith(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height:
                      13,
                ),

                // ==========================================
                // FACTURES
                // ==========================================

                _buildCategoryCard(
                  title:
                      'Factures',
                  subtitle:
                      'STEG • SONEDE • Tunisie Telecom',
                  icon:
                      Icons.receipt_long_rounded,
                  color:
                      blue,
                ),

                const SizedBox(
                  height:
                      12,
                ),

                // ==========================================
                // SERVICES
                // ==========================================

                _buildCategoryCard(
                  title:
                      'Services',
                  subtitle:
                      'Vignette • Amendes Radar',
                  icon:
                      Icons
                          .admin_panel_settings_outlined,
                  color:
                      orange,
                ),

                const SizedBox(
                  height:
                      12,
                ),

                // ==========================================
                // RECHARGES
                // ==========================================

                _buildCategoryCard(
                  title:
                      'Recharges',
                  subtitle:
                      'Tunisie Telecom • Ooredoo • Orange',
                  icon:
                      Icons
                          .phone_android_rounded,
                  color:
                      green,
                ),

                const SizedBox(
                  height:
                      22,
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
                        isDark
                            ? const Color(
                                0xFF221F16,
                              )
                            : const Color(
                                0xFFFFF8E7,
                              ),
                    borderRadius:
                        BorderRadius.circular(
                      17,
                    ),
                    border:
                        Border.all(
                      color:
                          yellow.withValues(
                        alpha:
                            0.25,
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
                              yellow,
                          shape:
                              BoxShape.circle,
                        ),
                        child:
                            const Icon(
                          Icons
                              .security_rounded,
                          color:
                              darkBlue,
                          size:
                              19,
                        ),
                      ),
                      const SizedBox(
                        width:
                            10,
                      ),
                      Expanded(
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Paiements sécurisés',
                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                            const SizedBox(
                              height:
                                  3,
                            ),
                            Text(
                              'Effectuez vos opérations rapidement et en toute sécurité avec SmartBank.',
                              style:
                                  TextStyle(
                                fontSize:
                                    12,
                                color:
                                    theme.textTheme.bodyMedium?.color?.withValues(
                                  alpha:
                                      0.68,
                                ),
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

    // =======================================================
    // PAGE FORMULAIRE
    // =======================================================

    return Scaffold(
      backgroundColor:
          isDark
              ? const Color(
                  0xFF0F1723,
                )
              : const Color(
                  0xFFF5F7FA,
                ),

      appBar:
          AppBar(
        backgroundColor:
            Colors.transparent,
        elevation:
            0,
        leading:
            IconButton(
          tooltip:
              'Retour',
          onPressed:
              _resetSelection,
          icon:
              const Icon(
            Icons.arrow_back_rounded,
          ),
        ),
        title:
            Text(
          '$_selectedCategory',
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),

      body:
          SingleChildScrollView(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          30,
        ),
        child:
            Form(
          key:
              _formKey,
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // =============================================
              // HEADER COMPTE
              // =============================================

              _buildAccountHeader(
                context,
              ),

              const SizedBox(
                height:
                    22,
              ),

              Text(
                _selectedCategory ==
                        'Factures'
                    ? 'Choisir une facture'
                    : _selectedCategory ==
                            'Services'
                        ? 'Choisir un service'
                        : 'Choisir un opérateur',
                style:
                    theme.textTheme.titleLarge?.copyWith(
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(
                height:
                    12,
              ),

              // =============================================
              // ORGANISME
              // =============================================

              DropdownButtonFormField<
                  String>(
                initialValue:
                    _selectedBiller,
                decoration:
                    InputDecoration(
                  labelText:
                      'Organisme / Opérateur',
                  prefixIcon:
                      const Icon(
                    Icons.business_rounded,
                  ),
                  filled:
                      true,
                  fillColor:
                      isDark
                          ? const Color(
                              0xFF182236,
                            )
                          : Colors.white,
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
                          Colors.grey.withValues(
                        alpha:
                            0.15,
                      ),
                    ),
                  ),
                ),
                items:
                    _currentBillers
                        .map(
                  (biller) =>
                      DropdownMenuItem<
                          String>(
                    value:
                        biller,
                    child:
                        Text(
                      biller,
                    ),
                  ),
                )
                        .toList(),
                onChanged:
                    (value) {
                  setState(() {
                    _selectedBiller =
                        value;

                    _referenceController
                        .clear();

                    _amountController
                        .clear();

                    _radarSearched =
                        false;

                    _selectedRadarFine =
                        null;

                    _radarFines =
                        [];
                  });
                },
                validator:
                    (value) {
                  if (value ==
                      null) {
                    return 'Veuillez sélectionner un organisme';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height:
                    18,
              ),

              // =============================================
              // AMENDES RADAR
              // =============================================

              if (_isRadar) ...[
                _buildRadarForm(
                  isDark,
                ),
              ]

              // =============================================
              // FORMULAIRE CLASSIQUE
              // =============================================

              else ...[
                TextFormField(
                  controller:
                      _referenceController,
                  keyboardType:
                      TextInputType.text,
                  textCapitalization:
                      _isVignette
                          ? TextCapitalization
                              .characters
                          : TextCapitalization
                              .none,
                  maxLength:
                      _getMaxReferenceLength(),
                  enabled:
                      !_isSubmittingPayment,
                  onChanged:
                      (_) {
                    if (_selectedCategory ==
                        'Recharges') {
                      setState(() {});
                    }
                  },
                  decoration:
                      InputDecoration(
                    labelText:
                        _referenceLabel,
                    hintText:
                        _getReferenceHint(),
                    helperText:
                        _getReferenceHelperText(),
                    prefixIcon:
                        Icon(
                      _isVignette
                          ? Icons
                              .directions_car_outlined
                          : _selectedCategory ==
                                  'Recharges'
                              ? Icons
                                  .phone_android_rounded
                              : Icons
                                  .confirmation_number_outlined,
                    ),
                    filled:
                        true,
                    fillColor:
                        isDark
                            ? const Color(
                                0xFF182236,
                              )
                            : Colors.white,
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
                            Colors.grey.withValues(
                          alpha:
                              0.15,
                        ),
                      ),
                    ),
                  ),
                  validator:
                      _getReferenceValidator(),
                ),

                if (_selectedCategory ==
                        'Recharges' &&
                    _isPrefixMismatchForRecharge())
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      top:
                          9,
                    ),
                    child:
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
                            isDark
                                ? const Color(
                                    0xFF2A2117,
                                  )
                                : const Color(
                                    0xFFFFF7E8,
                                  ),
                        borderRadius:
                            BorderRadius.circular(
                          13,
                        ),
                      ),
                      child:
                          Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons
                                .info_outline_rounded,
                            color:
                                Colors.orange.shade700,
                            size:
                                19,
                          ),
                          const SizedBox(
                            width:
                                8,
                          ),
                          Expanded(
                            child:
                                Text(
                              'Ce préfixe ne correspond pas habituellement à $_selectedBiller. En cas de portabilité, vous pouvez continuer.',
                              style:
                                  TextStyle(
                                color:
                                    isDark
                                        ? Colors.orange.shade200
                                        : Colors.orange.shade900,
                                fontSize:
                                    12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(
                  height:
                      18,
                ),

                TextFormField(
                  controller:
                      _amountController,
                  enabled:
                      !_isSubmittingPayment,
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
                      Icons.payments_outlined,
                    ),
                    filled:
                        true,
                    fillColor:
                        isDark
                            ? const Color(
                                0xFF182236,
                              )
                            : Colors.white,
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
                            Colors.grey.withValues(
                          alpha:
                              0.15,
                        ),
                      ),
                    ),
                  ),
                  validator:
                      _validateAmount,
                ),

                const SizedBox(
                  height:
                      24,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height:
                      54,
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        _isSubmittingPayment
                            ? null
                            : _submitPayment,
                    icon:
                        _isSubmittingPayment
                            ? const SizedBox(
                                width:
                                    19,
                                height:
                                    19,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons
                                    .check_circle_outline,
                              ),
                    label:
                        Text(
                      _isSubmittingPayment
                          ? 'Paiement en cours...'
                          : 'Valider le paiement',
                      style:
                          const TextStyle(
                        fontSize:
                            15.5,
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
              ],
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // FORMULAIRE RADAR
  // =========================================================

  Widget _buildRadarForm(
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller:
              _referenceController,
          keyboardType:
              TextInputType.text,
          textCapitalization:
              TextCapitalization.characters,
          enabled:
              !_isSearchingRadar &&
                  !_isPayingRadar,
          decoration:
              InputDecoration(
            labelText:
                'Immatriculation du véhicule',
            hintText:
                'Ex. 123TUN4567',
            helperText:
                'Format : 1 à 3 chiffres + TUN + 1 à 4 chiffres',
            prefixIcon:
                const Icon(
              Icons
                  .directions_car_outlined,
            ),
            filled:
                true,
            fillColor:
                isDark
                    ? const Color(
                        0xFF182236,
                      )
                    : Colors.white,
            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                15,
              ),
              borderSide:
                  BorderSide.none,
            ),
          ),
          validator:
              _validateImmatriculation,
        ),

        const SizedBox(
          height:
              12,
        ),

        SizedBox(
          width:
              double.infinity,
          height:
              50,
          child:
              OutlinedButton.icon(
            onPressed:
                _isSearchingRadar
                    ? null
                    : _searchRadarFines,
            icon:
                _isSearchingRadar
                    ? const SizedBox(
                        width:
                            18,
                        height:
                            18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
                        ),
                      )
                    : const Icon(
                        Icons
                            .search_rounded,
                      ),
            label:
                Text(
              _isSearchingRadar
                  ? 'Recherche en cours...'
                  : 'Rechercher mes infractions',
            ),
            style:
                OutlinedButton.styleFrom(
              foregroundColor:
                  blue,
              side:
                  BorderSide(
                color:
                    blue.withValues(
                  alpha:
                      0.35,
                ),
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
            ),
          ),
        ),

        if (_radarSearched) ...[
          const SizedBox(
            height:
                22,
          ),
          const Text(
            'Infractions trouvées',
            style:
                TextStyle(
              fontSize:
                  17,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(
            height:
                10,
          ),
          _buildRadarFineTable(),
        ],

        if (_selectedRadarFine !=
            null) ...[
          const SizedBox(
            height:
                16,
          ),
          Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets.all(
              17,
            ),
            decoration:
                BoxDecoration(
              color:
                  blue.withValues(
                alpha:
                    0.07,
              ),
              borderRadius:
                  BorderRadius.circular(
                17,
              ),
              border:
                  Border.all(
                color:
                    blue.withValues(
                  alpha:
                      0.15,
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
                          const Icon(
                        Icons
                            .gpp_good_outlined,
                        color:
                            blue,
                      ),
                    ),
                    const SizedBox(
                      width:
                          10,
                    ),
                    const Expanded(
                      child:
                          Text(
                        'Infraction sélectionnée',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height:
                      13,
                ),
                Text(
                  'Référence : ${_selectedRadarFine!.reference}',
                ),
                Text(
                  'Nature : ${_selectedRadarFine!.nature}',
                ),
                Text(
                  'Immatriculation : ${_selectedRadarFine!.immatriculation}',
                ),
                const SizedBox(
                  height:
                      5,
                ),
                Text(
                  '${_selectedRadarFine!.amount.toStringAsFixed(3)} TND',
                  style:
                      const TextStyle(
                    fontSize:
                        19,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        blue,
                  ),
                ),
                const SizedBox(
                  height:
                      14,
                ),
                SizedBox(
                  width:
                      double.infinity,
                  height:
                      50,
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        _isPayingRadar
                            ? null
                            : _paySelectedRadarFine,
                    icon:
                        _isPayingRadar
                            ? const SizedBox(
                                width:
                                    18,
                                height:
                                    18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons
                                    .credit_card_rounded,
                              ),
                    label:
                        Text(
                      _isPayingRadar
                          ? 'Paiement en cours...'
                          : 'Payer cette infraction',
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
                          14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // =========================================================
  // MAX REFERENCE
  // =========================================================

  int? _getMaxReferenceLength() {
    if (_selectedBiller ==
        'STEG') {
      return 9;
    }

    if (_selectedCategory ==
        'Recharges') {
      return 8;
    }

    if (_selectedBiller ==
            'Tunisie Telecom' &&
        _selectedCategory ==
            'Factures') {
      return 8;
    }

    return null;
  }

  // =========================================================
  // VALIDATEUR RÉFÉRENCE
  // =========================================================

  FormFieldValidator<String>?
      _getReferenceValidator() {
    if (_selectedCategory ==
        'Recharges') {
      return _validateRechargePhone;
    }

    if (_isVignette) {
      return _validateImmatriculation;
    }

    if (_selectedCategory ==
        'Factures') {
      return _validateReference;
    }

    return _validateReference;
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _referenceController
        .dispose();

    _amountController
        .dispose();

    super.dispose();
  }
}