import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/transaction_provider.dart';
import '../domain/transaction_entry.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionFilter _filter = TransactionFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

    final filtered = _applyFilter(transactions, _filter, _searchQuery);

    return SafeArea(
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Giao dịch', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      
                      // Thẻ Tổng Quan Thu/Chi
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text('Tổng thu', style: TextStyle(color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text(currencyFormat.format(income),
                                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                              ),
                              Container(height: 40, width: 1, color: Colors.grey.withOpacity(0.3)),
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text('Tổng chi', style: TextStyle(color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text(currencyFormat.format(expense),
                                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Ô Tìm Kiếm (Search Bar) bo tròn
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm giao dịch...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Bộ Lọc (Segmented Button)
                      SegmentedButton<TransactionFilter>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: TransactionFilter.all, label: Text('Tất cả')),
                          ButtonSegment(value: TransactionFilter.income, label: Text('Thu')),
                          ButtonSegment(value: TransactionFilter.expense, label: Text('Chi')),
                        ],
                        selected: {_filter},
                        onSelectionChanged: (selection) {
                          setState(() => _filter = selection.first);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('Chưa có giao dịch trong bộ lọc này.', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final entry = filtered[index];
                            return _TransactionCard(
                              entry: entry,
                              currencyFormat: currencyFormat,
                              onDelete: () => provider.deleteTransaction(entry.id),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  List<TransactionEntry> _applyFilter(
    List<TransactionEntry> source,
    TransactionFilter filter,
    String query,
  ) {
    Iterable<TransactionEntry> result = source;

    if (filter == TransactionFilter.income) {
      result = result.where((entry) => entry.type == TransactionType.income);
    } else if (filter == TransactionFilter.expense) {
      result = result.where((entry) => entry.type == TransactionType.expense);
    }

    if (query.isNotEmpty) {
      result = result.where((entry) =>
          entry.title.toLowerCase().contains(query.toLowerCase()) ||
          entry.category.toLowerCase().contains(query.toLowerCase()));
    }

    return result.toList();
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionEntry entry;
  final NumberFormat currencyFormat;
  final VoidCallback onDelete;

  const _TransactionCard({
    required this.entry,
    required this.currencyFormat,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = entry.type == TransactionType.income;
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Xác nhận xóa"),
              content: const Text("Bạn có chắc muốn xóa giao dịch này? Hành động này sẽ cập nhật lại số dư của bạn."),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Xóa", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        onDelete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa giao dịch')),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
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
            '${entry.category} • ${DateFormat('dd/MM/yyyy').format(entry.date)}',
          ),
          trailing: Text(
            '${isIncome ? '+' : '-'}${currencyFormat.format(entry.amount)}',
            style: TextStyle(
              color: isIncome ? Colors.green : Colors.red,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

enum TransactionFilter {
  all,
  income,
  expense,
}
