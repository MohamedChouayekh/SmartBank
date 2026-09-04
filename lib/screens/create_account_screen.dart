import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/user.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({
    super.key,
  });

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController =
      TextEditingController();
  final TextEditingController lastNameController =
      TextEditingController();
  final TextEditingController emailController =
      TextEditingController();
  final TextEditingController phoneController =
      TextEditingController();
  final TextEditingController usernameController =
      TextEditingController();
  final TextEditingController addressController =
      TextEditingController();
  final TextEditingController passwordController =
      TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  static const String baseUrl = 'http://192.168.1.155:8080';

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    usernameController.dispose();
    addressController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateFirstName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Veuillez entrer votre prénom.';
    }

    if (text.length < 2) {
      return 'Le prénom doit contenir au moins 2 caractères.';
    }

    if (!RegExp(r"^[a-zA-ZÀ-ÿ\s'-]+$").hasMatch(text)) {
      return 'Le prénom contient des caractères invalides.';
    }

    return null;
  }

  String? _validateLastName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Veuillez entrer votre nom.';
    }

    if (text.length < 2) {
      return 'Le nom doit contenir au moins 2 caractères.';
    }

    if (!RegExp(r"^[a-zA-ZÀ-ÿ\s'-]+$").hasMatch(text)) {
      return 'Le nom contient des caractères invalides.';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Veuillez entrer votre adresse email.';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailRegex.hasMatch(text)) {
      return 'Veuillez entrer une adresse email valide.';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Veuillez entrer votre numéro de téléphone.';
    }

    if (!RegExp(r'^\d{8}$').hasMatch(text)) {
      return 'Le numéro doit contenir exactement 8 chiffres.';
    }

    return null;
  }

  String? _validateUsername(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Veuillez choisir un identifiant.';
    }

    if (text.length < 6) {
      return 'L’identifiant doit contenir au moins 6 caractères.';
    }

    if (text.length > 20) {
      return 'L’identifiant ne doit pas dépasser 20 caractères.';
    }

    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9]*$').hasMatch(text)) {
      return 'Commencez par une lettre et utilisez uniquement des lettres et chiffres.';
    }

    return null;
  }

  String? _validateAddress(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Veuillez entrer votre adresse.';
    }

    if (text.length < 3) {
      return 'Veuillez entrer une adresse valide.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
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

    if (!RegExp(r'[A-Z]').hasMatch(text)) {
      return 'Le mot de passe doit contenir une majuscule.';
    }

    if (!RegExp(r'[a-z]').hasMatch(text)) {
      return 'Le mot de passe doit contenir une minuscule.';
    }

    if (!RegExp(r'\d').hasMatch(text)) {
      return 'Le mot de passe doit contenir un chiffre.';
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+\[\]\\\/]').hasMatch(text)) {
      return 'Le mot de passe doit contenir un caractère spécial.';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final text = value ?? '';

    if (text.isEmpty) {
      return 'Veuillez confirmer votre mot de passe.';
    }

    if (text != passwordController.text) {
      return 'Les mots de passe ne correspondent pas.';
    }

    return null;
  }

  Future<void> _createBankAccounts(int userId) async {
    final types = ['CURRENT', 'SAVINGS'];

    for (final type in types) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/api/accounts'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'userId': userId,
            'type': type,
          }),
        );

        debugPrint(
          'Création compte $type : ${response.statusCode}',
        );

        debugPrint(
          'Réponse compte $type : ${response.body}',
        );
      } catch (e) {
        debugPrint(
          'Erreur création compte $type : $e',
        );
      }
    }
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isLoading) {
      return;
    }

    final password = passwordController.text;

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Le mot de passe ne peut pas être vide.',
          ),
        ),
      );
      return;
    }

    if (password != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Les mots de passe ne correspondent pas.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('$baseUrl/api/users');

      final Map<String, dynamic> requestBody = {
        'username': usernameController.text.trim(),
        'password': password,
        'email': emailController.text.trim(),
        'fullName':
            '${firstNameController.text.trim()} ${lastNameController.text.trim()}',
        'phoneNumber': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'enabled': true,
      };

      debugPrint('==============================');
      debugPrint('CREATE USER REQUEST');
      debugPrint('URL: $url');
      debugPrint('username: ${requestBody['username']}');
      debugPrint('email: ${requestBody['email']}');
      debugPrint('fullName: ${requestBody['fullName']}');
      debugPrint('phoneNumber: ${requestBody['phoneNumber']}');
      debugPrint('address: ${requestBody['address']}');
      debugPrint('password présent: ${password.isNotEmpty}');
      debugPrint('password length: ${password.length}');
      debugPrint('==============================');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (!mounted) {
        return;
      }

      debugPrint(
        'Spring Boot status: ${response.statusCode}',
      );

      debugPrint(
        'Spring Boot response: ${response.body}',
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        final Map<String, dynamic> data =
            jsonDecode(response.body);

        final int newUserId =
            (data['id'] as num).toInt();

        final User user = User(
          id: newUserId,
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          email: (data['email'] ?? '').toString(),
          phone: (data['phoneNumber'] ?? '').toString(),
          username: (data['username'] ?? '').toString(),
          address: (data['address'] ?? '').toString().trim(),
        );

        await _createBankAccounts(newUserId);

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Compte créé avec succès.',
            ),
          ),
        );

        Navigator.pop(
          context,
          {
            'user': user,
            'password': password,
          },
        );

        return;
      }

      if (response.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cet identifiant ou cette adresse email existe déjà.',
            ),
          ),
        );

        return;
      }

      String errorMessage =
          'Erreur lors de la création du compte (${response.statusCode}).';

      if (response.body.isNotEmpty) {
        errorMessage =
            'Erreur ${response.statusCode} : ${response.body}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      debugPrint(
        'Erreur Flutter lors de la création : $e',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de contacter le serveur Spring Boot.',
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
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Créer un compte',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 500,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 75,
                        height: 75,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius:
                              BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: Text(
                        'Bienvenue chez SmartBank',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Center(
                      child: Text(
                        'Créez votre compte pour accéder à vos services bancaires.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),

                    const SizedBox(height: 32),

                    Text(
                      'Informations personnelles',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: firstNameController,
                      textCapitalization:
                          TextCapitalization.words,
                      textInputAction:
                          TextInputAction.next,
                      validator: _validateFirstName,
                      decoration: _inputDecoration(
                        label: 'Prénom',
                        hint: 'Ex. Mohamed',
                        icon: Icons.person_outline,
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: lastNameController,
                      textCapitalization:
                          TextCapitalization.words,
                      textInputAction:
                          TextInputAction.next,
                      validator: _validateLastName,
                      decoration: _inputDecoration(
                        label: 'Nom',
                        hint: 'Ex. Chouayekh',
                        icon: Icons.badge_outlined,
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: emailController,
                      keyboardType:
                          TextInputType.emailAddress,
                      textInputAction:
                          TextInputAction.next,
                      validator: _validateEmail,
                      decoration: _inputDecoration(
                        label: 'Email',
                        hint: 'exemple@email.com',
                        icon: Icons.email_outlined,
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 8,
                      textInputAction:
                          TextInputAction.next,
                      validator: _validatePhone,
                      decoration: _inputDecoration(
                        label: 'Téléphone',
                        hint: 'Ex. 98123456',
                        icon: Icons.phone_outlined,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextFormField(
                      controller: addressController,
                      textCapitalization:
                          TextCapitalization.sentences,
                      textInputAction:
                          TextInputAction.next,
                      validator: _validateAddress,
                      maxLines: 2,
                      decoration: _inputDecoration(
                        label: 'Adresse',
                        hint: 'Ex. Sfax, Tunisie',
                        icon: Icons.location_on_outlined,
                      ),
                    ),

                    const SizedBox(height: 30),

                    Text(
                      'Identifiants de connexion',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Votre identifiant doit commencer par une lettre et contenir uniquement des lettres et chiffres.',
                      style: theme.textTheme.bodySmall,
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: usernameController,
                      textInputAction:
                          TextInputAction.next,
                      validator: _validateUsername,
                      decoration: _inputDecoration(
                        label: 'Identifiant',
                        hint: 'Ex. Mohamed123',
                        icon:
                            Icons.account_circle_outlined,
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      textInputAction:
                          TextInputAction.next,
                      validator: _validatePassword,
                      decoration: _inputDecoration(
                        label: 'Mot de passe',
                        hint:
                            'Entrez un mot de passe sécurisé',
                        icon: Icons.lock_outline,
                      ).copyWith(
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword =
                                  !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller:
                          confirmPasswordController,
                      obscureText:
                          _obscureConfirmPassword,
                      textInputAction:
                          TextInputAction.done,
                      validator:
                          _validateConfirmPassword,
                      onFieldSubmitted:
                          (_) => _createAccount(),
                      decoration: _inputDecoration(
                        label:
                            'Confirmer le mot de passe',
                        hint:
                            'Répétez votre mot de passe',
                        icon: Icons.lock_reset_outlined,
                      ).copyWith(
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme
                            .surfaceContainerHighest,
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Le mot de passe doit contenir :',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                              '• Au moins 8 caractères'),
                          const Text(
                              '• Une lettre majuscule'),
                          const Text(
                              '• Une lettre minuscule'),
                          const Text('• Un chiffre'),
                          const Text(
                              '• Un caractère spécial'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : _createAccount,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.person_add,
                              ),
                        label: Text(
                          _isLoading
                              ? 'Création en cours...'
                              : 'Créer mon compte',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style:
                            ElevatedButton.styleFrom(
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        child: const Text(
                          'J’ai déjà un compte',
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
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