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
      child: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            title: const Text('Giao dich'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _TotalsCard(
                    income: currencyFormat.format(income),
                    expense: currencyFormat.format(expense),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<TransactionFilter>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: TransactionFilter.all,
                        label: Text('Tat ca'),
                        icon: Icon(Icons.layers_outlined),
                      ),
                      ButtonSegment(
                        value: TransactionFilter.income,
                        label: Text('Tien vao'),
                        icon: Icon(Icons.south_west),
                      ),
                      ButtonSegment(
                        value: TransactionFilter.expense,
                        label: Text('Tien ra'),
                        icon: Icon(Icons.north_east),
                      ),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _filter = selection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Text('Chua co giao dich trong bo loc nay.'),
                    )
                  else
                    ...filtered.map(
                      (entry) => _TransactionCard(
                        entry: entry,
                        currencyFormat: currencyFormat,
                      ),
                    ),
                ],
              ),
            ),
          ),
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
        return source
            .where((entry) => entry.type == TransactionType.income)
            .toList();
      case TransactionFilter.expense:
        return source
            .where((entry) => entry.type == TransactionType.expense)
            .toList();
    }
  }
}

enum TransactionFilter {
  all,
  income,
  expense,
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.income,
    required this.expense,
  });

  final String income;
  final String expense;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _Value(label: 'Tong thu', value: income, color: Colors.green),
            ),
            Container(
              width: 1,
              height: 50,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            Expanded(
              child: _Value(label: 'Tong chi', value: expense, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.entry,
    required this.currencyFormat,
  });

  final TransactionEntry entry;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final isIncome = entry.type == TransactionType.income;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
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
  }
}
