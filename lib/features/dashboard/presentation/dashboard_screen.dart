import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../transactions/data/transaction_provider.dart';
import '../../transactions/domain/transaction_entry.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final transactions = provider.transactions;
    final isLoading = provider.isLoading;

    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'VND ',
      decimalDigits: 0,
    );

    final income = transactions
        .where((tx) => tx.type == TransactionType.income)
        .fold<double>(0, (sum, tx) => sum + tx.amount);

    final expense = transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    
    final balance = income - expense;

    return SafeArea(
      child: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : transactions.isEmpty 
              ? const Center(child: Text("Empty Wallet", style: TextStyle(fontSize: 18, color: Colors.grey)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('My Wallet - Thân Đức Minh - 2351060467', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tổng số dư', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(currencyFormat.format(balance),
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Tổng thu', style: TextStyle(color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text(currencyFormat.format(income),
                                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Tổng chi', style: TextStyle(color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text(currencyFormat.format(expense),
                                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Giao dịch gần đây', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...transactions.take(5).map((entry) {
                      final isIncome = entry.type == TransactionType.income;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isIncome ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            child: Icon(
                              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isIncome ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${entry.category} • ${DateFormat('dd/MM/yyyy HH:mm').format(entry.date)}'),
                          trailing: Text(
                            '${isIncome ? '+' : '-'}${currencyFormat.format(entry.amount)}',
                            style: TextStyle(
                              color: isIncome ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
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
