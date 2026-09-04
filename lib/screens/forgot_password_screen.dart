import 'package:flutter/material.dart';

import '../services/otp_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final OtpService otpService;

  // E-mail éventuellement transmis depuis le profil.
  final String? initialEmail;

  // Si true, l'e-mail est affiché mais ne peut pas être modifié.
  final bool hideEmailField;

  const ForgotPasswordScreen({
    super.key,
    required this.otpService,
    this.initialEmail,
    this.hideEmailField = false,
  });

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController otpController =
      TextEditingController();

  final TextEditingController newPasswordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _contactVerified = false;
  bool _otpVerified = false;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Si l'écran est ouvert depuis SecurityScreen,
    // on récupère directement l'e-mail de l'utilisateur connecté.
    if (widget.initialEmail != null &&
        widget.initialEmail!.trim().isNotEmpty) {
      emailController.text =
          widget.initialEmail!.trim();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            error ? Colors.red : null,
        duration:
            const Duration(seconds: 4),
      ),
    );
  }

  // =========================================================
  // ENVOYER OTP
  // =========================================================

  Future<void> _verifyContact() async {
    final email =
        emailController.text.trim();

    if (email.isEmpty) {
      _showMessage(
        'Veuillez entrer votre adresse e-mail.',
        error: true,
      );
      return;
    }

    if (!RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email)) {
      _showMessage(
        'Veuillez entrer une adresse e-mail valide.',
        error: true,
      );
      return;
    }

    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.otpService.sendOtp(
        email: email,
      );

      if (!mounted) return;

      setState(() {
        _contactVerified = true;
        _otpVerified = false;
        otpController.clear();
      });

      _showMessage(
        'Code de vérification envoyé par email.',
      );
    } on OtpException catch (e) {
      if (!mounted) return;

      _showMessage(
        e.message,
        error: true,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Impossible de contacter le serveur. Vérifiez que Spring Boot est démarré.',
        error: true,
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
  // VERIFIER OTP
  // =========================================================

  Future<void> _verifyOtp() async {
    final email =
        emailController.text.trim();

    final otp =
        otpController.text.trim();

    if (otp.isEmpty) {
      _showMessage(
        'Veuillez entrer le code de vérification.',
        error: true,
      );
      return;
    }

    if (!RegExp(
      r'^\d{6}$',
    ).hasMatch(otp)) {
      _showMessage(
        'Le code doit contenir exactement 6 chiffres.',
        error: true,
      );
      return;
    }

    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.otpService.verifyOtp(
        email: email,
        otp: otp,
      );

      if (!mounted) return;

      setState(() {
        _otpVerified = true;
      });

      _showMessage(
        'Code vérifié. Vous pouvez maintenant créer un nouveau mot de passe.',
      );
    } on OtpException catch (e) {
      if (!mounted) return;

      _showMessage(
        e.message,
        error: true,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Impossible de contacter le serveur.',
        error: true,
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
  // VALIDATION MOT DE PASSE
  // =========================================================

  String? _validatePassword(
    String? value,
  ) {
    final text = value ?? '';

    if (text.isEmpty) {
      return 'Veuillez entrer un mot de passe.';
    }

    if (text.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères.';
    }

    if (text.length > 64) {
      return 'Le mot de passe ne doit pas dépasser 64 caractères.';
    }

    if (!RegExp(r'[A-Z]')
        .hasMatch(text)) {
      return 'Le mot de passe doit contenir une majuscule.';
    }

    if (!RegExp(r'[a-z]')
        .hasMatch(text)) {
      return 'Le mot de passe doit contenir une minuscule.';
    }

    if (!RegExp(r'\d')
        .hasMatch(text)) {
      return 'Le mot de passe doit contenir un chiffre.';
    }

    if (!RegExp(
      r'[!@#$%^&*(),.?":{}|<>_\-+\[\]\\\/]',
    ).hasMatch(text)) {
      return 'Le mot de passe doit contenir un caractère spécial.';
    }

    return null;
  }

  String? _validateConfirmPassword(
    String? value,
  ) {
    final text = value ?? '';

    if (text.isEmpty) {
      return 'Veuillez confirmer votre mot de passe.';
    }

    if (text !=
        newPasswordController.text) {
      return 'Les mots de passe ne correspondent pas.';
    }

    return null;
  }

  // =========================================================
  // REINITIALISER MOT DE PASSE
  // =========================================================

  Future<void> _changePassword() async {
    if (!_otpVerified) {
      _showMessage(
        'Veuillez d’abord vérifier le code de vérification.',
        error: true,
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email =
        emailController.text.trim();

    final otp =
        otpController.text.trim();

    final newPassword =
        newPasswordController.text;

    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.otpService.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );

      if (!mounted) return;

      _showMessage(
        'Mot de passe modifié avec succès.',
      );

      await Future.delayed(
        const Duration(
          milliseconds: 800,
        ),
      );

      if (!mounted) return;

      Navigator.pop(context);
    } on OtpException catch (e) {
      if (!mounted) return;

      _showMessage(
        e.message,
        error: true,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Impossible de contacter le serveur.',
        error: true,
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
  // DECORATION
  // =========================================================

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mot de passe oublié',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 500,
                ),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 20,
                    ),

                    // =================================================
                    // LOGO
                    // =================================================

                    Container(
                      width: 80,
                      height: 80,
                      decoration:
                          BoxDecoration(
                        color: theme
                            .colorScheme
                            .primary,
                        borderRadius:
                            BorderRadius
                                .circular(24),
                      ),
                      child:
                          const Icon(
                        Icons.lock_reset,
                        color:
                            Colors.white,
                        size: 42,
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    Text(
                      'Réinitialiser votre mot de passe',
                      textAlign:
                          TextAlign.center,
                      style: theme
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      'Entrez votre adresse e-mail afin de récupérer votre compte.',
                      textAlign:
                          TextAlign.center,
                      style: theme
                          .textTheme
                          .bodyMedium,
                    ),

                    const SizedBox(
                      height: 32,
                    ),

                    // =================================================
                    // EMAIL
                    // =================================================

                    TextFormField(
                      controller:
                          emailController,
                      enabled:
                          !widget.hideEmailField &&
                          !_contactVerified &&
                          !_isLoading,
                      keyboardType:
                          TextInputType
                              .emailAddress,
                      textInputAction:
                          TextInputAction
                              .done,
                      decoration:
                          _inputDecoration(
                        label:
                            'Adresse e-mail',
                        hint:
                            'Ex. exemple@email.com',
                        icon: Icons
                            .email_outlined,
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // =================================================
                    // BOUTON ENVOYER
                    // =================================================

                    if (!_contactVerified)
                      SizedBox(
                        width:
                            double.infinity,
                        height: 52,
                        child:
                            ElevatedButton
                                .icon(
                          onPressed:
                              _isLoading
                                  ? null
                                  : _verifyContact,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
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
                                      .send_outlined,
                                ),
                          label: Text(
                            _isLoading
                                ? 'Envoi en cours...'
                                : 'Envoyer le code',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                          style:
                              ElevatedButton
                                  .styleFrom(
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

                    // =================================================
                    // CONTACT VERIFIE
                    // =================================================

                    if (_contactVerified &&
                        !_otpVerified) ...[
                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets
                                .all(14),
                        decoration:
                            BoxDecoration(
                          color: theme
                              .colorScheme
                              .primaryContainer,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons
                                  .check_circle,
                              color: theme
                                  .colorScheme
                                  .primary,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            const Expanded(
                              child: Text(
                                'Un code de vérification a été envoyé à votre adresse e-mail.',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      // =================================================
                      // OTP
                      // =================================================

                      TextFormField(
                        controller:
                            otpController,
                        enabled:
                            !_isLoading,
                        keyboardType:
                            TextInputType
                                .number,
                        maxLength: 6,
                        textAlign:
                            TextAlign.center,
                        textInputAction:
                            TextInputAction
                                .done,
                        decoration:
                            _inputDecoration(
                          label:
                              'Code de vérification',
                          hint:
                              'Ex. 483721',
                          icon: Icons
                              .verified_outlined,
                        ).copyWith(
                          counterText: '',
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      SizedBox(
                        width:
                            double.infinity,
                        height: 52,
                        child:
                            ElevatedButton
                                .icon(
                          onPressed:
                              _isLoading
                                  ? null
                                  : _verifyOtp,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
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
                                      .verified,
                                ),
                          label: Text(
                            _isLoading
                                ? 'Vérification...'
                                : 'Vérifier le code',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                          style:
                              ElevatedButton
                                  .styleFrom(
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

                      const SizedBox(
                        height: 16,
                      ),

                      // Depuis SecurityScreen,
                      // l'e-mail ne doit pas être modifié.
                      if (!widget.hideEmailField)
                        TextButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () {
                                      setState(
                                        () {
                                          _contactVerified =
                                              false;
                                          otpController
                                              .clear();
                                        },
                                      );
                                    },
                          child:
                              const Text(
                            'Modifier l’e-mail',
                          ),
                        ),
                    ],

                    // =================================================
                    // OTP VERIFIE
                    // =================================================

                    if (_otpVerified) ...[
                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets
                                .all(14),
                        decoration:
                            BoxDecoration(
                          color: theme
                              .colorScheme
                              .primaryContainer,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.verified,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: Text(
                                'Identité vérifiée.',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      // =================================================
                      // NOUVEAU MOT DE PASSE
                      // =================================================

                      TextFormField(
                        controller:
                            newPasswordController,
                        enabled:
                            !_isLoading,
                        obscureText:
                            _obscurePassword,
                        validator:
                            _validatePassword,
                        textInputAction:
                            TextInputAction
                                .next,
                        decoration:
                            _inputDecoration(
                          label:
                              'Nouveau mot de passe',
                          hint:
                              'Entrez votre nouveau mot de passe',
                          icon: Icons
                              .lock_outline,
                        ).copyWith(
                          suffixIcon:
                              IconButton(
                            onPressed: () {
                              setState(
                                () {
                                  _obscurePassword =
                                      !_obscurePassword;
                                },
                              );
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons
                                      .visibility_outlined
                                  : Icons
                                      .visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // =================================================
                      // CONFIRMATION
                      // =================================================

                      TextFormField(
                        controller:
                            confirmPasswordController,
                        enabled:
                            !_isLoading,
                        obscureText:
                            _obscureConfirmPassword,
                        validator:
                            _validateConfirmPassword,
                        textInputAction:
                            TextInputAction
                                .done,
                        onFieldSubmitted:
                            (_) =>
                                _changePassword(),
                        decoration:
                            _inputDecoration(
                          label:
                              'Confirmer le mot de passe',
                          hint:
                              'Répétez votre mot de passe',
                          icon: Icons
                              .lock_reset_outlined,
                        ).copyWith(
                          suffixIcon:
                              IconButton(
                            onPressed: () {
                              setState(
                                () {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                },
                              );
                            },
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons
                                      .visibility_outlined
                                  : Icons
                                      .visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // =================================================
                      // REGLES
                      // =================================================

                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets
                                .all(16),
                        decoration:
                            BoxDecoration(
                          color: theme
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              'Le mot de passe doit contenir :',
                              style: theme
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            const Text(
                              '• Au moins 8 caractères',
                            ),
                            const Text(
                              '• Une lettre majuscule',
                            ),
                            const Text(
                              '• Une lettre minuscule',
                            ),
                            const Text(
                              '• Un chiffre',
                            ),
                            const Text(
                              '• Un caractère spécial',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 28,
                      ),

                      // =================================================
                      // MODIFIER
                      // =================================================

                      SizedBox(
                        width:
                            double.infinity,
                        height: 54,
                        child:
                            ElevatedButton
                                .icon(
                          onPressed:
                              _isLoading
                                  ? null
                                  : _changePassword,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
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
                          label: Text(
                            _isLoading
                                ? 'Modification...'
                                : 'Modifier le mot de passe',
                            style:
                                const TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                          style:
                              ElevatedButton
                                  .styleFrom(
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

                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}