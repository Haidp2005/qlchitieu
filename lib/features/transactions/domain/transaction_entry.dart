enum TransactionType {
  income,
  expense,
}

class TransactionEntry {
  const TransactionEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
  });

  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final TransactionType type;
}
