import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/transaction_provider.dart';
// import '../utils/currency_formatter.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analitik')),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final breakdown = provider.categoryTotalsForMonth();
          final entries = breakdown.entries.toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Perincian Kategori (Bulan ini)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: entries.isEmpty
                    ? const Center(child: Text('Tidak ada data'))
                    : PieChart(
                        PieChartData(
                          sections: entries
                              .map(
                                (e) => PieChartSectionData(
                                  value: e.value.abs(),
                                  title: e.key,
                                  radius: 50,
                                ),
                              )
                              .toList(),
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Tren Bulanan (Total)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(height: 200, child: _buildMonthlyTrend(provider)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthlyTrend(TransactionProvider provider) {
    final now = DateTime.now();
    final months = List.generate(
      6,
      (i) => DateTime(now.year, now.month - (5 - i), 1),
    );
    final spots = <FlSpot>[];
    for (var i = 0; i < months.length; i++) {
      final m = months[i];
      final total =
          provider.monthlyIncome(forMonth: m) -
          provider.monthlyExpense(forMonth: m);
      spots.add(FlSpot(i.toDouble(), total));
    }

    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                final idx = v.toInt();
                if (idx < 0 || idx >= months.length)
                  return const SizedBox.shrink();
                final label = '${months[idx].month}/${months[idx].year % 100}';
                return Text(label, style: const TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(spots: spots, isCurved: true, barWidth: 2),
        ],
      ),
    );
  }
}
