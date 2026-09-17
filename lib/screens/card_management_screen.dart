import 'package:flutter/material.dart';

import '../services/api_service.dart';

class CardManagementScreen extends StatefulWidget {
  final int userId;
  final String firstName;

  const CardManagementScreen({
    super.key,
    required this.userId,
    required this.firstName,
  });

  @override
  State<CardManagementScreen> createState() => _CardManagementScreenState();
}

class _CardManagementScreenState extends State<CardManagementScreen> {
  // ==========================================================================
  // COULEURS
  // ==========================================================================

  static const Color _blue = Color(0xFF0B5AA6);
  static const Color _green = Color(0xFF087A5B);
  static const Color _red = Color(0xFFC62828);
  static const Color _orange = Color(0xFFE67E22);

  static const Color _lightBackground = Color(0xFFF5F7FA);
  static const Color _darkBackground = Color(0xFF0F1723);
  static const Color _darkCardBackground = Color(0xFF182236);

  // ==========================================================================
  // SERVICE
  // ==========================================================================

  final ApiService _apiService = ApiService();

  // ==========================================================================
  // STATE
  // ==========================================================================

  List<Map<String, dynamic>> _cards = [];

  bool _isLoading = true;
  bool _isAssigning = false;

  // ID de la carte actuellement en cours de traitement.
  int? _processingCardId;

  // Statut de la dernière demande de déblocage connue pour chaque carte.
  //
  // Exemple :
  // 4 -> PENDING
  // 5 -> APPROVED
  // 6 -> REJECTED
  final Map<int, String> _unblockRequestStatuses = {};

  String _selectedCardType = 'Visa Classic';

  String _accountNumber = '';

  final List<String> _cardTypes = [
    'Visa Classic',
    'Visa Gold',
    'Mastercard Gold',
    'Mastercard Standard',
  ];

  // ==========================================================================
  // LIFECYCLE
  // ==========================================================================

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  // ==========================================================================
  // CHARGER LES CARTES
  // ==========================================================================

