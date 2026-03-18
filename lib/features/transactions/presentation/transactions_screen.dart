import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/mock_transactions.dart';
import '../domain/transaction_entry.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionFilter _filter = TransactionFilter.all;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'VND ',
      decimalDigits: 0,
    );

    final income = mockTransactions
        .where((tx) => tx.type == TransactionType.income)
        .fold<double>(0, (sum, tx) => sum + tx.amount);

    final expense = mockTransactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold<double>(0, (sum, tx) => sum + tx.amount);

    final filtered = _applyFilter(mockTransactions, _filter)
      ..sort((a, b) => b.date.compareTo(a.date));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Giao dich', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tong thu\n${currencyFormat.format(income)}',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Tong chi\n${currencyFormat.format(expense)}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<TransactionFilter>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: TransactionFilter.all, label: Text('Tat ca')),
              ButtonSegment(value: TransactionFilter.income, label: Text('Tien vao')),
              ButtonSegment(value: TransactionFilter.expense, label: Text('Tien ra')),
            ],
            selected: {_filter},
            onSelectionChanged: (selection) {
              setState(() => _filter = selection.first);
            },
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(child: Text('Chua co giao dich trong bo loc nay.')),
            )
          else
            ...filtered.map((entry) {
              final isIncome = entry.type == TransactionType.income;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(entry.title),
                  subtitle: Text(
                    '${entry.category} • ${DateFormat('dd/MM/yyyy').format(entry.date)}',
                  ),
                  trailing: Text(
                    '${isIncome ? '+' : '-'}${currencyFormat.format(entry.amount)}',
                    style: TextStyle(
                      color: isIncome ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  List<TransactionEntry> _applyFilter(
    List<TransactionEntry> source,
    TransactionFilter filter,
  ) {
    switch (filter) {
      case TransactionFilter.all:
        return [...source];
      case TransactionFilter.income:
        return source.where((entry) => entry.type == TransactionType.income).toList();
      case TransactionFilter.expense:
        return source.where((entry) => entry.type == TransactionType.expense).toList();
    }
  }
}

enum TransactionFilter {
  all,
  income,
  expense,
}
