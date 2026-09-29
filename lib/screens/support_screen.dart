import 'package:flutter/material.dart';

import '../services/api_service.dart';

class SupportScreen extends StatefulWidget {
  final int userId;

  const SupportScreen({
    super.key,
    required this.userId,
  });

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  static const Color _blue = Color(0xFF0B5AA6);
  static const Color _darkBlue = Color(0xFF06457E);
  static const Color _green = Color(0xFF087A5B);
  static const Color _orange = Color(0xFFE67E22);
  static const Color _red = Color(0xFFC62828);

  static const Color _lightBackground = Color(0xFFF5F7FA);
  static const Color _darkBackground = Color(0xFF0F1723);
  static const Color _darkCardBackground = Color(0xFF182236);

  final ApiService _apiService = ApiService();

  final List<Map<String, dynamic>> _categories = [
    {
      'value': 'CARTE',
      'title': 'Cartes',
      'subtitle':
          'Carte bloquée, perdue ou problème avec ma carte',
      'icon': Icons.credit_card_rounded,
    },
    {
      'value': 'VIREMENT',
      'title': 'Virements',
      'subtitle':
          'Problème avec un virement ou un bénéficiaire',
      'icon': Icons.swap_horiz_rounded,
    },
    {
      'value': 'PAIEMENT',
      'title': 'Paiements & factures',
      'subtitle':
          'Paiement, facture ou recharge',
      'icon': Icons.receipt_long_rounded,
    },
    {
      'value': 'SECURITE',
      'title': 'Sécurité',
      'subtitle':
          'Connexion, mot de passe ou activité suspecte',
      'icon': Icons.security_rounded,
    },
    {
      'value': 'COMPTE',
      'title': 'Compte',
      'subtitle':
          'Compte courant, épargne ou informations personnelles',
      'icon': Icons.account_balance_rounded,
    },
    {
      'value': 'APPLICATION',
      'title': 'Application',
      'subtitle':
          'Problème technique avec SmartBank',
      'icon': Icons.phone_android_rounded,
    },
    {
      'value': 'AUTRE',
      'title': 'Autre',
      'subtitle':
          'Une autre question ou demande',
      'icon': Icons.help_outline_rounded,
    },
  ];

  List<Map<String, dynamic>> _requests = [];

  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  // =========================================================
  // CHARGER LES DEMANDES
  // =========================================================

  Future<void> _loadRequests() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.get(
        '/api/support/user/${widget.userId}',
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

      final requests = decoded
          .whereType<Map>()
          .map(
            (item) =>
                Map<String, dynamic>.from(item),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnackBar(
        'Impossible de charger vos demandes : '
        '${_extractError(error)}',
      );
    }
  }

  // =========================================================
  // OUVRIR LE FORMULAIRE
  // =========================================================

