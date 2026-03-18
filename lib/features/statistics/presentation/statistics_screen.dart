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
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  @override
  Widget build(BuildContext context) {
    final monthOptions = List.generate(12, (index) {
      final now = DateTime.now();
      return DateTime(now.year, now.month - index);
    });

    final provider = context.watch<TransactionProvider>();
    final transactions = provider.transactions;

    final filtered = transactions.where((tx) {
      return tx.date.year == _selectedMonth.year &&
          tx.date.month == _selectedMonth.month;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

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
        .map((day) => FlSpot(day.toDouble(), (expenseByDay[day] ?? 0) / 1000000))
        .toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Thống kê', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          DropdownButtonFormField<DateTime>(
            initialValue: _selectedMonth,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: monthOptions
                .map(
                  (month) => DropdownMenuItem(
                    value: month,
                    child: Text(DateFormat('MM/yyyy').format(month)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedMonth = value);
            },
          ),
          const SizedBox(height: 16),
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
                          titlesData: const FlTitlesData(
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                          lineBarsData: [
                            LineChartBarData(
                              spots: lineSpots,
                              color: const Color(0xFF0D6EFD),
                              barWidth: 3,
                              isCurved: true,
                              dotData: const FlDotData(show: true),
                            ),
                          ],
                          titlesData: const FlTitlesData(
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
