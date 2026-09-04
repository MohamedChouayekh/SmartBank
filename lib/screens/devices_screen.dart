import 'dart:async';
import 'package:flutter/material.dart';
import '../services/device_session_service.dart';

class DevicesScreen extends StatefulWidget {
  final int userId;

  const DevicesScreen({
    super.key,
    required this.userId,
  });

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final DeviceSessionService _deviceSessionService = DeviceSessionService();

  List<DeviceSession> _sessions = [];
  Timer? _refreshTimer;
  bool _isLoading = false;
  bool _isDisconnecting = false;

  @override
  void initState() {
    super.initState();

    _loadSessions();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (!_isLoading && !_isDisconnecting) {
          _loadSessions();
        }
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final sessions = await _deviceSessionService.getUserSessions(
        widget.userId,
      );

      if (!mounted) {
        return;
      }

      final activeSessions = sessions
          .where((session) => session.active)
          .toList();

      setState(() {
        _sessions = activeSessions;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de récupérer les appareils : $e',
          ),
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

  Future<void> _refreshSessions() async {
    await _loadSessions();
  }

  Future<void> _disconnectSession(
    DeviceSession session,
  ) async {
    if (session.current) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Déconnecter cet appareil ?',
          ),
          content: Text(
            'Voulez-vous déconnecter ${session.deviceName} ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Déconnecter'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isDisconnecting = true;
    });

    try {
      await _deviceSessionService.disconnectSession(
        session.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _sessions.removeWhere(
          (item) => item.id == session.id,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Appareil déconnecté.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de la déconnexion : $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDisconnecting = false;
        });
      }
    }
  }

  Future<void> _disconnectOtherSessions() async {
    final currentSession = _sessions
        .where((session) => session.current)
        .firstOrNull;

    if (currentSession == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Session actuelle introuvable.',
          ),
        ),
      );

      return;
    }

    final otherSessions = _sessions
        .where((session) => !session.current)
        .toList();

    if (otherSessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aucun autre appareil connecté.',
          ),
        ),
      );

      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Déconnecter les autres appareils ?',
          ),
          content: const Text(
            'Tous les autres appareils seront déconnectés de votre compte.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Déconnecter'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isDisconnecting = true;
    });

    try {
      await _deviceSessionService.disconnectOtherSessions(
  widget.userId,
  currentSession.id,
);

      if (!mounted) {
        return;
      }

      setState(() {
        _sessions = _sessions
            .where((session) => session.current)
            .toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tous les autres appareils ont été déconnectés.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de la déconnexion : $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDisconnecting = false;
        });
      }
    }
  }

  IconData _getDeviceIcon(DeviceSession session) {
    final type = session.deviceType.toLowerCase();

    if (type.contains('android')) {
      return Icons.phone_android;
    }

    if (type.contains('ios') ||
        type.contains('iphone') ||
        type.contains('ipad')) {
      return Icons.phone_iphone;
    }

    if (type.contains('web') ||
        type.contains('windows') ||
        type.contains('linux') ||
        type.contains('mac')) {
      return Icons.computer;
    }

    if (type.contains('tablet')) {
      return Icons.tablet_android;
    }

    return Icons.devices;
  }

  String _getDeviceType(DeviceSession session) {
    if (session.deviceType.trim().isEmpty) {
      return 'Appareil inconnu';
    }

    return session.deviceType;
  }

  String _getBrowser(DeviceSession session) {
    if (session.browser.trim().isEmpty) {
      return 'Application SmartBank';
    }

    return session.browser;
  }

  Widget _buildDeviceCard(DeviceSession session) {
    final isCurrent = session.current;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _getDeviceIcon(session),
                size: 28,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.deviceName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Cet appareil',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.devices_other,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _getDeviceType(session),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.language,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _getBrowser(session),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Connecté',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isCurrent)
              IconButton(
                tooltip: 'Déconnecter',
                onPressed: _isDisconnecting
                    ? null
                    : () => _disconnectSession(session),
                icon: const Icon(
                  Icons.logout,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices_other,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 18),
            const Text(
              'Aucun appareil connecté',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les appareils connectés à votre compte apparaîtront ici.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final otherDevicesCount =
        _sessions.where((session) => !session.current).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Appareils connectés',
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _isLoading ? null : _refreshSessions,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSessions,
        child: _sessions.isEmpty && !_isLoading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: _buildEmptyState(),
                  ),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(
                      bottom: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.security,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Appareils connectés',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_sessions.length} appareil${_sessions.length > 1 ? 's' : ''} actuellement connecté${_sessions.length > 1 ? 's' : ''}.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (otherDevicesCount > 0)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isDisconnecting
                            ? null
                            : _disconnectOtherSessions,
                        icon: const Icon(
                          Icons.logout,
                        ),
                        label: Text(
                          'Déconnecter les $otherDevicesCount autres appareils',
                        ),
                      ),
                    ),
                  if (otherDevicesCount > 0) const SizedBox(height: 16),
                  if (_isLoading && _sessions.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ..._sessions.map(
                    _buildDeviceCard,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Actualisation automatique toutes les 5 secondes',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}