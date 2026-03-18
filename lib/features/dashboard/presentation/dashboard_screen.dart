import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../statistics/presentation/statistics_screen.dart';

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
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: Text('Phan tich')),
                        body: StatisticsScreen(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.bar_chart),
                label: const Text('Phan tich'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tong quan tai chinh',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tong thu: ${currencyFormat.format(income)}',
                    style: const TextStyle(color: Colors.green),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tong chi: ${currencyFormat.format(expense)}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Giao dich gan day',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...recent.take(6).map((entry) {
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
}