  Future<void> _loadCards() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.get(
        '/api/cards/user/${widget.userId}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          _apiService.getErrorMessage(response),
        );
      }

      final decoded = _apiService.decodeResponse(response);

      if (decoded is! List) {
        throw Exception(
          'Réponse invalide du serveur.',
        );
      }

      final cards = decoded
          .whereType<Map>()
          .map(
            (card) => Map<String, dynamic>.from(card),
          )
          .toList();

      String accountNumber = '';

      for (final card in cards) {
        final value = card['accountNumber']?.toString().trim();

        if (value != null && value.isNotEmpty) {
          accountNumber = value;
          break;
        }
      }

      if (!mounted) return;

      setState(() {
        _cards = cards;
        _accountNumber = accountNumber;
        _isLoading = false;
      });

      // Charger séparément les demandes de déblocage.
      await _loadUnblockRequests();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnackBar(
        'Impossible de charger les cartes : '
        '${_extractError(error)}',
      );
    }
  }

  // ==========================================================================
  // CHARGER LES DEMANDES DE DÉBLOCAGE
  // ==========================================================================

  Future<void> _loadUnblockRequests() async {
    try {
      final response = await _apiService.get(
        '/api/cards/unblock-requests/user/${widget.userId}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }

      final decoded = _apiService.decodeResponse(response);

      if (decoded is! List) {
        return;
      }

      final Map<int, String> statuses = {};

      for (final item in decoded) {
        if (item is! Map) continue;

        final cardId = int.tryParse(
          item['cardId']?.toString() ?? '',
        );

        final status = item['status']
            ?.toString()
            .trim()
            .toUpperCase();

        if (cardId == null ||
            status == null ||
            status.isEmpty) {
          continue;
        }

        // La liste retournée par le backend est triée
        // par date décroissante. On garde donc uniquement
        // la première demande rencontrée pour chaque carte.
        if (!statuses.containsKey(cardId)) {
          statuses[cardId] = status;
        }
      }

      if (!mounted) return;

      setState(() {
        _unblockRequestStatuses
          ..clear()
          ..addAll(statuses);
      });
    } catch (_) {
      // Une erreur de chargement des demandes ne doit pas empêcher
      // l'affichage des cartes.
    }
  }

  // ==========================================================================
  // BLOQUER UNE CARTE
  // ==========================================================================

  Future<void> _blockCard(
    Map<String, dynamic> card,
  ) async {
    if (_processingCardId != null) return;

    final cardIdValue = card['id'];

    if (cardIdValue == null) {
      _showSnackBar(
        'Identifiant de carte introuvable.',
      );
      return;
    }

    final int? cardId = int.tryParse(
      cardIdValue.toString(),
    );

    if (cardId == null) {
      _showSnackBar(
        'Identifiant de carte invalide.',
      );
      return;
    }

    final cardType =
        card['cardType']?.toString() ?? 'Carte bancaire';

    final lastFour =
        card['lastFourDigits']?.toString() ?? '0000';

    final currentStatus =
        card['status']?.toString().trim().toUpperCase() ??
            'ACTIVE';

    if (currentStatus != 'ACTIVE') {
      _showSnackBar(
        'Cette carte ne peut pas être bloquée.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _red.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.block_rounded,
                  color: _red,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Bloquer la carte',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Voulez-vous vraiment bloquer la carte '
            '$cardType •••• $lastFour ?',
            style: const TextStyle(
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: _red,
              ),
              child: const Text('Bloquer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _processingCardId = cardId;
    });

    try {
      final response = await _apiService.post(
        '/api/cards/$cardId/block',
        body: {
          'userId': widget.userId,
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          _apiService.getErrorMessage(response),
        );
      }

      if (!mounted) return;

      setState(() {
        _processingCardId = null;
      });

      await _loadCards();

      if (!mounted) return;

      _showSnackBar(
        'Carte •••• $lastFour bloquée avec succès.',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _processingCardId = null;
      });

      _showSnackBar(
        'Impossible de bloquer la carte : '
        '${_extractError(error)}',
      );
    }
  }

  // ==========================================================================
  // DEMANDER LE DÉBLOCAGE
  // ==========================================================================

  Future<void> _requestUnblock(
    Map<String, dynamic> card,
  ) async {
    if (_processingCardId != null) return;

    final cardIdValue = card['id'];

    if (cardIdValue == null) {
      _showSnackBar(
        'Identifiant de carte introuvable.',
      );
      return;
    }

    final int? cardId = int.tryParse(
      cardIdValue.toString(),
    );

    if (cardId == null) {
      _showSnackBar(
        'Identifiant de carte invalide.',
      );
      return;
    }

    final cardType =
        card['cardType']?.toString() ?? 'Carte bancaire';

    final lastFour =
        card['lastFourDigits']?.toString() ?? '0000';

    final currentStatus =
        card['status']?.toString().trim().toUpperCase() ??
            'ACTIVE';

    if (currentStatus != 'BLOCKED') {
      _showSnackBar(
        'Une demande de déblocage est uniquement possible '
        'pour une carte bloquée.',
      );
      return;
    }

    final existingRequestStatus =
        _unblockRequestStatuses[cardId];

    // Une demande PENDING existe déjà.
    if (existingRequestStatus == 'PENDING') {
      _showSnackBar(
        'Une demande de déblocage est déjà en cours '
        'pour cette carte.',
      );
      return;
    }

    final messageController = TextEditingController();

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _orange.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock_open_rounded,
                    color: _orange,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Demander le déblocage',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votre carte $cardType •••• $lastFour est actuellement bloquée.',
                  style: const TextStyle(
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Votre demande sera transmise à la banque pour vérification.',
                  style: TextStyle(
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: InputDecoration(
                    labelText: 'Message (facultatif)',
                    hintText:
                        'Expliquez brièvement votre demande...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                ),
                child: const Text('Envoyer'),
              ),
            ],
          );
        },
      );

      if (confirmed != true || !mounted) {
        return;
      }

      setState(() {
        _processingCardId = cardId;
      });

      final message = messageController.text.trim();

      final response = await _apiService.post(
        '/api/cards/$cardId/unblock-request',
        body: {
          'userId': widget.userId,
          if (message.isNotEmpty) 'message': message,
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          _apiService.getErrorMessage(response),
        );
      }

      if (!mounted) return;

      setState(() {
        _processingCardId = null;
        _unblockRequestStatuses[cardId] = 'PENDING';
      });

      _showSnackBar(
        'Demande de déblocage envoyée à la banque.',
      );

      // Recharge les demandes pour synchroniser exactement
      // avec le backend.
      await _loadUnblockRequests();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _processingCardId = null;
      });

      _showSnackBar(
        'Impossible d’envoyer la demande de déblocage : '
        '${_extractError(error)}',
      );
    } finally {
      messageController.dispose();
    }
  }

  // ==========================================================================
  // ATTRIBUER UNE NOUVELLE CARTE
  // ==========================================================================
  //
  // Cette méthode est conservée pour ne pas supprimer la logique existante.
  // La section correspondante n'est plus affichée dans l'interface client.
  //
  // L'attribution destinée à la banque utilise maintenant :
  // POST /api/admin/cards/assign
  // ==========================================================================

  Future<void> _assignCard() async {
    if (_isAssigning) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.credit_card_rounded,
                  color: _blue,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Attribuer une carte',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Une nouvelle carte $_selectedCardType '
            'sera attribuée à ${widget.firstName}. '
            'Les cartes existantes ne seront pas modifiées.',
            style: const TextStyle(
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: _blue,
              ),
              child: const Text('Attribuer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isAssigning = true;
    });

    try {
      final response = await _apiService.post(
        '/api/cards/assign',
        body: {
          'userId': widget.userId,
          'cardType': _selectedCardType,
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          _apiService.getErrorMessage(response),
        );
      }

      final decoded = _apiService.decodeResponse(response);

      String message =
          'Carte $_selectedCardType attribuée avec succès.';

      if (decoded is Map) {
        final lastFour =
            decoded['lastFourDigits']?.toString();

        final expiry =
            decoded['expiryDate']?.toString();

        if (lastFour != null &&
            lastFour.isNotEmpty &&
            expiry != null &&
            expiry.isNotEmpty) {
          message =
              'Carte $_selectedCardType •••• $lastFour '
              'attribuée avec succès. '
              'Expiration : $expiry.';
        }
      }

      if (!mounted) return;

      setState(() {
        _isAssigning = false;
      });

      await _loadCards();

      if (!mounted) return;

      _showSnackBar(message);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isAssigning = false;
      });

      _showSnackBar(
        'Impossible d’attribuer la carte : '
        '${_extractError(error)}',
      );
    }
  }

  // ==========================================================================
  // UTILITAIRES
  // ==========================================================================

  String _extractError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(
        'Exception: '.length,
      );
    }

    return message;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'BLOCKED':
        return 'BLOQUÉE';

      case 'EXPIRED':
        return 'EXPIRÉE';

      default:
        return 'ACTIVE';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'BLOCKED':
        return _red;

      case 'EXPIRED':
        return Colors.orange;

      default:
        return _green;
    }
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark =
        theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? _darkBackground : _lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Gestion des cartes',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadCards,
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              30,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildClientSection(
                  theme: theme,
                  isDark: isDark,
                ),
                const SizedBox(height: 20),
                _buildCardsSection(
                  theme: theme,
                  isDark: isDark,
                ),

                // IMPORTANT :
                // La section d'attribution n'est plus affichée
                // dans l'espace client.
                //
                // L'attribution est maintenant gérée par :
                // AdminCardsScreen
                //
                // et l'API :
                // /api/admin/cards/assign
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // CLIENT
  // ==========================================================================

  Widget _buildClientSection({
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? _darkCardBackground
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _blue.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Client',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color
                  ?.withValues(alpha: 0.60),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: _blue.withValues(alpha: 0.18),
              ),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_rounded,
                  color: _blue,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.firstName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.account_balance_rounded,
                color: _blue,
                size: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compte courant',
                      style:
                          theme.textTheme.bodySmall?.copyWith(
                        color: theme
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(
                              alpha: 0.60,
                            ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _accountNumber.isEmpty
                          ? 'Numéro non disponible'
                          : _accountNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // CARTES
  // ==========================================================================

  Widget _buildCardsSection({
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? _darkCardBackground
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _blue.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.credit_card_rounded,
                color: _blue,
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Cartes actuelles',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${_cards.length}',
                style: const TextStyle(
                  color: _blue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(25),
                child: CircularProgressIndicator(
                  color: _blue,
                ),
              ),
            )
          else if (_cards.isEmpty)
            _buildEmptyCards(theme)
          else
            ..._cards.map(
              (card) => _buildCardRow(
                card,
                theme,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyCards(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 20,
      ),
      child: Center(
        child: Text(
          'Aucune carte attribuée.',
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }

  // ==========================================================================
  // CARTE INDIVIDUELLE
  // ==========================================================================

  Widget _buildCardRow(
    Map<String, dynamic> card,
    ThemeData theme,
  ) {
    final cardType =
        card['cardType']?.toString() ??
            'Carte bancaire';

    final lastFour =
        card['lastFourDigits']?.toString() ??
            '0000';

    final expiry =
        card['expiryDate']?.toString() ??
            '--/--';

    final status =
        card['status']
                ?.toString()
                .trim()
                .toUpperCase() ??
            'ACTIVE';

    final statusColor =
        _getStatusColor(status);

    final cardId =
        int.tryParse(
          card['id']?.toString() ?? '',
        );

    final isProcessing =
        cardId != null &&
            _processingCardId == cardId;

    final unblockRequestStatus =
        cardId == null
            ? null
            : _unblockRequestStatuses[cardId];

    final hasPendingRequest =
        unblockRequestStatus == 'PENDING';

    return Container(
      margin:
          const EdgeInsets.only(bottom: 10),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withValues(
          alpha: 0.055,
        ),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withValues(
            alpha: 0.14,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: _blue.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.credit_card_rounded,
                  color: _blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      cardType,
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '•••• $lastFour',
                      style: TextStyle(
                        color: theme
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(
                              alpha: 0.70,
                            ),
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Expire : $expiry',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(
                              alpha: 0.58,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusLabel(status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          // ------------------------------------------------------------------
          // DEMANDE EN COURS
          // ------------------------------------------------------------------

          if (status == 'BLOCKED' &&
              hasPendingRequest) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: _orange.withValues(
                  alpha: 0.08,
                ),
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                  color: _orange.withValues(
                    alpha: 0.20,
                  ),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.hourglass_top_rounded,
                    color: _orange,
                    size: 20,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Demande de déblocage en cours de vérification par la banque.',
                      style: TextStyle(
                        color: _orange,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]

          // ------------------------------------------------------------------
          // ACTIONS CLIENT : BLOQUER / DEMANDER LE DÉBLOCAGE
          // ------------------------------------------------------------------

          else if (status == 'ACTIVE' ||
              status == 'BLOCKED') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                onPressed: isProcessing
                    ? null
                    : () {
                        if (status == 'ACTIVE') {
                          _blockCard(card);
                        } else {
                          _requestUnblock(card);
                        }
                      },
                icon: isProcessing
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        status == 'ACTIVE'
                            ? Icons.block_rounded
                            : Icons.lock_open_rounded,
                      ),
                label: Text(
                  isProcessing
                      ? status == 'ACTIVE'
                          ? 'Blocage en cours...'
                          : 'Envoi de la demande...'
                      : status == 'ACTIVE'
                          ? 'Bloquer la carte'
                          : 'Demander le déblocage',
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      status == 'ACTIVE'
                          ? _red
                          : _blue,
                  side: BorderSide(
                    color:
                        status == 'ACTIVE'
                            ? _red
                            : _blue,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================================
  // ATTRIBUTION
  // ==========================================================================
  //
  // Conservée dans le code pour ne pas supprimer la logique existante.
  // Cette section n'est volontairement plus appelée depuis build().
  //
  // L'interface Banque / Administration possède maintenant sa propre
  // attribution via /api/admin/cards/assign.
  // ==========================================================================

  Widget _buildAssignSection({
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? _darkCardBackground
            : Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: _blue.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Attribuer une carte',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Attribuez une nouvelle carte au client '
            'sans modifier ses cartes existantes.',
            style:
                theme.textTheme.bodyMedium?.copyWith(
              color: theme
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.65),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: _selectedCardType,
            decoration: InputDecoration(
              labelText: 'Type de carte',
              prefixIcon: const Icon(
                Icons.credit_card_rounded,
                color: _blue,
              ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
            ),
            items: _cardTypes.map(
              (type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              },
            ).toList(),
            onChanged: _isAssigning
                ? null
                : (value) {
                    if (value == null) return;

                    setState(() {
                      _selectedCardType = value;
                    });
                  },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed:
                  _isAssigning
                      ? null
                      : _assignCard,
              icon: _isAssigning
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.add_card_rounded,
                    ),
              label: Text(
                _isAssigning
                    ? 'Attribution en cours...'
                    : 'Attribuer la carte',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              style:
                  FilledButton.styleFrom(
                backgroundColor: _blue,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
