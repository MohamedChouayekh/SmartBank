import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'card_management_screen.dart';

class CardsScreen extends StatefulWidget {
  final int userId;
  final String firstName;
  final double courantBalance;
  final ValueChanged<double>? onCourantBalanceChanged;

  const CardsScreen({
    super.key,
    required this.userId,
    required this.firstName,
    required this.courantBalance,
    this.onCourantBalanceChanged,
  });

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

// ============================================================================
// STATE
// ============================================================================

class _CardsScreenState extends State<CardsScreen> {
  // --------------------------------------------------------------------------
  // COULEURS
  // --------------------------------------------------------------------------

  static const Color _blue = Color(0xFF0B5AA6);
  static const Color _darkBlue = Color(0xFF06457E);
  static const Color _green = Color(0xFF087A5B);
  static const Color _yellow = Color(0xFFF4C542);
  static const Color _red = Color(0xFFC62828);

  static const Color _lightBackground = Color(0xFFF5F7FA);
  static const Color _darkBackground = Color(0xFF0F1723);
  static const Color _darkCardBackground = Color(0xFF182236);

  static const Color _mastercardDark = Color(0xFF202735);
  static const Color _mastercardDarker = Color(0xFF111722);

  // --------------------------------------------------------------------------
  // SERVICES
  // --------------------------------------------------------------------------

  final ApiService _apiService = ApiService();

  // --------------------------------------------------------------------------
  // STATE
  // --------------------------------------------------------------------------

  List<Map<String, dynamic>> _cards = [];

