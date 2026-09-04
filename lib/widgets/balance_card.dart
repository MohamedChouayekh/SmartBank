import 'package:flutter/material.dart';
import '../models/account.dart';

class BalanceCard extends StatelessWidget {
  final Account account;

  const BalanceCard({
    super.key,
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.20),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TYPE DU COMPTE
          Text(
            account.accountType,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          // SOLDE
          const Text(
            'Solde disponible',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            account.formattedBalance,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // NUMÉRO DU COMPTE
          Text(
            '•••• ${_lastFourDigits(account.accountNumber)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _lastFourDigits(String accountNumber) {
    if (accountNumber.length <= 4) {
      return accountNumber;
    }

    return accountNumber.substring(accountNumber.length - 4);
  }
}

