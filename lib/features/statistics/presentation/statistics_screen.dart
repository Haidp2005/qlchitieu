import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../transactions/data/transaction_provider.dart';
import '../../transactions/domain/transaction_entry.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final transactions = provider.transactions;

    // available years from the data
    final years = transactions.map((t) => t.date.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    if (years.isEmpty) years.add(DateTime.now().year);

    final monthNames = List.generate(
      12,
      (i) => DateFormat.MMMM('vi').format(DateTime(2020, i + 1)),
    );

    final filtered = transactions.where((tx) {
      return tx.date.year == _selectedYear && tx.date.month == _selectedMonth;
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    final incomeByDay = <int, double>{};
    final expenseByDay = <int, double>{};

    for (final tx in filtered) {
      final day = tx.date.day;
      if (tx.type == TransactionType.income) {
        incomeByDay[day] = (incomeByDay[day] ?? 0) + tx.amount;
      } else {
        expenseByDay[day] = (expenseByDay[day] ?? 0) + tx.amount;
      }
    }

    final days = {...incomeByDay.keys, ...expenseByDay.keys}.toList()..sort();
    final barGroups = days.map((day) {
      final income = (incomeByDay[day] ?? 0) / 1000000;
      final expense = (expenseByDay[day] ?? 0) / 1000000;
      return BarChartGroupData(
        x: day,
        barsSpace: 4,
        barRods: [
          BarChartRodData(toY: income, color: Colors.green, width: 7),
          BarChartRodData(toY: expense, color: Colors.red, width: 7),
        ],
      );
    }).toList();

    final lineSpots = days
        .map(
          (day) => FlSpot(day.toDouble(), (expenseByDay[day] ?? 0) / 1000000),
        )
        .toList();

    final totalIncome = incomeByDay.values.fold<double>(0, (p, e) => p + e);
    final totalExpense = expenseByDay.values.fold<double>(0, (p, e) => p + e);
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'VND ',
      decimalDigits: 0,
    );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Thống kê', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedMonth,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Thang',
                  ),
                  items: List.generate(12, (i) => i + 1)
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(monthNames[m - 1]),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedMonth = v);
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedYear,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Nam',
                  ),
                  items: years
                      .map(
                        (y) => DropdownMenuItem(
                          value: y,
                          child: Text(y.toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedYear = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tong thu',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currencyFormat.format(totalIncome),
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tong chi',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currencyFormat.format(totalExpense),
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Can doi',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currencyFormat.format(totalIncome - totalExpense),
                        style: TextStyle(
                          color: (totalIncome - totalExpense) >= 0
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            children: const [
              Icon(Icons.stop, size: 14, color: Colors.green),
              SizedBox(width: 6),
              Text('Thu'),
              SizedBox(width: 12),
              Icon(Icons.stop, size: 14, color: Colors.red),
              SizedBox(width: 6),
              Text('Chi'),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 240,
                child: days.isEmpty
                    ? const Center(child: Text('Không có dữ liệu trong tháng này'))
                    : BarChart(
                        BarChartData(
                          gridData: const FlGridData(drawVerticalLine: false),
                          borderData: FlBorderData(show: false),
                          barGroups: barGroups,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                    final value = (rod.toY * 1000000).toInt();
                                    return BarTooltipItem(
                                      currencyFormat.format(value),
                                      TextStyle(
                                        color: rod.color ?? Colors.black,
                                      ),
                                    );
                                  },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 48,
                                interval: 1,
                                getTitlesWidget: (value, meta) =>
                                    Text('${value.toInt()}M'),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) =>
                                    Text(value.toInt().toString()),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 240,
                child: days.isEmpty
                    ? const Center(child: Text('Không có dữ liệu chi tiêu trong tháng này'))
                    : LineChart(
                        LineChartData(
                          gridData: const FlGridData(drawVerticalLine: false),
                          borderData: FlBorderData(show: false),
                          lineTouchData: LineTouchData(
                            enabled: true,
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (spots) => spots
                                  .map(
                                    (s) => LineTooltipItem(
                                      currencyFormat.format(
                                        (s.y * 1000000).toInt(),
                                      ),
                                      const TextStyle(),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: lineSpots,
                              color: const Color(0xFF0D6EFD),
                              barWidth: 3,
                              isCurved: true,
                              dotData: const FlDotData(show: true),
                            ),
                          ],
                          titlesData: FlTitlesData(
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) =>
                                    Text(value.toInt().toString()),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Category breakdown (top categories)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phan tich nguon/chi',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (ctx) {
                      // compute category breakdown
                      final Map<String, double> expenseByCategory = {};
                      final Map<String, double> incomeByCategory = {};
                      for (final tx in filtered) {
                        if (tx.type == TransactionType.expense) {
                          expenseByCategory[tx.category] =
                              (expenseByCategory[tx.category] ?? 0) + tx.amount;
                        } else {
                          incomeByCategory[tx.category] =
                              (incomeByCategory[tx.category] ?? 0) + tx.amount;
                        }
                      }
                      final topExpenseCats = expenseByCategory.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));
                      final topIncomeCats = incomeByCategory.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));

                      if (topExpenseCats.isEmpty && topIncomeCats.isEmpty) {
                        return const Text('Khong co du lieu de phan tich');
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (topExpenseCats.isNotEmpty) ...[
                            Text(
                              'Top chi tieu',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 6),
                            ...topExpenseCats.take(3).map((e) {
                              final pct = totalExpense == 0
                                  ? 0
                                  : (e.value / totalExpense * 100).round();
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(e.key),
                                  Text(
                                    '${currencyFormat.format(e.value)} • $pct%',
                                  ),
                                ],
                              );
                            }),
                            const SizedBox(height: 8),
                          ],
                          if (topIncomeCats.isNotEmpty) ...[
                            Text(
                              'Top thu',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 6),
                            ...topIncomeCats.take(3).map((e) {
                              final pct = totalIncome == 0
                                  ? 0
                                  : (e.value / totalIncome * 100).round();
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(e.key),
                                  Text(
                                    '${currencyFormat.format(e.value)} • $pct%',
                                  ),
                                ],
                              );
                            }),
                          ],
                        ],
                      );
                    },
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
