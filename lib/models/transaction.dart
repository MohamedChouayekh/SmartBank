enum TransactionType {
  income,
  expense,
}

class BankTransaction {
  final int id;
  final String title;
  final String description;
  final double amount;
  final String currency;
  final DateTime date;
  final TransactionType type;
  final String category;

  final String? relatedAccountNumber;

  const BankTransaction({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.currency,
    required this.date,
    required this.type,
    required this.category,
    this.relatedAccountNumber,
  });
}