class Account {
  final int id;
  final String accountNumber;
  final String accountType;
  final double balance;
  final String currency;

  Account({
    required this.id,
    required this.accountNumber,
    required this.accountType,
    required this.balance,
    required this.currency,
  });

  String get formattedBalance {
    return '${balance.toStringAsFixed(2)} $currency';
  }
}