  Future<void> _openSupportForm() async {
    final result =
        await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SupportFormSheet(
          categories: _categories,
          apiService: _apiService,
          userId: widget.userId,
        );
      },
    );

    if (result == true) {
      await _loadRequests();

      if (!mounted) return;

      _showSnackBar(
        'Votre demande a été envoyée au support.',
      );
    }
  }

  // =========================================================
  // DÉTAIL D'UNE DEMANDE
  // =========================================================

  void _showRequestDetails(
    Map<String, dynamic> request,
  ) {
    final theme = Theme.of(context);

    final category =
        request['category']?.toString() ?? 'AUTRE';

    final categoryInfo =
        _getCategoryInfo(category);

    final subject =
        request['subject']?.toString() ?? '';

    final message =
        request['message']?.toString() ?? '';

    final adminResponse =
        request['adminResponse']?.toString() ?? '';

    final status =
        request['status']
                ?.toString()
                .trim()
                .toUpperCase() ??
            'OPEN';

    final createdAt =
        request['createdAt']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark =
            theme.brightness ==
                Brightness.dark;

        return Container(
          constraints:
              const BoxConstraints(
            maxHeight: 720,
          ),
          padding:
              const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            25,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? _darkBackground
                : Colors.white,
            borderRadius:
                const BorderRadius.vertical(
              top: Radius.circular(26),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration:
                          BoxDecoration(
                        color: theme
                            .dividerColor,
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration:
                            BoxDecoration(
                          color: _blue.withValues(
                            alpha: 0.10,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                        child: Icon(
                          categoryInfo['icon']
                              as IconData,
                          color: _blue,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          subject,
                          style:
                              const TextStyle(
                            fontSize: 19,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildStatusChip(
                    status,
                  ),

                  if (createdAt.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Demande envoyée : '
                      '${_formatDate(createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(
                              alpha: 0.60,
                            ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),

                  const Text(
                    'Votre message',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 8),

                  _buildMessageContainer(
                    context,
                    message,
                  ),

                  if (adminResponse
                      .trim()
                      .isNotEmpty) ...[
                    const SizedBox(height: 20),

                    const Text(
                      'Réponse du support',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(
                        15,
                      ),
                      decoration:
                          BoxDecoration(
                        color: _green.withValues(
                          alpha: 0.07,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                        border: Border.all(
                          color:
                              _green.withValues(
                            alpha: 0.16,
                          ),
                        ),
                      ),
                      child: Text(
                        adminResponse,
                        style:
                            const TextStyle(
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pop(
                        context,
                      ),
                      child: const Text(
                        'Fermer',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // INFOS CATÉGORIE
  // =========================================================

  Map<String, dynamic> _getCategoryInfo(
    String value,
  ) {
    for (final category in _categories) {
      if (category['value'] == value) {
        return category;
      }
    }

    return _categories.last;
  }

  // =========================================================
  // STATUT
  // =========================================================

  Widget _buildStatusChip(
    String status,
  ) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'IN_PROGRESS':
        color = _blue;
        label = 'En cours de traitement';
        icon = Icons.sync_rounded;
        break;

      case 'RESOLVED':
        color = _green;
        label = 'Résolue';
        icon =
            Icons.check_circle_outline_rounded;
        break;

      case 'CLOSED':
        color = Colors.grey;
        label = 'Fermée';
        icon = Icons.lock_outline_rounded;
        break;

      default:
        color = _orange;
        label = 'En attente';
        icon =
            Icons.hourglass_empty_rounded;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.10,
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 17,
            color: color,
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContainer(
    BuildContext context,
    String message,
  ) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark
            ? _darkCardBackground
            : _lightBackground,
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Text(
        message,
        style: const TextStyle(
          height: 1.5,
        ),
      ),
    );
  }

  // =========================================================
  // DATE
  // =========================================================

  String _formatDate(String value) {
    try {
      final date =
          DateTime.parse(value).toLocal();

      final day =
          date.day.toString().padLeft(2, '0');

      final month =
          date.month.toString().padLeft(2, '0');

      final hour =
          date.hour.toString().padLeft(2, '0');

      final minute =
          date.minute.toString().padLeft(2, '0');

      return '$day/$month/${date.year} à $hour:$minute';
    } catch (_) {
      return value;
    }
  }

  // =========================================================
  // ERREUR
  // =========================================================

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
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark =
        theme.brightness ==
            Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? _darkBackground
          : _lightBackground,

      appBar: AppBar(
        backgroundColor:
            Colors.transparent,
        elevation: 0,
        title: const Text(
          'Aide & Support',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRequests,
          child: SingleChildScrollView(
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
                  CrossAxisAlignment.start,
              children: [
                // =================================================
                // INTRODUCTION
                // =================================================

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(20),
                  decoration:
                      BoxDecoration(
                    gradient:
                        const LinearGradient(
                      begin:
                          Alignment.topLeft,
                      end:
                          Alignment.bottomRight,
                      colors: [
                        _blue,
                        _darkBlue,
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration:
                            BoxDecoration(
                          color: Colors.white
                              .withValues(
                            alpha: 0.14,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            15,
                          ),
                        ),
                        child: const Icon(
                          Icons
                              .support_agent_rounded,
                          color: Colors.white,
                          size: 29,
                        ),
                      ),

                      const SizedBox(width: 14),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Comment pouvons-nous vous aider ?',
                              style: TextStyle(
                                color:
                                    Colors.white,
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Consultez les sujets fréquents ou contactez directement le support SmartBank.',
                              style: TextStyle(
                                color:
                                    Colors.white70,
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // =================================================
                // QUESTIONS FRÉQUENTES
                // =================================================

                const Text(
                  'Questions fréquentes',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 10),

                ..._categories.map(
                  (category) =>
                      _buildCategoryTile(
                    context,
                    category,
                    isDark,
                  ),
                ),

                const SizedBox(height: 20),

                // =================================================
                // CONTACT SUPPORT
                // =================================================

                const Text(
                  'Contacter le support',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed:
                        _isSending
                            ? null
                            : _openSupportForm,
                    icon: const Icon(
                      Icons
                          .chat_bubble_outline_rounded,
                    ),
                    label: const Text(
                      'Envoyer une demande',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    style:
                        FilledButton.styleFrom(
                      backgroundColor:
                          _blue,
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

                const SizedBox(height: 25),

                // =================================================
                // MES DEMANDES
                // =================================================

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Mes demandes',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),

                    if (_requests.isNotEmpty)
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration:
                            BoxDecoration(
                          color: _blue
                              .withValues(
                            alpha: 0.10,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            20,
                          ),
                        ),
                        child: Text(
                          '${_requests.length}',
                          style:
                              const TextStyle(
                            color: _blue,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding:
                          EdgeInsets.all(25),
                      child:
                          CircularProgressIndicator(
                        color: _blue,
                      ),
                    ),
                  )
                else if (_requests.isEmpty)
                  _buildNoRequests(
                    context,
                    isDark,
                  )
                else
                  ..._requests.map(
                    (request) =>
                        _buildRequestTile(
                      context,
                      request,
                      isDark,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // CATÉGORIE
  // =========================================================

  Widget _buildCategoryTile(
    BuildContext context,
    Map<String, dynamic> category,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark
            ? _darkCardBackground
            : Colors.white,
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 3,
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _blue.withValues(
              alpha: 0.10,
            ),
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: Icon(
            category['icon']
                as IconData,
            color: _blue,
          ),
        ),
        title: Text(
          category['title']
              .toString(),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          category['subtitle']
              .toString(),
          style: const TextStyle(
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // AUCUNE DEMANDE
  // =========================================================

  Widget _buildNoRequests(
    BuildContext context,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: isDark
            ? _darkCardBackground
            : Colors.white,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons
                .mark_email_unread_outlined,
            size: 42,
            color: _blue.withValues(
              alpha: 0.65,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Aucune demande pour le moment.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Vos échanges avec le support apparaîtront ici.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(
                    alpha: 0.60,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DEMANDE
  // =========================================================

  Widget _buildRequestTile(
    BuildContext context,
    Map<String, dynamic> request,
    bool isDark,
  ) {
    final category =
        request['category']
                ?.toString() ??
            'AUTRE';

    final categoryInfo =
        _getCategoryInfo(category);

    final subject =
        request['subject']
                ?.toString() ??
            '';

    final message =
        request['message']
                ?.toString() ??
            '';

    final status =
        request['status']
                ?.toString()
                .trim()
                .toUpperCase() ??
            'OPEN';

    final adminResponse =
        request['adminResponse']
                ?.toString()
                .trim() ??
            '';

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark
            ? _darkCardBackground
            : Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: adminResponse.isNotEmpty
            ? Border.all(
                color:
                    _green.withValues(
                  alpha: 0.18,
                ),
              )
            : null,
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(16),
        onTap: () =>
            _showRequestDetails(
          request,
        ),
        child: Padding(
          padding:
              const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration:
                    BoxDecoration(
                  color:
                      _blue.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  categoryInfo['icon']
                      as IconData,
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
                      subject,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      message,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(
                              alpha: 0.65,
                            ),
                      ),
                    ),

                    const SizedBox(height: 9),

                    _buildStatusChip(
                      status,
                    ),

                    if (adminResponse
                        .isNotEmpty) ...[
                      const SizedBox(height: 7),

                      Row(
                        children: [
                          const Icon(
                            Icons
                                .mark_chat_read_rounded,
                            color: _green,
                            size: 16,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          const Text(
                            'Le support a répondu',
                            style: TextStyle(
                              color: _green,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.chevron_right_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// FORMULAIRE DE SUPPORT
// ============================================================================

class _SupportFormSheet extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final ApiService apiService;
  final int userId;

  const _SupportFormSheet({
    required this.categories,
    required this.apiService,
    required this.userId,
  });

  @override
  State<_SupportFormSheet> createState() =>
      _SupportFormSheetState();
}

class _SupportFormSheetState
    extends State<_SupportFormSheet> {
  static const Color _blue =
      Color(0xFF0B5AA6);

  String? _selectedCategory;

  final TextEditingController
      _subjectController =
      TextEditingController();

  final TextEditingController
      _messageController =
      TextEditingController();

  bool _isSending = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // =========================================================
  // ENVOYER
  // =========================================================

  Future<void> _sendRequest() async {
    if (_isSending) return;

    final category =
        _selectedCategory;

    final subject =
        _subjectController.text.trim();

    final message =
        _messageController.text.trim();

    if (category == null ||
        category.isEmpty) {
      _showError(
        'Veuillez sélectionner une catégorie.',
      );
      return;
    }

    if (subject.isEmpty) {
      _showError(
        'Veuillez saisir un sujet.',
      );
      return;
    }

    if (message.isEmpty) {
      _showError(
        'Veuillez saisir votre message.',
      );
      return;
    }

    if (subject.length > 150) {
      _showError(
        'Le sujet ne doit pas dépasser 150 caractères.',
      );
      return;
    }

    if (message.length > 2000) {
      _showError(
        'Le message ne doit pas dépasser 2000 caractères.',
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final response =
          await widget.apiService.post(
        '/api/support',
        body: {
          'userId': widget.userId,
          'category': category,
          'subject': subject,
          'message': message,
        },
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          widget.apiService
              .getErrorMessage(response),
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSending = false;
      });

      _showError(
        _extractError(error),
      );
    }
  }

  String _extractError(Object error) {
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

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final isDark =
        theme.brightness ==
            Brightness.dark;

    return Container(
      constraints:
          const BoxConstraints(
        maxHeight: 760,
      ),
      padding:
          EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 +
            MediaQuery.of(context)
                .viewInsets
                .bottom,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F1723)
            : Colors.white,
        borderRadius:
            const BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration:
                      BoxDecoration(
                    color: theme
                        .dividerColor,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Contacter le support',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Décrivez votre problème et notre équipe pourra traiter votre demande.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: theme
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(
                        alpha: 0.65,
                      ),
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // CATÉGORIE
              // =================================================

              DropdownButtonFormField<String>(
                initialValue:
                    _selectedCategory,
                decoration:
                    InputDecoration(
                  labelText:
                      'Catégorie',
                  prefixIcon:
                      const Icon(
                    Icons.category_outlined,
                    color: _blue,
                  ),
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
                items:
                    widget.categories.map(
                  (category) {
                    return DropdownMenuItem<
                        String>(
                      value:
                          category['value']
                              .toString(),
                      child: Text(
                        category['title']
                            .toString(),
                      ),
                    );
                  },
                ).toList(),
                onChanged:
                    _isSending
                        ? null
                        : (value) {
                            setState(() {
                              _selectedCategory =
                                  value;
                            });
                          },
              ),

              const SizedBox(height: 14),

              // =================================================
              // SUJET
              // =================================================

              TextField(
                controller:
                    _subjectController,
                enabled: !_isSending,
                maxLength: 150,
                decoration:
                    InputDecoration(
                  labelText: 'Sujet',
                  hintText:
                      'Ex. Ma carte est bloquée',
                  prefixIcon:
                      const Icon(
                    Icons.subject_rounded,
                    color: _blue,
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

              const SizedBox(height: 5),

              // =================================================
              // MESSAGE
              // =================================================

              TextField(
                controller:
                    _messageController,
                enabled: !_isSending,
                maxLength: 2000,
                maxLines: 6,
                decoration:
                    InputDecoration(
                  labelText: 'Message',
                  hintText:
                      'Expliquez votre problème ou votre demande...',
                  alignLabelWithHint: true,
                  prefixIcon:
                      const Padding(
                    padding:
                        EdgeInsets.only(
                      bottom: 92,
                    ),
                    child: Icon(
                      Icons
                          .chat_bubble_outline_rounded,
                      color: _blue,
                    ),
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

              const SizedBox(height: 12),

              // =================================================
              // ENVOYER
              // =================================================

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed:
                      _isSending
                          ? null
                          : _sendRequest,
                  icon: _isSending
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                        ),
                  label: Text(
                    _isSending
                        ? 'Envoi en cours...'
                        : 'Envoyer la demande',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  style:
                      FilledButton.styleFrom(
                    backgroundColor:
                        _blue,
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

              const SizedBox(height: 8),

              Center(
                child: Text(
                  'Vous pourrez suivre votre demande depuis cette page.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withValues(
                          alpha: 0.55,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}