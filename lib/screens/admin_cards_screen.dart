import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AdminCardsScreen extends StatefulWidget {
  const AdminCardsScreen({super.key});

  @override
  State<AdminCardsScreen> createState() => _AdminCardsScreenState();
}

class _AdminCardsScreenState extends State<AdminCardsScreen> {
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _cards = [];

  bool _isLoading = true;
  bool _isAssigning = false;

  int? _selectedUserId;
  String _selectedCardType = 'VISA';

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  // =========================================================
  // CHARGEMENT DES DONNÉES
  // =========================================================

  Future<void> _loadAdminData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final usersResponse =
          await _apiService.get('/api/admin/cards/users');

      final cardsResponse =
          await _apiService.get('/api/admin/cards');

      if (usersResponse.statusCode < 200 ||
          usersResponse.statusCode >= 300) {
        throw Exception(
          _apiService.getErrorMessage(usersResponse),
        );
      }

      if (cardsResponse.statusCode < 200 ||
          cardsResponse.statusCode >= 300) {
        throw Exception(
          _apiService.getErrorMessage(cardsResponse),
        );
      }

      final usersData = _apiService.decodeResponse(usersResponse);
      final cardsData = _apiService.decodeResponse(cardsResponse);

      if (!mounted) return;

      setState(() {
        _users = usersData is List
            ? usersData
                .map(
                  (user) => Map<String, dynamic>.from(user as Map),
                )
                .toList()
            : [];

        _cards = cardsData is List
            ? cardsData
                .map(
                  (card) => Map<String, dynamic>.from(card as Map),
                )
                .toList()
            : [];

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de charger les données : $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // ATTRIBUTION D'UNE CARTE
  // =========================================================

  Future<void> _assignCard() async {
    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez sélectionner un utilisateur.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isAssigning = true;
    });

    try {
      final response = await _apiService.post(
        '/api/admin/cards/assign',
        body: {
          'userId': _selectedUserId,
          'cardType': _selectedCardType,
        },
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          _apiService.getErrorMessage(response),
        );
      }

      final data = _apiService.decodeResponse(response);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data is Map && data['message'] != null
                ? data['message'].toString()
                : 'Carte attribuée avec succès.',
          ),
        ),
      );

      await _loadAdminData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de l’attribution : $e',
          ),
        ),
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
  // AFFICHAGE
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Banque / Administration',
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadAdminData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildTitle(
                    'Attribution d’une carte',
                  ),

                  const SizedBox(height: 12),

                  _buildAssignmentCard(),

                  const SizedBox(height: 28),

                  _buildTitle(
                    'Utilisateurs',
                  ),

                  const SizedBox(height: 12),

                  _buildUsersSection(),

                  const SizedBox(height: 28),

                  _buildTitle(
                    'Cartes attribuées',
                  ),

                  const SizedBox(height: 12),

                  _buildCardsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // =========================================================
  // FORMULAIRE D'ATTRIBUTION
  // =========================================================

  Widget _buildAssignmentCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attribuer une nouvelle carte',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<int>(
              value: _selectedUserId,
              decoration: const InputDecoration(
                labelText: 'Utilisateur',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: _users
                  .map(
                    (user) => DropdownMenuItem<int>(
                      value: user['id'] as int,
                      child: Text(
                        '${user['username']} — ${user['fullName'] ?? ''}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedUserId = value;
                });
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedCardType,
              decoration: const InputDecoration(
                labelText: 'Type de carte',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'VISA',
                  child: Text('VISA'),
                ),
                DropdownMenuItem(
                  value: 'MASTERCARD',
                  child: Text('MASTERCARD'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedCardType = value;
                });
              },
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAssigning
                    ? null
                    : _assignCard,
                icon: _isAssigning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.add_card,
                      ),
                label: Text(
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
  // UTILISATEURS
  // =========================================================

  Widget _buildUsersSection() {
    if (_users.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Aucun utilisateur trouvé.',
          ),
        ),
      );
    }

    return Column(
      children: _users.map((user) {
        final bool enabled = user['enabled'] == true;

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(
                enabled
                    ? Icons.person
                    : Icons.person_off,
              ),
            ),
            title: Text(
              user['username']?.toString() ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${user['fullName'] ?? ''}\n'
              '${user['email'] ?? ''}',
            ),
            isThreeLine: true,
            trailing: Text(
              enabled
                  ? 'Actif'
                  : 'Désactivé',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: enabled
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // =========================================================
  // CARTES
  // =========================================================

  Widget _buildCardsSection() {
    if (_cards.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Aucune carte attribuée.',
          ),
        ),
      );
    }

    return Column(
      children: _cards.map((card) {
        final status =
            card['status']?.toString() ?? '';

        return Card(
          child: ListTile(
            leading: const Icon(
              Icons.credit_card,
              size: 32,
            ),
            title: Text(
              '${card['cardType']} •••• ${card['lastFourDigits']}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${card['username'] ?? ''}\n'
              'Expiration : ${card['expiryDate'] ?? ''}\n'
              'Compte : ${card['accountNumber'] ?? ''}',
            ),
            isThreeLine: true,
            trailing: _buildStatusChip(status),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusChip(String status) {
    Color textColor;

    switch (status.toUpperCase()) {
      case 'ACTIVE':
        textColor = Colors.green;
        break;

      case 'BLOCKED':
        textColor = Colors.orange;
        break;

      case 'EXPIRED':
        textColor = Colors.red;
        break;

      default:
        textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: textColor.withValues(
          alpha: 0.12,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}