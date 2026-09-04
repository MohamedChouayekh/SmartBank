import 'package:flutter/material.dart';

import '../models/transaction.dart';

class TransactionItem extends StatelessWidget {
  final BankTransaction transaction;

  const TransactionItem({
    super.key,
    required this.transaction,
  });

  IconData _getCategoryIcon() {
    switch (transaction.category) {
      case 'Alimentation':
        return Icons.restaurant;
      case 'Électricité':
        return Icons.bolt;
      case 'Eau':
        return Icons.water_drop;
      case 'Salaire':
        return Icons.account_balance_wallet;
      case 'Virement':
        return Icons.swap_horiz;
      default:
        return transaction.type == TransactionType.income
            ? Icons.arrow_downward
            : Icons.arrow_upward;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isIncome =
        transaction.type == TransactionType.income;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          child: Icon(
            _getCategoryIcon(),
          ),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(
              transaction.description,
            ),
            const SizedBox(height: 3),
            Text(
              transaction.category,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall,
            ),
          ],
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'} '
          '${transaction.amount.toStringAsFixed(2)} '
          '${transaction.currency}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isIncome
                ? Colors.green
                : Colors.red,
          ),
        ),
      ),
    );
  }
}