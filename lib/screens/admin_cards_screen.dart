import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/api_service.dart';
import 'login_screen.dart';

class AdminCardsScreen extends StatefulWidget {
  const AdminCardsScreen({
    super.key,
  });

  @override
  State<AdminCardsScreen> createState() =>
      _AdminCardsScreenState();
}

class _AdminCardsScreenState
    extends State<AdminCardsScreen> {
  final ApiService _apiService =
      ApiService();

  static const FlutterSecureStorage
      _secureStorage =
      FlutterSecureStorage();

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _cards = [];
  List<Map<String, dynamic>> _requests = [];

  // =========================================================
  // DEMANDES AIDE & SUPPORT
  // =========================================================

  List<Map<String, dynamic>>
      _supportRequests = [];

  bool _isLoading = true;
  bool _isAssigning = false;
  bool _isSendingPromotion = false;

  int? _selectedUserId;
  int? _selectedPromotionUserId;

  String _selectedCardType = 'VISA';

  bool _sendPromotionToAll = true;

  String? _adminUsername;
  String? _adminPassword;

  int _selectedSection = 0;

  final TextEditingController
      _promotionTitleController =
      TextEditingController();

  final TextEditingController
      _promotionMessageController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    _loadAdminCredentialsAndData();
  }

  @override
  void dispose() {
    _promotionTitleController.dispose();
    _promotionMessageController.dispose();

    _apiService.dispose();

    super.dispose();
  }

  // =========================================================
  // IDENTIFIANTS ADMIN
  // =========================================================

  Future<void>
      _loadAdminCredentialsAndData() async {
    try {
      final username =
          await _secureStorage.read(
        key:
            'biometric_username_user_10',
      );

      final password =
          await _secureStorage.read(
        key:
            'biometric_password_user_10',
      );

      if (username == null ||
          password == null ||
          username.isEmpty ||
          password.isEmpty) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        _showMessage(
          'Session administrateur introuvable. '
          'Veuillez vous reconnecter.',
          error: true,
        );

        return;
      }

      _adminUsername = username;
      _adminPassword = password;

      await _loadAdminData();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Erreur : $e',
        error: true,
      );
    }
  }

  // =========================================================
  // CHARGEMENT GLOBAL
  // =========================================================

  Future<void> _loadAdminData() async {
    if (_adminUsername == null ||
        _adminPassword == null) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final usersResponse =
          await _apiService.adminGet(
        '/api/admin/cards/users',
        username: _adminUsername!,
        password: _adminPassword!,
      );

      final cardsResponse =
          await _apiService.adminGet(
        '/api/admin/cards',
        username: _adminUsername!,
        password: _adminPassword!,
      );

      final requestsResponse =
          await _apiService.adminGet(
        '/api/admin/card-unblock-requests',
        username: _adminUsername!,
        password: _adminPassword!,
      );

      final supportRequestsResponse =
          await _apiService.adminGet(
        '/api/support/admin',
        username: _adminUsername!,
        password: _adminPassword!,
      );

      if (usersResponse.statusCode < 200 ||
          usersResponse.statusCode >= 300) {
        throw Exception(
          _apiService.getErrorMessage(
            usersResponse,
          ),
        );
      }

      if (cardsResponse.statusCode < 200 ||
          cardsResponse.statusCode >= 300) {
        throw Exception(
          _apiService.getErrorMessage(
            cardsResponse,
          ),
        );
      }

      if (requestsResponse.statusCode < 200 ||
          requestsResponse.statusCode >= 300) {
        throw Exception(
          _apiService.getErrorMessage(
            requestsResponse,
          ),
        );
      }

      if (supportRequestsResponse.statusCode < 200 ||
          supportRequestsResponse.statusCode >= 300) {
        throw Exception(
          _apiService.getErrorMessage(
            supportRequestsResponse,
          ),
        );
      }

      final usersData =
          _apiService.decodeResponse(
        usersResponse,
      );

      final cardsData =
          _apiService.decodeResponse(
        cardsResponse,
      );

      final requestsData =
          _apiService.decodeResponse(
        requestsResponse,
      );

      final supportRequestsData =
          _apiService.decodeResponse(
        supportRequestsResponse,
      );

      if (!mounted) return;

      setState(() {
        _users = _convertList(
          usersData,
        );

        _cards = _convertList(
          cardsData,
        );

        _requests = _convertList(
          requestsData,
        );

        _supportRequests =
            _convertList(
          supportRequestsData,
        );

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Impossible de charger les données : $e',
        error: true,
      );
    }
  }

  List<Map<String, dynamic>> _convertList(
    dynamic data,
  ) {
    if (data is! List) {
      return [];
    }

    return data
        .map(
          (item) =>
              Map<String, dynamic>.from(
            item as Map,
          ),
        )
        .toList();
  }

  // =========================================================
  // ATTRIBUER CARTE
  // =========================================================

  Future<void> _assignCard() async {
    if (_selectedUserId == null) {
      _showMessage(
        'Veuillez sélectionner un utilisateur.',
        error: true,
      );

      return;
    }

    if (_adminUsername == null ||
        _adminPassword == null) {
      _showMessage(
        'Session administrateur introuvable.',
        error: true,
      );

      return;
    }

    setState(() {
      _isAssigning = true;
    });

    try {
      final response =
          await _apiService.adminPost(
        '/api/admin/cards/assign',
        username: _adminUsername!,
        password: _adminPassword!,
        body: {
          'userId': _selectedUserId,
          'cardType':
              _selectedCardType,
        },
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          _apiService.getErrorMessage(
            response,
          ),
        );
      }

      final data =
          _apiService.decodeResponse(
        response,
      );

      if (!mounted) return;

      _showMessage(
        data is Map &&
                data['message'] != null
            ? data['message'].toString()
            : 'Carte attribuée avec succès.',
      );

      await _loadAdminData();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Erreur lors de l’attribution : $e',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAssigning = false;
        });
      }
    }
  }

  // =========================================================
  // BLOQUER
  // =========================================================

  Future<void> _blockCard(
    Map<String, dynamic> card,
  ) async {
    final cardId =
        _parseInt(card['id']);

    if (cardId <= 0) {
      _showMessage(
        'Identifiant de carte invalide.',
        error: true,
      );
      return;
    }

    if (_adminUsername == null ||
        _adminPassword == null) {
      _showMessage(
        'Session administrateur introuvable.',
        error: true,
      );
      return;
    }

    final confirmed =
        await _confirmAction(
      title: 'Bloquer la carte',
      message:
          'Voulez-vous vraiment bloquer '
          'la carte •••• ${card['lastFourDigits']} ?',
      confirmText: 'Bloquer',
    );

    if (!confirmed) return;

    try {
      final response =
          await _apiService.adminPost(
        '/api/admin/cards/$cardId/block',
        username: _adminUsername!,
        password: _adminPassword!,
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          _apiService.getErrorMessage(
            response,
          ),
        );
      }

      _showMessage(
        'Carte bloquée avec succès.',
      );

      await _loadAdminData();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Erreur : $e',
        error: true,
      );
    }
  }

  // =========================================================
  // DÉBLOQUER
  // =========================================================

  Future<void> _unblockCard(
    Map<String, dynamic> card,
  ) async {
    final cardId =
        _parseInt(card['id']);

    if (cardId <= 0) {
      _showMessage(
        'Identifiant de carte invalide.',
        error: true,
      );
      return;
    }

    if (_adminUsername == null ||
        _adminPassword == null) {
      _showMessage(
        'Session administrateur introuvable.',
        error: true,
      );
      return;
    }

    final confirmed =
        await _confirmAction(
      title: 'Débloquer la carte',
      message:
          'Après vérification bancaire, '
          'voulez-vous débloquer cette carte ?',
      confirmText: 'Débloquer',
    );

    if (!confirmed) return;

    try {
      final response =
          await _apiService.adminPost(
        '/api/admin/cards/$cardId/unblock',
        username: _adminUsername!,
        password: _adminPassword!,
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          _apiService.getErrorMessage(
            response,
          ),
        );
      }

      _showMessage(
        'Carte débloquée avec succès.',
      );

      await _loadAdminData();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Erreur : $e',
        error: true,
      );
    }
  }

  // =========================================================
  // APPROUVER DEMANDE CARTE
  // =========================================================

  Future<void> _approveRequest(
    Map<String, dynamic> request,
  ) async {
    final requestId =
        _parseInt(
      request['requestId'],
    );

    if (requestId <= 0) {
      _showMessage(
        'Identifiant de demande invalide.',
        error: true,
      );
      return;
    }

    if (_adminUsername == null ||
        _adminPassword == null) {
      _showMessage(
        'Session administrateur introuvable.',
        error: true,
      );
      return;
    }

    final responseText =
        await _responseDialog(
      title: 'Approuver la demande',
      hint:
          'Réponse envoyée au client',
    );

    if (responseText == null) {
      return;
    }

    try {
      final response =
          await _apiService.adminPost(
        '/api/admin/card-unblock-requests/'
        '$requestId/approve',
        username: _adminUsername!,
        password: _adminPassword!,
        body: {
          'adminId': 10,
          'adminResponse':
              responseText,
        },
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          _apiService.getErrorMessage(
            response,
          ),
        );
      }

      _showMessage(
        'Demande approuvée. La carte est active.',
      );

      await _loadAdminData();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Erreur : $e',
        error: true,
      );
    }
  }

  // =========================================================
  // REJETER DEMANDE CARTE
  // =========================================================

  Future<void> _rejectRequest(
    Map<String, dynamic> request,
  ) async {
    final requestId =
        _parseInt(
      request['requestId'],
    );

    if (requestId <= 0) {
      _showMessage(
        'Identifiant de demande invalide.',
        error: true,
      );
      return;
    }

    if (_adminUsername == null ||
        _adminPassword == null) {
      _showMessage(
        'Session administrateur introuvable.',
        error: true,
      );
      return;
    }

    final responseText =
        await _responseDialog(
      title: 'Rejeter la demande',
      hint:
          'Motif du rejet',
    );

    if (responseText == null) {
      return;
    }

    try {
      final response =
          await _apiService.adminPost(
        '/api/admin/card-unblock-requests/'
        '$requestId/reject',
        username: _adminUsername!,
        password: _adminPassword!,
        body: {
          'adminId': 10,
          'adminResponse':
              responseText,
        },
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          _apiService.getErrorMessage(
            response,
          ),
        );
      }

      _showMessage(
        'Demande rejetée. La carte reste bloquée.',
      );

      await _loadAdminData();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Erreur : $e',
        error: true,
      );
    }
  }

  // =========================================================
  // SUPPORT - RÉPONDRE
  // =========================================================

  Future<void> _replyToSupportRequest(
    Map<String, dynamic> request,
  ) async {
    final requestId =
        _parseInt(request['id']);

    if (requestId <= 0) {
      _showMessage(
        'Identifiant de demande invalide.',
        error: true,
      );
      return;
    }

    if (_adminUsername == null ||
        _adminPassword == null) {
      _showMessage(
        'Session administrateur introuvable.',
        error: true,
      );
      return;
    }

    final responseText =
        await _responseDialog(
      title: 'Répondre au client',
      hint:
          'Écrivez votre réponse...',
    );

    if (responseText == null ||
        responseText.trim().isEmpty) {
      return;
    }

    try {
      final response =
          await _apiService.adminPut(
        '/api/support/admin/$requestId/reply',
        username: _adminUsername!,
        password: _adminPassword!,
        body: {
          'response':
              responseText.trim(),
        },
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          _apiService.getErrorMessage(
            response,
          ),
        );
      }

      _showMessage(
        'Réponse envoyée au client.',
      );

      await _loadAdminData();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Erreur lors de la réponse : $e',
        error: true,
      );
    }
  }

  // =========================================================
  // SUPPORT - RÉSOUDRE
  // =========================================================

  Future<void> _resolveSupportRequest(
    Map<String, dynamic> request,
  ) async {
    final requestId =
        _parseInt(request['id']);

    if (requestId <= 0) {
      _showMessage(
        'Identifiant de demande invalide.',
        error: true,
      );
      return;
    }

    if (_adminUsername == null ||
        _adminPassword == null) {
      _showMessage(
        'Session administrateur introuvable.',
        error: true,
      );
      return;
    }

    final confirmed =
        await _confirmAction(
      title: 'Résoudre la demande',
      message:
          'Voulez-vous marquer cette demande '
          'comme résolue ?',
      confirmText: 'Résoudre',
    );

    if (!confirmed) return;

    try {
      final response =
          await _apiService.adminPut(
        '/api/support/admin/$requestId/status',
        username: _adminUsername!,
        password: _adminPassword!,
        body: {
          'status': 'RESOLVED',
        },
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          _apiService.getErrorMessage(
            response,
          ),
        );
      }

      _showMessage(
        'Demande marquée comme résolue.',
      );

      await _loadAdminData();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Erreur lors de la résolution : $e',
        error: true,
      );
    }
  }

  // =========================================================
  // SUPPORT - LIBELLÉ CATÉGORIE
  // =========================================================

  String _supportCategoryLabel(
    String category,
  ) {
    switch (category.toUpperCase()) {
      case 'CARTE':
        return 'Cartes';

      case 'VIREMENT':
        return 'Virements';

      case 'PAIEMENT':
        return 'Paiements & factures';

      case 'SECURITE':
        return 'Sécurité';

      case 'COMPTE':
        return 'Compte';

      case 'APPLICATION':
        return 'Application';

      case 'AUTRE':
        return 'Autre';

      default:
        return category;
    }
  }

  // =========================================================
  // SUPPORT - ICÔNE CATÉGORIE
  // =========================================================

  IconData _supportCategoryIcon(
    String category,
  ) {
    switch (category.toUpperCase()) {
      case 'CARTE':
        return Icons.credit_card_rounded;

      case 'VIREMENT':
        return Icons.swap_horiz_rounded;

      case 'PAIEMENT':
        return Icons.receipt_long_rounded;

      case 'SECURITE':
        return Icons.security_rounded;

      case 'COMPTE':
        return Icons.account_balance_rounded;

      case 'APPLICATION':
        return Icons.phone_android_rounded;

      default:
        return Icons.help_outline_rounded;
    }
  }

  // =========================================================
  // SUPPORT - STATUT
  // =========================================================

  Widget _buildSupportStatusChip(
    String status,
  ) {
    Color color;
    String label;

    switch (status) {
      case 'OPEN':
        color = Colors.orange;
        label = 'En attente';
        break;

      case 'IN_PROGRESS':
        color = Colors.blue;
        label = 'En cours';
        break;

      case 'RESOLVED':
        color = Colors.green;
        label = 'Résolue';
        break;

      case 'CLOSED':
        color = Colors.grey;
        label = 'Fermée';
        break;

      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.12,
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight:
              FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  // =========================================================
  // SUPPORT - CARTE
  // =========================================================

  Widget _buildSupportRequestCard(
    Map<String, dynamic> request,
  ) {
    final status =
        request['status']
                ?.toString()
                .toUpperCase() ??
            'OPEN';

    final userName =
        request['fullName']
                    ?.toString()
                    .trim()
                    .isNotEmpty ==
                true
            ? request['fullName']
                .toString()
            : request['username']
                    ?.toString() ??
                'Client';

    final username =
        request['username']
                ?.toString() ??
            '';

    final email =
        request['email']
                ?.toString() ??
            '';

    final category =
        request['category']
                ?.toString() ??
            'AUTRE';

    final subject =
        request['subject']
                ?.toString() ??
            '';

    final message =
        request['message']
                ?.toString() ??
            '';

    final adminResponse =
        request['adminResponse']
                ?.toString()
                .trim() ??
            '';

    final isOpen =
        status == 'OPEN';

    final isInProgress =
        status == 'IN_PROGRESS';

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Icon(
                    _supportCategoryIcon(
                      category,
                    ),
                  ),
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
                        userName,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      if (username.isNotEmpty)
                        Text(
                          username,
                          style:
                              const TextStyle(
                            color:
                                Colors.grey,
                            fontSize: 12,
                          ),
                        ),

                      if (email.isNotEmpty)
                        Text(
                          email,
                          style:
                              const TextStyle(
                            color:
                                Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),

                _buildSupportStatusChip(
                  status,
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(10),
              decoration:
                  BoxDecoration(
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
                color:
                    Colors.blue.withValues(
                  alpha: 0.08,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.category_outlined,
                    size: 20,
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Expanded(
                    child: Text(
                      _supportCategoryLabel(
                        category,
                      ),
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              subject,
              style:
                  const TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(12),
              decoration:
                  BoxDecoration(
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
                color:
                    Colors.grey.withValues(
                  alpha: 0.08,
                ),
              ),
              child: Text(
                message,
              ),
            ),

            if (adminResponse
                .isNotEmpty) ...[
              const SizedBox(
                height: 10,
              ),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(12),
                decoration:
                    BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                  color:
                      Colors.green.withValues(
                    alpha: 0.08,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Réponse de la banque',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      adminResponse,
                    ),
                  ],
                ),
              ),
            ],

            if (isOpen ||
                isInProgress) ...[
              const SizedBox(
                height: 12,
              ),

              Row(
                children: [
                  Expanded(
                    child:
                        OutlinedButton.icon(
                      onPressed: () =>
                          _replyToSupportRequest(
                        request,
                      ),
                      icon:
                          const Icon(
                        Icons.reply,
                      ),
                      label:
                          const Text(
                        'Répondre',
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child:
                        ElevatedButton.icon(
                      onPressed: () =>
                          _resolveSupportRequest(
                        request,
                      ),
                      icon:
                          const Icon(
                        Icons
                            .check_circle_outline,
                      ),
                      label:
                          const Text(
                        'Résoudre',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================
  // PROMOTION
  // =========================================================

  Future<void> _sendPromotion() async {
    final title =
        _promotionTitleController.text.trim();

    final message =
        _promotionMessageController.text.trim();

    if (title.isEmpty) {
      _showMessage(
        'Veuillez saisir le titre de la promotion.',
        error: true,
      );

      return;
    }

    if (message.isEmpty) {
      _showMessage(
        'Veuillez saisir le message de la promotion.',
        error: true,
      );

      return;
    }

    if (!_sendPromotionToAll &&
        _selectedPromotionUserId == null) {
      _showMessage(
        'Veuillez sélectionner un client.',
        error: true,
      );

      return;
    }

    if (_adminUsername == null ||
        _adminPassword == null) {
      _showMessage(
        'Session administrateur introuvable.',
        error: true,
      );

      return;
    }

    if (_sendPromotionToAll) {
      final confirmed =
          await _confirmAction(
        title:
            'Envoyer à tous les clients',
        message:
            'Cette promotion sera envoyée '
            'à tous les clients actifs de SmartBank.\n\n'
            'Voulez-vous continuer ?',
        confirmText:
            'Envoyer à tous',
      );

      if (!confirmed) {
        return;
      }
    }

    setState(() {
      _isSendingPromotion = true;
    });

    try {
      late final dynamic response;

      if (_sendPromotionToAll) {
        response =
            await _apiService.adminPost(
          '/api/admin/promotions/all',
          username: _adminUsername!,
          password: _adminPassword!,
          body: {
            'title': title,
            'message': message,
          },
        );
      } else {
        response =
            await _apiService.adminPost(
          '/api/admin/promotions/user',
          username: _adminUsername!,
          password: _adminPassword!,
          body: {
            'userId':
                _selectedPromotionUserId,
            'title': title,
            'message': message,
          },
        );
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          _apiService.getErrorMessage(
            response,
          ),
        );
      }

      final data =
          _apiService.decodeResponse(
        response,
      );

      if (!mounted) return;

      String successMessage =
          'Promotion envoyée avec succès.';

      if (data is Map &&
          data['message'] != null) {
        successMessage =
            data['message'].toString();

        if (_sendPromotionToAll &&
            data['sentCount'] != null) {
          successMessage +=
              ' (${data['sentCount']} clients)';
        }
      }

      _showMessage(
        successMessage,
      );

      _promotionTitleController.clear();
      _promotionMessageController.clear();

      setState(() {
        _selectedPromotionUserId = null;
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Erreur lors de l’envoi de la promotion : $e',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingPromotion = false;
        });
      }
    }
  }

  // =========================================================
  // DÉCONNEXION
  // =========================================================

  Future<void> _logout() async {
    final confirmed =
        await _confirmAction(
      title: 'Déconnexion',
      message:
          'Voulez-vous vous déconnecter '
          'de l’espace bancaire ?',
      confirmText: 'Se déconnecter',
    );

    if (!confirmed) return;

    await _secureStorage.delete(
      key:
          'biometric_username_user_10',
    );

    await _secureStorage.delete(
      key:
          'biometric_password_user_10',
    );

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          onThemeChanged: () {
            // Le thème sera géré par l'écran principal.
          },
        ),
      ),
      (route) => false,
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Banque / Administration',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed:
                _loadAdminData,
            icon: const Icon(
              Icons.refresh,
            ),
          ),

          IconButton(
            tooltip: 'Se déconnecter',
            onPressed: _logout,
            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),

      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : _buildBody(),

      bottomNavigationBar:
          NavigationBar(
        selectedIndex:
            _selectedSection,
        onDestinationSelected:
            (index) {
          setState(() {
            _selectedSection =
                index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon:
                Icon(Icons.dashboard_outlined),
            selectedIcon:
                Icon(Icons.dashboard),
            label:
                'Accueil',
          ),
          NavigationDestination(
            icon:
                Icon(Icons.people_outline),
            selectedIcon:
                Icon(Icons.people),
            label:
                'Utilisateurs',
          ),
          NavigationDestination(
            icon:
                Icon(Icons.credit_card_outlined),
            selectedIcon:
                Icon(Icons.credit_card),
            label:
                'Cartes',
          ),
          NavigationDestination(
            icon:
                Icon(Icons.mark_email_unread_outlined),
            selectedIcon:
                Icon(Icons.mark_email_unread),
            label:
                'Demandes',
          ),
          NavigationDestination(
            icon:
                Icon(Icons.campaign_outlined),
            selectedIcon:
                Icon(Icons.campaign),
            label:
                'Promotions',
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BODY
  // =========================================================

  Widget _buildBody() {
    switch (_selectedSection) {
      case 1:
        return _buildUsersPage();

      case 2:
        return _buildCardsPage();

      case 3:
        return _buildRequestsPage();

      case 4:
        return _buildPromotionsPage();

      default:
        return _buildDashboardPage();
    }
  }

  // =========================================================
  // DASHBOARD
  // =========================================================

  Widget _buildDashboardPage() {
    final activeCards =
        _cards.where(
      (card) =>
          card['status']
              ?.toString()
              .toUpperCase() ==
          'ACTIVE',
    ).length;

    final blockedCards =
        _cards.where(
      (card) =>
          card['status']
              ?.toString()
              .toUpperCase() ==
          'BLOCKED',
    ).length;

    final pendingCardRequests =
        _requests.where(
      (request) =>
          request['status']
              ?.toString()
              .toUpperCase() ==
          'PENDING',
    ).length;

    final pendingSupportRequests =
        _supportRequests.where(
      (request) {
        final status =
            request['status']
                    ?.toString()
                    .toUpperCase() ??
                '';

        return status == 'OPEN' ||
            status == 'IN_PROGRESS';
      },
    ).length;

    final pendingRequests =
        pendingCardRequests +
            pendingSupportRequests;

    return RefreshIndicator(
      onRefresh:
          _loadAdminData,
      child: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          const Text(
            'Tableau de bord',
            style: TextStyle(
              fontSize: 25,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          const Text(
            'Gestion de SmartBank',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          _buildStatCard(
            'Utilisateurs',
            _users.length,
            Icons.people,
          ),

          _buildStatCard(
            'Cartes',
            _cards.length,
            Icons.credit_card,
          ),

          _buildStatCard(
            'Cartes actives',
            activeCards,
            Icons.check_circle,
          ),

          _buildStatCard(
            'Cartes bloquées',
            blockedCards,
            Icons.lock,
          ),

          _buildStatCard(
            'Demandes en attente',
            pendingRequests,
            Icons.pending_actions,
          ),

          const SizedBox(
            height: 20,
          ),

          _buildTitle(
            'Attribution d’une carte',
          ),

          const SizedBox(
            height: 12,
          ),

          _buildAssignmentCard(),
        ],
      ),
    );
  }

  // =========================================================
  // UTILISATEURS
  // =========================================================

  Widget _buildUsersPage() {
    if (_users.isEmpty) {
      return const Center(
        child: Text(
          'Aucun utilisateur trouvé.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh:
          _loadAdminData,
      child: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          _buildTitle(
            'Utilisateurs',
          ),

          const SizedBox(
            height: 12,
          ),

          ..._users.map(
            (user) {
              final enabled =
                  user['enabled'] == true;

              return Card(
                child: ListTile(
                  leading:
                      CircleAvatar(
                    child: Icon(
                      enabled
                          ? Icons.person
                          : Icons.person_off,
                    ),
                  ),
                  title: Text(
                    user['username']
                            ?.toString() ??
                        '',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${user['fullName'] ?? ''}\n'
                    '${user['email'] ?? ''}\n'
                    '${user['phoneNumber'] ?? ''}',
                  ),
                  isThreeLine:
                      true,
                  trailing:
                      Text(
                    enabled
                        ? 'Actif'
                        : 'Désactivé',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      color:
                          enabled
                              ? Colors.green
                              : Colors.red,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CARTES
  // =========================================================

  Widget _buildCardsPage() {
    return RefreshIndicator(
      onRefresh:
          _loadAdminData,
      child: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          _buildTitle(
            'Gestion des cartes',
          ),

          const SizedBox(
            height: 12,
          ),

          if (_cards.isEmpty)
            const Card(
              child: Padding(
                padding:
                    EdgeInsets.all(16),
                child: Text(
                  'Aucune carte attribuée.',
                ),
              ),
            ),

          ..._cards.map(
            _buildAdminCard,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(
    Map<String, dynamic> card,
  ) {
    final status =
        card['status']
                ?.toString()
                .toUpperCase() ??
            '';

    final blocked =
        status == 'BLOCKED';

    final expired =
        status == 'EXPIRED';

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.credit_card,
                  size: 34,
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${card['cardType'] ?? ''} '
                        '•••• '
                        '${card['lastFourDigits'] ?? ''}',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      Text(
                        '${card['fullName'] ?? ''} '
                        '(${card['username'] ?? ''})',
                      ),
                    ],
                  ),
                ),

                _buildStatusChip(
                  status,
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              'Expiration : '
              '${card['expiryDate'] ?? ''}',
            ),

            Text(
              'Compte : '
              '${card['accountNumber'] ?? ''}',
            ),

            const SizedBox(
              height: 12,
            ),

            Row(
              children: [
                if (!blocked &&
                    !expired)
                  Expanded(
                    child:
                        OutlinedButton.icon(
                      onPressed:
                          () => _blockCard(
                        card,
                      ),
                      icon:
                          const Icon(
                        Icons.lock,
                      ),
                      label:
                          const Text(
                        'Bloquer',
                      ),
                    ),
                  ),

                if (blocked)
                  Expanded(
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          () => _unblockCard(
                        card,
                      ),
                      icon:
                          const Icon(
                        Icons.lock_open,
                      ),
                      label:
                          const Text(
                        'Débloquer',
                      ),
                    ),
                  ),

                if (expired)
                  const Expanded(
                    child: Text(
                      'Carte expirée',
                      textAlign:
                          TextAlign.center,
                      style:
                          TextStyle(
                        color: Colors.red,
                        fontWeight:
                            FontWeight.bold,
                      ),
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
  // DEMANDES
  // =========================================================

  Widget _buildRequestsPage() {
    final pendingCardRequests =
        _requests.where(
      (request) =>
          request['status']
              ?.toString()
              .toUpperCase() ==
          'PENDING',
    ).length;

    final pendingSupportRequests =
        _supportRequests.where(
      (request) {
        final status =
            request['status']
                    ?.toString()
                    .toUpperCase() ??
                '';

        return status == 'OPEN' ||
            status == 'IN_PROGRESS';
      },
    ).length;

    final totalPending =
        pendingCardRequests +
            pendingSupportRequests;

    return RefreshIndicator(
      onRefresh:
          _loadAdminData,
      child: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTitle(
                  'Demandes',
                ),
              ),

              if (totalPending > 0)
                CircleAvatar(
                  radius: 15,
                  child: Text(
                    '$totalPending',
                    style:
                        const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          // ===================================================
          // SUPPORT
          // ===================================================

          Row(
            children: [
              Expanded(
                child: _buildTitle(
                  'Demandes de support',
                ),
              ),

              if (pendingSupportRequests >
                  0)
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.orange
                            .withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    '$pendingSupportRequests',
                    style:
                        const TextStyle(
                      color:
                          Colors.orange,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          if (_supportRequests.isEmpty)
            const Card(
              child: Padding(
                padding:
                    EdgeInsets.all(16),
                child: Text(
                  'Aucune demande de support.',
                ),
              ),
            ),

          ..._supportRequests.map(
            _buildSupportRequestCard,
          ),

          const SizedBox(
            height: 28,
          ),

          // ===================================================
          // DÉBLOCAGE CARTES
          // ===================================================

          Row(
            children: [
              Expanded(
                child: _buildTitle(
                  'Demandes de déblocage de carte',
                ),
              ),

              if (pendingCardRequests >
                  0)
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.orange
                            .withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    '$pendingCardRequests',
                    style:
                        const TextStyle(
                      color:
                          Colors.orange,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          if (_requests.isEmpty)
            const Card(
              child: Padding(
                padding:
                    EdgeInsets.all(16),
                child: Text(
                  'Aucune demande de déblocage.',
                ),
              ),
            ),

          ..._requests.map(
            _buildRequestCard,
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DEMANDE DÉBLOCAGE CARTE
  // =========================================================

  Widget _buildRequestCard(
    Map<String, dynamic> request,
  ) {
    final status =
        request['status']
                ?.toString()
                .toUpperCase() ??
            '';

    final pending =
        status == 'PENDING';

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.person,
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: Text(
                    '${request['fullName'] ?? ''} '
                    '(${request['username'] ?? ''})',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                _buildStatusChip(
                  status,
                ),
              ],
            ),

            const Divider(),

            Text(
              'Carte : '
              '${request['cardType'] ?? ''} '
              '•••• '
              '${request['lastFourDigits'] ?? ''}',
            ),

            Text(
              'Expiration : '
              '${request['expiryDate'] ?? ''}',
            ),

            const SizedBox(
              height: 8,
            ),

            if (request['message'] != null &&
                request['message']
                    .toString()
                    .trim()
                    .isNotEmpty)
              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(10),
                decoration:
                    BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                  color:
                      Colors.grey.withValues(
                    alpha: 0.08,
                  ),
                ),
                child: Text(
                  request['message']
                      .toString(),
                ),
              ),

            if (request['adminResponse'] !=
                    null &&
                request['adminResponse']
                    .toString()
                    .trim()
                    .isNotEmpty) ...[
              const SizedBox(
                height: 8,
              ),

              Text(
                'Réponse banque : '
                '${request['adminResponse']}',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ],

            if (pending) ...[
              const SizedBox(
                height: 12,
              ),

              Row(
                children: [
                  Expanded(
                    child:
                        OutlinedButton.icon(
                      onPressed:
                          () =>
                              _rejectRequest(
                        request,
                      ),
                      icon:
                          const Icon(
                        Icons.close,
                      ),
                      label:
                          const Text(
                        'Rejeter',
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          () =>
                              _approveRequest(
                        request,
                      ),
                      icon:
                          const Icon(
                        Icons.check,
                      ),
                      label:
                          const Text(
                        'Approuver',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================
  // PROMOTIONS
  // =========================================================

  Widget _buildPromotionsPage() {
    final activeClients =
        _users.where(
      (user) =>
          user['enabled'] == true &&
          user['role']
                  ?.toString()
                  .toUpperCase() ==
              'CLIENT',
    ).toList();

    return RefreshIndicator(
      onRefresh:
          _loadAdminData,
      child: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          _buildTitle(
            'Promotions',
          ),

          const SizedBox(
            height: 6,
          ),

          const Text(
            'Envoyer une notification promotionnelle '
            'aux clients SmartBank.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Destinataires',
                    style:
                        TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: true,
                        icon:
                            Icon(
                          Icons.groups,
                        ),
                        label:
                            Text(
                          'Tous les clients',
                        ),
                      ),
                      ButtonSegment<bool>(
                        value: false,
                        icon:
                            Icon(
                          Icons.person,
                        ),
                        label:
                            Text(
                          'Un client',
                        ),
                      ),
                    ],
                    selected: {
                      _sendPromotionToAll,
                    },
                    onSelectionChanged:
                        (selection) {
                      if (selection.isEmpty) {
                        return;
                      }

                      setState(() {
                        _sendPromotionToAll =
                            selection.first;

                        if (_sendPromotionToAll) {
                          _selectedPromotionUserId =
                              null;
                        }
                      });
                    },
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  if (!_sendPromotionToAll)
                    DropdownButtonFormField<int>(
                      value:
                          _selectedPromotionUserId,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Client',
                        border:
                            OutlineInputBorder(),
                        prefixIcon:
                            Icon(
                          Icons.person_outline,
                        ),
                      ),
                      items:
                          activeClients.map(
                        (user) {
                          final id =
                              _parseInt(
                            user['id'],
                          );

                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(
                              '${user['username'] ?? ''}'
                              ' — '
                              '${user['fullName'] ?? ''}',
                            ),
                          );
                        },
                      ).toList(),
                      onChanged:
                          activeClients.isEmpty
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedPromotionUserId =
                                        value;
                                  });
                                },
                    ),

                  if (!_sendPromotionToAll &&
                      activeClients.isEmpty)
                    const Padding(
                      padding:
                          EdgeInsets.only(
                        top: 10,
                      ),
                      child: Text(
                        'Aucun client actif disponible.',
                        style:
                            TextStyle(
                          color:
                              Colors.orange,
                        ),
                      ),
                    ),

                  if (!_sendPromotionToAll)
                    const SizedBox(
                      height: 16,
                    ),

                  TextField(
                    controller:
                        _promotionTitleController,
                    maxLength: 150,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Titre de la promotion',
                      hintText:
                          'Ex. Offre spéciale SmartBank',
                      border:
                          OutlineInputBorder(),
                      prefixIcon:
                          Icon(
                        Icons.title,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  TextField(
                    controller:
                        _promotionMessageController,
                    maxLength: 2000,
                    maxLines: 6,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Message',
                      hintText:
                          'Écrivez le contenu de la promotion...',
                      border:
                          OutlineInputBorder(),
                      prefixIcon:
                          Padding(
                        padding:
                            EdgeInsets.only(
                          bottom: 85,
                        ),
                        child:
                            Icon(
                          Icons.message_outlined,
                        ),
                      ),
                      alignLabelWithHint:
                          true,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Container(
                    width:
                        double.infinity,
                    padding:
                        const EdgeInsets.all(12),
                    decoration:
                        BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                      color:
                          Colors.blue.withValues(
                        alpha: 0.08,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Expanded(
                          child: Text(
                            _sendPromotionToAll
                                ? 'La promotion sera envoyée '
                                  'à tous les clients actifs.'
                                : 'La promotion sera envoyée '
                                  'uniquement au client sélectionné.',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  SizedBox(
                    width:
                        double.infinity,
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          _isSendingPromotion
                              ? null
                              : _sendPromotion,
                      icon:
                          _isSendingPromotion
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                  ),
                                )
                              : const Icon(
                                  Icons.campaign,
                                ),
                      label:
                          Text(
                        _isSendingPromotion
                            ? 'Envoi...'
                            : 'Envoyer la promotion',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ATTRIBUTION
  // =========================================================

  Widget _buildAssignmentCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              value:
                  _selectedUserId,
              decoration:
                  const InputDecoration(
                labelText:
                    'Utilisateur',
                border:
                    OutlineInputBorder(),
                prefixIcon:
                    Icon(
                  Icons.person_outline,
                ),
              ),
              items:
                  _users.map(
                (user) {
                  final id =
                      _parseInt(
                    user['id'],
                  );

                  return DropdownMenuItem<
                      int>(
                    value: id,
                    child: Text(
                      '${user['username'] ?? ''} — '
                      '${user['fullName'] ?? ''}',
                    ),
                  );
                },
              ).toList(),
              onChanged:
                  _users.isEmpty
                      ? null
                      : (value) {
                          setState(() {
                            _selectedUserId =
                                value;
                          });
                        },
            ),

            const SizedBox(
              height: 16,
            ),

            DropdownButtonFormField<
                String>(
              value:
                  _selectedCardType,
              decoration:
                  const InputDecoration(
                labelText:
                    'Type de carte',
                border:
                    OutlineInputBorder(),
                prefixIcon:
                    Icon(
                  Icons.credit_card,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'VISA',
                  child:
                      Text('VISA'),
                ),
                DropdownMenuItem(
                  value:
                      'MASTERCARD',
                  child:
                      Text(
                    'MASTERCARD',
                  ),
                ),
              ],
              onChanged:
                  (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedCardType =
                      value;
                });
              },
            ),

            const SizedBox(
              height: 16,
            ),

            SizedBox(
              width:
                  double.infinity,
              child:
                  ElevatedButton.icon(
                onPressed:
                    _isAssigning ||
                            _users.isEmpty
                        ? null
                        : _assignCard,
                icon:
                    _isAssigning
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                            ),
                          )
                        : const Icon(
                            Icons.add_card,
                          ),
                label:
                    Text(
                  _isAssigning
                      ? 'Attribution...'
                      : 'Attribuer la carte',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // STATISTIQUE
  // =========================================================

  Widget _buildStatCard(
    String title,
    int value,
    IconData icon,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        leading:
            CircleAvatar(
          child:
              Icon(icon),
        ),
        title:
            Text(title),
        trailing:
            Text(
          '$value',
          style:
              const TextStyle(
            fontSize: 22,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // TITRE
  // =========================================================

  Widget _buildTitle(
    String title,
  ) {
    return Text(
      title,
      style:
          const TextStyle(
        fontSize: 21,
        fontWeight:
            FontWeight.bold,
      ),
    );
  }

  // =========================================================
  // STATUS
  // =========================================================

  Widget _buildStatusChip(
    String status,
  ) {
    Color color;

    switch (status) {
      case 'ACTIVE':
        color =
            Colors.green;
        break;

      case 'BLOCKED':
        color =
            Colors.orange;
        break;

      case 'EXPIRED':
        color =
            Colors.red;
        break;

      case 'APPROVED':
        color =
            Colors.green;
        break;

      case 'REJECTED':
        color =
            Colors.red;
        break;

      case 'PENDING':
        color =
            Colors.orange;
        break;

      default:
        color =
            Colors.grey;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha: 0.12,
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child:
          Text(
        status,
        style:
            TextStyle(
          color: color,
          fontWeight:
              FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  // =========================================================
  // CONFIRMATION
  // =========================================================

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmText,
  }) async {
    final result =
        await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
        title:
            Text(title),
        content:
            Text(message),
        actions: [
          TextButton(
            onPressed:
                () =>
                    Navigator.pop(
              context,
              false,
            ),
            child:
                const Text(
              'Annuler',
            ),
          ),
          ElevatedButton(
            onPressed:
                () =>
                    Navigator.pop(
              context,
              true,
            ),
            child:
                Text(
              confirmText,
            ),
          ),
        ],
      ),
    );

    return result == true;
  }

  // =========================================================
  // RÉPONSE ADMIN
  // =========================================================

  Future<String?> _responseDialog({
    required String title,
    required String hint,
  }) async {
    final controller =
        TextEditingController();

    final result =
        await showDialog<String>(
      context: context,
      builder: (context) =>
          AlertDialog(
        title:
            Text(title),
        content:
            TextField(
          controller:
              controller,
          maxLines: 4,
          decoration:
              InputDecoration(
            hintText: hint,
            border:
                const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed:
                () =>
                    Navigator.pop(
              context,
            ),
            child:
                const Text(
              'Annuler',
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final text =
                  controller.text
                      .trim();

              if (text.isEmpty) {
                return;
              }

              Navigator.pop(
                context,
                text,
              );
            },
            child:
                const Text(
              'Confirmer',
            ),
          ),
        ],
      ),
    );

    controller.dispose();

    return result;
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(message),
        backgroundColor:
            error
                ? Colors.red
                : null,
      ),
    );
  }

  // =========================================================
  // INT
  // =========================================================

  int _parseInt(
    dynamic value,
  ) {
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
}