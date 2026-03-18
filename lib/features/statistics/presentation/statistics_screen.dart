import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../transactions/data/mock_transactions.dart';
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

    final filtered = mockTransactions.where((tx) {
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

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            title: const Text('Thong ke'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chon thang/nam',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<DateTime>(
                    initialValue: _selectedMonth,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: monthOptions
                        .map(
                          (month) => DropdownMenuItem(
                            value: month,
                            child: Text(DateFormat('MM/yyyy').format(month)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedMonth = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _ChartCard(
                    title: 'Bieu do cot thu chi theo ngay',
                    child: _BarChartSection(
                      incomeByDay: incomeByDay,
                      expenseByDay: expenseByDay,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ChartCard(
                    title: 'Bieu do duong xu huong chi tieu',
                    child: _LineChartSection(expenseByDay: expenseByDay),
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

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(height: 240, child: child),
          ],
        ),
      ),
    );
  }
}

class _BarChartSection extends StatelessWidget {
  const _BarChartSection({
    required this.incomeByDay,
    required this.expenseByDay,
  });

  final Map<int, double> incomeByDay;
  final Map<int, double> expenseByDay;

  @override
  Widget build(BuildContext context) {
    final days = {...incomeByDay.keys, ...expenseByDay.keys}.toList()..sort();

    if (days.isEmpty) {
      return const Center(child: Text('Khong co du lieu trong thang nay'));
    }

    final groups = days.map((day) {
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

    return BarChart(
      BarChartData(
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: groups,
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) => Text(
                '${value.toStringAsFixed(0)}M',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(value.toInt().toString()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LineChartSection extends StatelessWidget {
  const _LineChartSection({required this.expenseByDay});

  final Map<int, double> expenseByDay;

  @override
  Widget build(BuildContext context) {
    final days = expenseByDay.keys.toList()..sort();

    if (days.isEmpty) {
      return const Center(child: Text('Khong co du lieu chi tieu trong thang nay'));
    }

    final spots = days
        .map(
          (day) => FlSpot(day.toDouble(), (expenseByDay[day] ?? 0) / 1000000),
        )
        .toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: const Color(0xFF0D6EFD),
            barWidth: 3,
            isCurved: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF0D6EFD).withValues(alpha: 0.15),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) => Text(
                '${value.toStringAsFixed(0)}M',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(value.toInt().toString()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
