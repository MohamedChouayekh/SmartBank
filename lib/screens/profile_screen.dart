import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/device_session_service.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'security_screen.dart';

class ProfileScreen extends StatelessWidget {
  final User user;
  final VoidCallback onThemeChanged;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.onThemeChanged,
  });

  static const Color blue =
      Color(0xFF0B5AA6);

  static const Color darkBlue =
      Color(0xFF06457E);

  static const Color yellow =
      Color(0xFFF4C542);

  Future<void> _logout(
    BuildContext context,
  ) async {
    DeviceSessionService()
        .stopHeartbeat();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LoginScreen(
          onThemeChanged:
              onThemeChanged,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final isDark =
        theme.brightness ==
            Brightness.dark;

    final displayName =
        user.firstName.isNotEmpty
            ? '${user.firstName[0].toUpperCase()}'
                '${user.firstName.substring(1)}'
            : 'Utilisateur';

    final avatarLetter =
        displayName.isNotEmpty
            ? displayName[0].toUpperCase()
            : 'U';

    final idString =
        user.id.toString();

    final clientId =
        idString.length >= 6
            ? idString.substring(
                idString.length - 6,
              )
            : idString.padLeft(
                6,
                '0',
              );

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
          'Mon profil',
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
            children: [
              // =================================================
              // PROFIL
              // =================================================

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  22,
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
                          22,
                      offset:
                          const Offset(
                        0,
                        9,
                      ),
                    ),
                  ],
                ),
                child:
                    Stack(
                  children: [
                    Positioned(
                      right:
                          -40,
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
                                0.06,
                          ),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          width:
                              88,
                          height:
                              88,
                          decoration:
                              BoxDecoration(
                            color:
                                Colors.white.withValues(
                              alpha:
                                  0.16,
                            ),
                            shape:
                                BoxShape.circle,
                            border:
                                Border.all(
                              color:
                                  Colors.white.withValues(
                                alpha:
                                    0.25,
                              ),
                              width:
                                  2,
                            ),
                          ),
                          child:
                              Center(
                            child:
                                Text(
                              avatarLetter,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                                fontSize:
                                    38,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height:
                              13,
                        ),
                        Text(
                          user.fullName,
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize:
                                22,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        const SizedBox(
                          height:
                              4,
                        ),
                        Text(
                          user.email,
                          textAlign:
                              TextAlign.center,
                          style:
                              TextStyle(
                            color:
                                Colors.white.withValues(
                              alpha:
                                  0.75,
                            ),
                            fontSize:
                                13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height:
                    25,
              ),

              _buildSectionTitle(
                context,
                'Mes comptes',
              ),

              const SizedBox(
                height:
                    10,
              ),

              _buildProfileCard(
                context,
                icon:
                    Icons.account_balance_outlined,
                iconColor:
                    blue,
                title:
                    'Compte courant',
                subtitle:
                    user.fullName,
                isDark:
                    isDark,
              ),

              _buildProfileCard(
                context,
                icon:
                    Icons.savings_outlined,
                iconColor:
                    const Color(
                  0xFF087A5B,
                ),
                title:
                    'Compte épargne',
                subtitle:
                    'Épargne de ${user.fullName}',
                isDark:
                    isDark,
              ),

              const SizedBox(
                height:
                    20,
              ),

              _buildSectionTitle(
                context,
                'Informations personnelles',
              ),

              const SizedBox(
                height:
                    10,
              ),

              _buildInfoCard(
                context,
                icon:
                    Icons.phone_outlined,
                title:
                    'Téléphone',
                value:
                    user.phone.isNotEmpty
                        ? '+216 ${user.phone}'
                        : 'Non renseigné',
                isDark:
                    isDark,
              ),

              _buildInfoCard(
                context,
                icon:
                    Icons.account_circle_outlined,
                title:
                    'Identifiant',
                value:
                    user.username,
                isDark:
                    isDark,
              ),

              _buildInfoCard(
                context,
                icon:
                    Icons.badge_outlined,
                title:
                    'Identifiant client',
                value:
                    'CLT-$clientId',
                isDark:
                    isDark,
              ),

              _buildInfoCard(
                context,
                icon:
                    Icons.location_on_outlined,
                title:
                    'Adresse',
                value:
                    user.address.isNotEmpty
                        ? user.address
                        : 'Non renseignée',
                isDark:
                    isDark,
              ),

              const SizedBox(
                height:
                    22,
              ),

              _buildSectionTitle(
                context,
                'Préférences',
              ),

              const SizedBox(
                height:
                    10,
              ),

              _buildActionTile(
                context,
                icon:
                    isDark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                title:
                    'Apparence',
                subtitle:
                    isDark
                        ? 'Mode sombre'
                        : 'Mode clair',
                isDark:
                    isDark,
                trailing:
                    Switch(
                  value:
                      isDark,
                  onChanged:
                      (_) =>
                          onThemeChanged(),
                ),
                onTap:
                    onThemeChanged,
              ),

              _buildActionTile(
                context,
                icon:
                    Icons.notifications_outlined,
                title:
                    'Notifications',
                subtitle:
                    'Gérer vos préférences',
                isDark:
                    isDark,
                trailing:
                    const Icon(
                  Icons.chevron_right_rounded,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              NotificationsScreen(
                        userId:
                            user.id,
                      ),
                    ),
                  );
                },
              ),

              _buildActionTile(
                context,
                icon:
                    Icons.security_outlined,
                title:
                    'Sécurité',
                subtitle:
                    'Biométrie et sécurité du compte',
                isDark:
                    isDark,
                trailing:
                    const Icon(
                  Icons.chevron_right_rounded,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              SecurityScreen(
                        userId:
                            user.id,
                        userEmail:
                            user.email,
                        onThemeChanged:
                            onThemeChanged,
                      ),
                    ),
                  );
                },
              ),

              _buildActionTile(
                context,
                icon:
                    Icons.help_outline_rounded,
                title:
                    'Aide & Support',
                subtitle:
                    'Obtenir de l’aide',
                isDark:
                    isDark,
                trailing:
                    const Icon(
                  Icons.chevron_right_rounded,
                ),
                onTap: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content:
                          Text(
                        'Le service Aide & Support sera disponible prochainement.',
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(
                height:
                    25,
              ),

              SizedBox(
                width:
                    double.infinity,
                height:
                    54,
                child:
                    OutlinedButton.icon(
                  onPressed:
                      () => _logout(
                    context,
                  ),
                  icon:
                      const Icon(
                    Icons.logout_rounded,
                  ),
                  label:
                      const Text(
                    'Se déconnecter',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        Colors.red.shade700,
                    side:
                        BorderSide(
                      color:
                          Colors.red.shade200,
                    ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
  ) {
    return Align(
      alignment:
          Alignment.centerLeft,
      child:
          Text(
        title,
        style:
            Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
              fontWeight:
                  FontWeight.w800,
            ),
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      width:
          double.infinity,
      margin:
          const EdgeInsets.only(
        bottom:
            10,
      ),
      padding:
          const EdgeInsets.all(
        15,
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
          16,
        ),
      ),
      child:
          Row(
        children: [
          Container(
            width:
                44,
            height:
                44,
            decoration:
                BoxDecoration(
              color:
                  iconColor.withValues(
                alpha:
                    0.10,
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
                  iconColor,
            ),
          ),
          const SizedBox(
            width:
                12,
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
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height:
                      3,
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
                        12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Container(
      width:
          double.infinity,
      margin:
          const EdgeInsets.only(
        bottom:
            8,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            14,
        vertical:
            12,
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
          14,
        ),
      ),
      child:
          Row(
        children: [
          Icon(
            icon,
            color:
                blue,
            size:
                21,
          ),
          const SizedBox(
            width:
                12,
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
                      TextStyle(
                    fontSize:
                        11,
                    color:
                        isDark
                            ? Colors.white54
                            : Colors.grey.shade600,
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
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      width:
          double.infinity,
      margin:
          const EdgeInsets.only(
        bottom:
            8,
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
          15,
        ),
      ),
      child:
          ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal:
              14,
          vertical:
              3,
        ),
        leading:
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
              Icon(
            icon,
            color:
                blue,
          ),
        ),
        title:
            Text(
          title,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
        subtitle:
            Text(
          subtitle,
          style:
              const TextStyle(
            fontSize:
                11.5,
          ),
        ),
        trailing:
            trailing,
        onTap:
            onTap,
      ),
    );
  }
}