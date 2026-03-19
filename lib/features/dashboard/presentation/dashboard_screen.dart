import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../auth/domain/auth_provider.dart';
import '../../transactions/data/spending_limit_provider.dart';
import '../../transactions/data/transaction_provider.dart';
import '../../transactions/domain/transaction_categories.dart';
import '../../transactions/domain/transaction_entry.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    final provider = context.watch<TransactionProvider>();
    final limitProvider = context.watch<SpendingLimitProvider>();
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

    final balance = user?.currentAssets ?? (income - expense);
    final recent = [...transactions]..sort((a, b) => b.date.compareTo(a.date));
    final currentMonth = DateTime.now();
    final yearMonth = DateFormat('yyyy-MM').format(currentMonth);
    final expenseByCategory = _buildCurrentMonthExpenseByCategory(transactions);
    unawaited(limitProvider.syncSpentFromTransactions(transactions));

    return SafeArea(
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Nhóm 13 - TH5', style: Theme.of(context).textTheme.titleMedium),
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
                    Text(
                      'Hạn mức chi tiêu tháng ${DateFormat('MM/yyyy').format(currentMonth)}',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: expenseCategories.map((category) {
                        final limit = limitProvider.getLimit(
                          category: category,
                          yearMonth: yearMonth,
                        );
                        final spent = expenseByCategory[category] ?? 0;
                        final hasLimit = limit != null && limit.limitAmount > 0;
                        final progress = hasLimit
                            ? (spent / limit.limitAmount).clamp(0.0, 9.99)
                            : 0.0;
                        final isExceeded = progress >= 1;
                        final isWarning = hasLimit && !isExceeded && progress >= (limit.warningPercent / 100);

                        final cardWidth = (MediaQuery.of(context).size.width - 44) / 2;

                        return SizedBox(
                          width: cardWidth,
                          child: Card(
                            margin: EdgeInsets.zero,
                            color: isExceeded
                                ? Colors.red.withValues(alpha: 0.08)
                                : isWarning
                                    ? Colors.orange.withValues(alpha: 0.08)
                                    : null,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          categoryDisplayName(category),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => _showLimitEditor(
                                          context,
                                          category: category,
                                          yearMonth: yearMonth,
                                          currentLimit: limit,
                                        ),
                                        icon: Icon(
                                          hasLimit ? Icons.edit : Icons.add_circle_outline,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Đã chi: ${currencyFormat.format(spent)}',
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 6),
                                  if (hasLimit) ...[
                                    Text(
                                      'Hạn mức: ${currencyFormat.format(limit.limitAmount)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: progress.clamp(0.0, 1.0),
                                      minHeight: 8,
                                      borderRadius: BorderRadius.circular(6),
                                      color: isExceeded
                                          ? Colors.red
                                          : isWarning
                                              ? Colors.orange
                                              : Colors.blue,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${(progress * 100).toStringAsFixed(0)}% / cảnh báo ${limit.warningPercent.toStringAsFixed(0)}%',
                                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Chưa đặt hạn mức',
                                      style: TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text('Giao dịch gần đây', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (recent.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Chưa có giao dịch', style: TextStyle(color: Colors.grey)),
                      ),
                    ...recent.take(5).map((entry) {
                      final isIncome = entry.type == TransactionType.income;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isIncome ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                            child: Icon(
                              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isIncome ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${categoryDisplayName(entry.category)} • ${DateFormat('dd/MM/yyyy HH:mm').format(entry.date)}'),
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

  Map<String, double> _buildCurrentMonthExpenseByCategory(
    List<TransactionEntry> source,
  ) {
    final now = DateTime.now();
    final result = <String, double>{};

    for (final entry in source) {
      final isCurrentMonth =
          entry.date.year == now.year && entry.date.month == now.month;
      if (!isCurrentMonth || entry.type != TransactionType.expense) {
        continue;
      }
      result[entry.category] = (result[entry.category] ?? 0) + entry.amount;
    }

    return result;
  }

  Future<void> _showLimitEditor(
    BuildContext context, {
    required String category,
    required String yearMonth,
    required SpendingLimit? currentLimit,
  }) async {
    final limitProvider = context.read<SpendingLimitProvider>();
    final amountController = TextEditingController(
      text: (currentLimit?.limitAmount ?? 0).toStringAsFixed(0),
    );
    final warningController = TextEditingController(
      text: (currentLimit?.warningPercent ?? 80).toStringAsFixed(0),
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Hạn mức $category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tháng ${yearMonth.substring(5, 7)}/${yearMonth.substring(0, 4)}'),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Hạn mức'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: warningController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '% cảnh báo'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          if (currentLimit != null)
            TextButton(
              onPressed: () async {
                await limitProvider.removeLimit(
                  category: category,
                  yearMonth: yearMonth,
                );
                if (context.mounted) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa hạn mức')),
                  );
                }
              },
              child: const Text('Xóa'),
            ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(
                    amountController.text
                        .replaceAll('.', '')
                        .replaceAll(',', '')
                        .trim(),
                  ) ??
                  0;
              final warningPercent =
                  double.tryParse(warningController.text.trim()) ?? 80;

              await limitProvider.upsertLimit(
                category: category,
                amount: amount,
                warningPercent: warningPercent,
                yearMonth: yearMonth,
              );

              if (context.mounted) {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã lưu hạn mức')),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    amountController.dispose();
    warningController.dispose();
  }
}