  bool _isLoading = true;

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
  // CHARGEMENT DES CARTES
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

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          _apiService.getErrorMessage(response),
        );
      }

      final decoded =
          _apiService.decodeResponse(response);

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

      if (!mounted) return;

      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnackBar(
        'Impossible de charger les cartes : ${_extractError(error)}',
      );
    }
  }

  // ==========================================================================
  // GESTION DES CARTES
  // ==========================================================================

  Future<void> _openCardManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CardManagementScreen(
          userId: widget.userId,
          firstName: widget.firstName,
        ),
      ),
    );

    if (!mounted) return;

    await _loadCards();
  }

  // ==========================================================================
  // RETRAIT D'ESPÈCES
  // ==========================================================================

  Future<void> _showWithdrawalDialog(
    Map<String, dynamic> card,
  ) async {
    final amountController =
        TextEditingController();

    final cardId = card['id'];

    final result = await showDialog<_WithdrawalResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _WithdrawalDialog(
          card: card,
          courantBalance: widget.courantBalance,
          amountController: amountController,
          onWithdraw: (
            amountText,
          ) async {
            return _performWithdrawal(
              cardId: cardId,
              amountText: amountText,
            );
          },
        );
      },
    );

    amountController.dispose();

    if (!mounted) return;

    if (result == null) {
      return;
    }

    if (result.success) {
      if (result.newBalance != null) {
        widget.onCourantBalanceChanged
            ?.call(result.newBalance!);
      }

      _showSnackBar(
        'Retrait de ${result.amount.toStringAsFixed(3)} TND effectué avec succès.',
      );
    } else if (result.errorMessage != null) {
      _showSnackBar(
        result.errorMessage!,
      );
    }
  }

  Future<_WithdrawalResult> _performWithdrawal({
    required dynamic cardId,
    required String amountText,
  }) async {
    final rawAmount =
        amountText.trim().replaceAll(',', '.');

    final amount =
        double.tryParse(rawAmount);

    if (amount == null || amount <= 0) {
      return const _WithdrawalResult.failure(
        'Veuillez saisir un montant valide.',
      );
    }

    if (amount > widget.courantBalance) {
      return const _WithdrawalResult.failure(
        'Solde insuffisant.',
      );
    }

    try {
      final response =
          await _apiService.post(
        '/api/cards/$cardId/withdraw',
        body: {
          'userId': widget.userId,
          'amount': amount,
        },
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        return _WithdrawalResult.failure(
          _apiService.getErrorMessage(
            response,
          ),
        );
      }

      final decoded =
          _apiService.decodeResponse(response);

      double? newBalance;

      if (decoded is Map &&
          decoded['newBalance'] != null) {
        newBalance = double.tryParse(
          decoded['newBalance'].toString(),
        );
      }

      return _WithdrawalResult.success(
        amount: amount,
        newBalance: newBalance,
      );
    } catch (error) {
      return _WithdrawalResult.failure(
        _extractError(error),
      );
    }
  }

  // ==========================================================================
  // STATUT DE LA CARTE
  // ==========================================================================

  String _getCardStatus(
    Map<String, dynamic> card,
  ) {
    final status = card['status']
        ?.toString()
        .trim()
        .toUpperCase();

    if (status == 'BLOCKED') {
      return 'BLOCKED';
    }

    if (status == 'EXPIRED') {
      return 'EXPIRED';
    }

    return 'ACTIVE';
  }

  String _getStatusLabel(
    String status,
  ) {
    switch (status) {
      case 'BLOCKED':
        return 'Carte bloquée';

      case 'EXPIRED':
        return 'Carte expirée';

      case 'ACTIVE':
      default:
        return 'Carte active';
    }
  }

  Color _getStatusColor(
    String status,
  ) {
    switch (status) {
      case 'BLOCKED':
        return _red;

      case 'EXPIRED':
        return Colors.orange;

      case 'ACTIVE':
      default:
        return _green;
    }
  }

  IconData _getStatusIcon(
    String status,
  ) {
    switch (status) {
      case 'BLOCKED':
        return Icons.lock_rounded;

      case 'EXPIRED':
        return Icons.event_busy_rounded;

      case 'ACTIVE':
      default:
        return Icons.check_circle_rounded;
    }
  }

  // ==========================================================================
  // UTILITAIRES
  // ==========================================================================

  String _extractError(
    Object error,
  ) {
    final message = error.toString();

    if (message.startsWith(
      'Exception: ',
    )) {
      return message.substring(
        'Exception: '.length,
      );
    }

    return message;
  }

  void _showSnackBar(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  // ==========================================================================
  // DESIGN DES CARTES
  // ==========================================================================

  String _formatCardNumber(
    String lastFourDigits,
  ) {
    return '••••  ••••  ••••  $lastFourDigits';
  }

  Color _getCardColor1(
    String cardType,
  ) {
    if (cardType
        .toLowerCase()
        .contains('visa')) {
      return _blue;
    }

    return _mastercardDark;
  }

  Color _getCardColor2(
    String cardType,
  ) {
    if (cardType
        .toLowerCase()
        .contains('visa')) {
      return _darkBlue;
    }

    return _mastercardDarker;
  }

  String _getCardLogo(
    String cardType,
  ) {
    if (cardType
        .toLowerCase()
        .contains('visa')) {
      return 'VISA';
    }

    return '●●';
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final isDark =
        theme.brightness ==
            Brightness.dark;

    final fullName =
        widget.firstName.trim().isEmpty
            ? 'SMARTBANK CLIENT'
            : widget.firstName
                .toUpperCase();

    return Scaffold(
      backgroundColor:
          isDark
              ? _darkBackground
              : _lightBackground,
      appBar: AppBar(
        backgroundColor:
            Colors.transparent,
        elevation: 0,
        title: const Text(
          'Mes cartes',
          style: TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadCards,
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
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                _buildHeader(
                  theme,
                ),
                const SizedBox(
                  height: 22,
                ),
                _buildCardsSection(
                  context: context,
                  theme: theme,
                  isDark: isDark,
                  fullName: fullName,
                ),
                const SizedBox(
                  height: 18,
                ),
                _buildAdminTestButton(
                  theme: theme,
                  isDark: isDark,
                ),
                const SizedBox(
                  height: 18,
                ),
                _buildSecuritySection(
                  theme: theme,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // GESTION DES CARTES
  // ==========================================================================

  Widget _buildAdminTestButton({
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? _darkCardBackground
            : Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: _darkBlue.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                    BoxDecoration(
                  color:
                      _darkBlue.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: const Icon(
                  Icons
                      .account_balance_rounded,
                  color: _darkBlue,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      'Gestion des cartes',
                      style: theme
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      'Bloquer, débloquer et gérer le statut de vos cartes.',
                      style: theme
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        color: theme
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(
                          alpha: 0.65,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 14,
          ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child:
                FilledButton.icon(
              onPressed:
                  _openCardManagement,
              icon: const Icon(
                Icons
                    .manage_accounts_rounded,
              ),
              label: const Text(
                'Gérer les cartes',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    _darkBlue,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'Vos cartes bancaires',
          style: theme
              .textTheme
              .headlineSmall
              ?.copyWith(
            fontWeight:
                FontWeight.w800,
          ),
        ),
        const SizedBox(
          height: 6,
        ),
        Text(
          'Gérez vos moyens de paiement SmartBank.',
          style: theme
              .textTheme
              .bodyMedium
              ?.copyWith(
            color: theme
                .textTheme
                .bodyMedium
                ?.color
                ?.withValues(
              alpha: 0.68,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardsSection({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required String fullName,
  }) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding:
              EdgeInsets.symmetric(
            vertical: 50,
          ),
          child:
              CircularProgressIndicator(
            color: _blue,
          ),
        ),
      );
    }

    if (_cards.isEmpty) {
      return _buildEmptyCardsState(
        theme: theme,
        isDark: isDark,
      );
    }

    return Column(
      children: _cards.map(
        (card) {
          return _buildCardItem(
            context: context,
            card: card,
            fullName: fullName,
          );
        },
      ).toList(),
    );
  }

  Widget _buildEmptyCardsState({
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? _darkCardBackground
            : Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: _blue.withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons
                .credit_card_off_rounded,
            size: 48,
            color: _blue,
          ),
          const SizedBox(
            height: 12,
          ),
          const Text(
            'Aucune carte',
            style: TextStyle(
              fontWeight:
                  FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            'Votre carte bancaire sera attribuée par SmartBank.',
            textAlign:
                TextAlign.center,
            style: theme
                .textTheme
                .bodyMedium
                ?.copyWith(
              color: theme
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(
                alpha: 0.65,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem({
    required BuildContext context,
    required Map<String, dynamic> card,
    required String fullName,
  }) {
    final cardType =
        card['cardType']
                ?.toString() ??
            'Carte bancaire';

    final lastFour =
        card['lastFourDigits']
                ?.toString() ??
            '0000';

    final expiry =
        card['expiryDate']
                ?.toString() ??
            '--/--';

    final status =
        _getCardStatus(card);

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 18,
      ),
      child: Column(
        children: [
          _buildBankCard(
            context: context,
            cardType: cardType,
            number:
                _formatCardNumber(
              lastFour,
            ),
            holder: fullName,
            expiry: expiry,
            color1:
                _getCardColor1(
              cardType,
            ),
            color2:
                _getCardColor2(
              cardType,
            ),
            logo:
                _getCardLogo(
              cardType,
            ),
            chipColor:
                _yellow,
            status: status,
          ),
          const SizedBox(
            height: 10,
          ),
          _buildCardStatus(
            status,
          ),
          const SizedBox(
            height: 10,
          ),
          _buildWithdrawalButton(
            card,
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // STATUT VISUEL
  // ==========================================================================

  Widget _buildCardStatus(
    String status,
  ) {
    final statusColor =
        _getStatusColor(status);

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: statusColor
            .withValues(alpha: 0.09),
        borderRadius:
            BorderRadius.circular(13),
        border: Border.all(
          color: statusColor
              .withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(status),
            color: statusColor,
            size: 20,
          ),
          const SizedBox(
            width: 9,
          ),
          Expanded(
            child: Text(
              _getStatusLabel(
                status,
              ),
              style: TextStyle(
                color: statusColor,
                fontWeight:
                    FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // RETRAIT
  // ==========================================================================

  Widget _buildWithdrawalButton(
    Map<String, dynamic> card,
  ) {
    final status =
        _getCardStatus(card);

    final isActive =
        status == 'ACTIVE';

    return SizedBox(
      width: double.infinity,
      height: 48,
      child:
          OutlinedButton.icon(
        onPressed: isActive
            ? () =>
                _showWithdrawalDialog(
                  card,
                )
            : null,
        icon: const Icon(
          Icons.atm_rounded,
        ),
        label: Text(
          isActive
              ? 'Retrait d’espèces'
              : 'Retrait indisponible',
          style: const TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
        style:
            OutlinedButton.styleFrom(
          foregroundColor: isActive
              ? _blue
              : Colors.grey,
          side: BorderSide(
            color: isActive
                ? _blue.withValues(
                    alpha: 0.30,
                  )
                : Colors.grey.withValues(
                    alpha: 0.25,
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
    );
  }

  // ==========================================================================
  // SECTION SÉCURITÉ
  // ==========================================================================

  Widget _buildSecuritySection({
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? _darkCardBackground
            : Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: _blue.withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(
              color: _yellow.withValues(
                alpha: 0.18,
              ),
              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),
            child: const Icon(
              Icons.security_rounded,
              color: _darkBlue,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                const Text(
                  'Paiements sécurisés',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  'Vos informations de carte restent protégées.',
                  style: TextStyle(
                    color: theme
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(
                      alpha: 0.68,
                    ),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // DESIGN DE LA CARTE BANCAIRE
  // ==========================================================================

  Widget _buildBankCard({
    required BuildContext context,
    required String cardType,
    required String number,
    required String holder,
    required String expiry,
    required Color color1,
    required Color color2,
    required String logo,
    required Color chipColor,
    required String status,
  }) {
    final statusColor =
        _getStatusColor(status);

    final isActive =
        status == 'ACTIVE';

    return Container(
      width: double.infinity,
      height: 215,
      decoration: BoxDecoration(
        gradient:
            LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            color1,
            color2,
          ],
        ),
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color1
                .withValues(
              alpha: 0.30,
            ),
            blurRadius: 22,
            offset:
                const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -40,
            child:
                _buildDecorativeCircle(
              size: 160,
              opacity: 0.06,
            ),
          ),
          Positioned(
            left: -40,
            bottom: -65,
            child:
                _buildDecorativeCircle(
              size: 150,
              opacity: 0.04,
            ),
          ),

          // ------------------------------------------------------------------
          // BADGE STATUT
          // ------------------------------------------------------------------

          Positioned(
            right: 18,
            top: 54,
            child: Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.black
                    .withValues(
                  alpha: 0.24,
                ),
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
                border: Border.all(
                  color: Colors.white
                      .withValues(
                    alpha: 0.18,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(
                      status,
                    ),
                    color: isActive
                        ? Colors.white
                        : statusColor,
                    size: 13,
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Text(
                    status,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w800,
                      letterSpacing:
                          0.7,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.all(
              20,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                _buildCardTopRow(
                  cardType: cardType,
                  logo: logo,
                ),
                const SizedBox(
                  height: 12,
                ),
                _buildChip(
                  color: chipColor,
                  backgroundColor:
                      color1,
                ),
                const Spacer(),
                Text(
                  number,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w500,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(
                  height: 17,
                ),
                _buildCardBottomRow(
                  holder: holder,
                  expiry: expiry,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeCircle({
    required double size,
    required double opacity,
  }) {
    return Container(
      width: size,
      height: size,
      decoration:
          BoxDecoration(
        shape:
            BoxShape.circle,
        color: Colors.white
            .withValues(
          alpha: opacity,
        ),
      ),
    );
  }

  Widget _buildCardTopRow({
    required String cardType,
    required String logo,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment
              .spaceBetween,
      children: [
        Text(
          cardType,
          style: TextStyle(
            color: Colors.white
                .withValues(
              alpha: 0.80,
            ),
            fontSize: 13,
            fontWeight:
                FontWeight.w600,
          ),
        ),
        Text(
          logo,
          style:
              const TextStyle(
            color:
                Colors.white,
            fontSize: 18,
            fontWeight:
                FontWeight.w900,
            letterSpacing:
                1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildChip({
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      width: 45,
      height: 32,
      decoration:
          BoxDecoration(
        color: color,
        borderRadius:
            BorderRadius.circular(
          7,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 14,
            top: 0,
            bottom: 0,
            child: Container(
              width: 1,
              color: backgroundColor
                  .withValues(
                alpha: 0.28,
              ),
            ),
          ),
          Positioned(
            top: 15,
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              color: backgroundColor
                  .withValues(
                alpha: 0.28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBottomRow({
    required String holder,
    required String expiry,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildCardInfo(
            label: 'TITULAIRE',
            value: holder,
          ),
        ),
        _buildCardInfo(
          label: 'EXPIRE',
          value: expiry,
        ),
      ],
    );
  }

  Widget _buildCardInfo({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment
              .start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white
                .withValues(
              alpha: 0.52,
            ),
            fontSize: 9,
            fontWeight:
                FontWeight.w600,
          ),
        ),
        const SizedBox(
          height: 3,
        ),
        Text(
          value,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style:
              const TextStyle(
            color:
                Colors.white,
            fontSize: 13,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// RÉSULTAT DU RETRAIT
// ============================================================================

class _WithdrawalResult {
  final bool success;
  final double amount;
  final double? newBalance;
  final String? errorMessage;

  const _WithdrawalResult({
    required this.success,
    required this.amount,
    this.newBalance,
    this.errorMessage,
  });

  const _WithdrawalResult.success({
    required double amount,
    double? newBalance,
  }) : this(
          success: true,
          amount: amount,
          newBalance: newBalance,
        );

  const _WithdrawalResult.failure(
    String message,
  ) : this(
          success: false,
          amount: 0,
          errorMessage: message,
        );
}

// ============================================================================
// DIALOGUE DE RETRAIT
// ============================================================================

class _WithdrawalDialog extends StatefulWidget {
  final Map<String, dynamic> card;
  final double courantBalance;
  final TextEditingController amountController;
  final Future<_WithdrawalResult> Function(
    String amountText,
  ) onWithdraw;

  const _WithdrawalDialog({
    required this.card,
    required this.courantBalance,
    required this.amountController,
    required this.onWithdraw,
  });

  @override
  State<_WithdrawalDialog> createState() =>
      _WithdrawalDialogState();
}

class _WithdrawalDialogState
    extends State<_WithdrawalDialog> {
  bool _isWithdrawing = false;

  // ==========================================================================
  // CONFIRMATION DU RETRAIT
  // ==========================================================================

  Future<void> _confirmWithdrawal() async {
    if (_isWithdrawing) {
      return;
    }

    final rawAmount =
        widget.amountController.text
            .trim()
            .replaceAll(',', '.');

    final amount =
        double.tryParse(rawAmount);

    if (amount == null || amount <= 0) {
      _showError(
        'Veuillez saisir un montant valide.',
      );
      return;
    }

    if (amount > widget.courantBalance) {
      _showError(
        'Solde insuffisant.',
      );
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isWithdrawing = true;
    });

    final result =
        await widget.onWithdraw(
      widget.amountController.text,
    );

    if (!mounted) {
      return;
    }

    if (result.success) {
      Navigator.of(context).pop(
        result,
      );
      return;
    }

    setState(() {
      _isWithdrawing = false;
    });

    if (result.errorMessage != null) {
      _showError(
        result.errorMessage!,
      );
    }
  }

  // ==========================================================================
  // MESSAGE D'ERREUR DANS LE DIALOGUE
  // ==========================================================================

  void _showError(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final textColor = theme
        .textTheme
        .bodyMedium
        ?.color
        ?.withValues(
      alpha: 0.65,
    );

    final cardType =
        widget.card['cardType']
                ?.toString() ??
            'Carte bancaire';

    final lastFour =
        widget.card['lastFourDigits']
                ?.toString() ??
            '0000';

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
      ),
      title: const Text(
        'Retrait d’espèces',
        style: TextStyle(
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            '$cardType •••• $lastFour',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Compte courant associé',
            style: TextStyle(
              color: textColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Solde disponible',
            style: TextStyle(
              color: textColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${widget.courantBalance.toStringAsFixed(3)} TND',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0B5AA6),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller:
                widget.amountController,
            enabled: !_isWithdrawing,
            keyboardType:
                const TextInputType
                    .numberWithOptions(
              decimal: true,
            ),
            decoration:
                InputDecoration(
              labelText:
                  'Montant du retrait',
              hintText:
                  'Ex. 200',
              suffixText:
                  'TND',
              prefixIcon:
                  const Icon(
                Icons
                    .payments_rounded,
              ),
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed:
              _isWithdrawing
                  ? null
                  : () {
                      Navigator.of(
                        context,
                      ).pop();
                    },
          child:
              const Text(
            'Annuler',
          ),
        ),
        FilledButton(
          onPressed:
              _isWithdrawing
                  ? null
                  : _confirmWithdrawal,
          style:
              FilledButton.styleFrom(
            backgroundColor:
                const Color(0xFF087A5B),
          ),
          child: _isWithdrawing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Confirmer',
                ),
        ),
      ],
    );
  }
}
