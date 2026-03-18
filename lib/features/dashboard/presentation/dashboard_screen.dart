import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../transactions/data/mock_transactions.dart';
import '../../transactions/domain/transaction_entry.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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

    final recent = [...mockTransactions]
      ..sort((a, b) => b.date.compareTo(a.date));

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            title: const Text('Dashboard'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SummaryCard(
                    totalIncome: currencyFormat.format(income),
                    totalExpense: currencyFormat.format(expense),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Giao dich gan day',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...recent.take(6).map(
                    (tx) => _TransactionTile(
                      entry: tx,
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
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalIncome,
    required this.totalExpense,
  });

  final String totalIncome;
  final String totalExpense;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1C7C54), Color(0xFF0D6EFD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tong quan tai chinh',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ValueBlock(
                  label: 'Tong thu',
                  value: totalIncome,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ValueBlock(
                  label: 'Tong chi',
                  value: totalExpense,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValueBlock extends StatelessWidget {
  const _ValueBlock({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color.withValues(alpha: 0.85),
              ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
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
        leading: CircleAvatar(
          backgroundColor: isIncome
              ? Colors.green.withValues(alpha: 0.15)
              : Colors.red.withValues(alpha: 0.15),
          child: Icon(
            isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(entry.title),
        subtitle: Text(
          '${entry.category} • ${DateFormat('dd/MM/yyyy').format(entry.date)}',
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'}${currencyFormat.format(entry.amount)}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isIncome ? Colors.green : Colors.red,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
