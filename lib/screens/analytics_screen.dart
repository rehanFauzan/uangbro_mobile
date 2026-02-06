import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/transaction_provider.dart';
import '../models/transaction_model.dart';
import '../utils/currency_formatter.dart';
import '../utils/design_tokens.dart';

enum PeriodPreset { week, month, threeMonths, sixMonths, year, custom }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  PeriodPreset _selected = PeriodPreset.month;
  DateTimeRange? _customRange;
  int _touchedIndex = -1;

  DateTimeRange _rangeForPreset(PeriodPreset preset) {
    final now = DateTime.now();
    switch (preset) {
      case PeriodPreset.week:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
          start: DateTime(start.year, start.month, start.day),
          end: now,
        );
      case PeriodPreset.month:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
      case PeriodPreset.threeMonths:
        final from = DateTime(now.year, now.month - 2, 1);
        return DateTimeRange(start: from, end: now);
      case PeriodPreset.sixMonths:
        final from = DateTime(now.year, now.month - 5, 1);
        return DateTimeRange(start: from, end: now);
      case PeriodPreset.year:
        final from = DateTime(now.year, 1, 1);
        return DateTimeRange(start: from, end: now);
      case PeriodPreset.custom:
        return _customRange ??
            DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
    }
  }

  final List<Color> _palette = [
    DesignTokens.primary,
    DesignTokens.success,
    DesignTokens.danger,
    DesignTokens.neutralHigh,
    DesignTokens.primaryVariant,
  ];

  Color _colorForIndex(int i) {
    return _palette[i % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analitik')),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final range = _rangeForPreset(_selected);
          final filtered = provider.transactions.where((tx) {
            return !tx.date.isBefore(range.start) &&
                !tx.date.isAfter(range.end);
          }).toList();

          final totalExpense = filtered
              .where((t) => t.type == TransactionType.expense)
              .fold(0.0, (s, t) => s + t.amount);

          // category totals
          final Map<String, double> totals = {};
          for (var tx in filtered) {
            totals[tx.category] = (totals[tx.category] ?? 0) + tx.amount;
          }
          final entries = totals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          // comparison with previous period
          final prevRange = DateTimeRange(
            start: range.start.subtract(
              Duration(days: range.end.difference(range.start).inDays + 1),
            ),
            end: range.start.subtract(const Duration(days: 1)),
          );
          final prev = provider.transactions
              .where(
                (tx) =>
                    !tx.date.isBefore(prevRange.start) &&
                    !tx.date.isAfter(prevRange.end),
              )
              .toList();
          final prevExpense = prev
              .where((t) => t.type == TransactionType.expense)
              .fold(0.0, (s, t) => s + t.amount);

          final avgDailyExpense = range.duration.inDays > 0
              ? totalExpense / max(1, range.duration.inDays)
              : totalExpense;
          final totalTx = filtered.length;
          final frequentCategory = entries.isNotEmpty ? entries.first.key : '-';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Active range label
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_formatDate(range.start)} — ${_formatDate(range.end)}',
                  style: const TextStyle(
                    color: DesignTokens.neutralLow,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Summary cards
              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      'Rata-rata /hari',
                      CurrencyFormatter.format(avgDailyExpense),
                      icon: Icons.calendar_today,
                      color: DesignTokens.primary,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryCard(
                      'Total transaksi',
                      totalTx.toString(),
                      icon: Icons.receipt_long,
                      color: DesignTokens.success,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryCard(
                      'Kategori top',
                      frequentCategory,
                      icon: Icons.label_important,
                      color: DesignTokens.danger,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Period selector
              _buildPeriodSelector(context),
              const SizedBox(height: 12),

              // Pie + legend
              const Text(
                'Pengeluaran per kategori',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DesignTokens.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 220,
                      child: entries.isEmpty
                          ? const Center(child: Text('Tidak ada data'))
                          : PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 28,
                                pieTouchData: PieTouchData(
                                  touchCallback: (event, pieTouchResponse) {
                                    final idx =
                                        pieTouchResponse
                                            ?.touchedSection
                                            ?.touchedSectionIndex ??
                                        -1;
                                    setState(() {
                                      _touchedIndex = idx;
                                    });
                                  },
                                ),
                                sections: List.generate(entries.length, (i) {
                                  final e = entries[i];
                                  final percent = totalExpense > 0
                                      ? (e.value / totalExpense * 100)
                                      : 0.0;
                                  final selected = i == _touchedIndex;
                                  return PieChartSectionData(
                                    value: e.value,
                                    color: _colorForIndex(i),
                                    radius: selected ? 60 : 48,
                                    title: '${percent.toStringAsFixed(0)}%',
                                    titleStyle: const TextStyle(
                                      color: DesignTokens.bg,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }),
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: List.generate(entries.length, (i) {
                        final e = entries[i];
                        final percent = totalExpense > 0
                            ? (e.value / totalExpense * 100)
                            : 0.0;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              color: _colorForIndex(i),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${e.key} • ${percent.toStringAsFixed(0)}% • ${CurrencyFormatter.format(e.value)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 12),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Comparison card
              _comparisonCard(totalExpense, prevExpense),
              const SizedBox(height: 16),

              // Top categories
              const Text(
                'Top kategori',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DesignTokens.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < min(5, entries.length); i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: _categoryBarRow(
                          entries[i].key,
                          entries[i].value,
                          entries.first.value,
                          _colorForIndex(i),
                        ),
                      ),
                    if (entries.isEmpty) const Text('Tidak ada pengeluaran'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Income vs Expense bar chart
              const Text(
                'Pemasukan vs Pengeluaran (6 bulan)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(height: 220, child: _buildIncomeExpenseChart(provider)),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard(
    String title,
    String value, {
    IconData? icon,
    Color? color,
    VoidCallback? onTap,
  }) {
    final content = Row(
      children: [
        if (icon != null)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color ?? DesignTokens.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: DesignTokens.neutralHigh, size: 20),
          ),
        if (icon != null) const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: DesignTokens.neutralLow, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  color: DesignTokens.neutralHigh,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final card = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: content,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }
    return card;
  }

  // helper to format date
  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')} ${_monthShort(d.month)} ${d.year}';
  }

  String _monthShort(int m) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return names[m - 1];
  }

  Widget _buildPeriodSelector(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (var p in PeriodPreset.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selected == p
                          ? DesignTokens.primary
                          : DesignTokens.surface,
                      foregroundColor: _selected == p
                          ? DesignTokens.neutralHigh
                          : DesignTokens.neutralLow,
                    ),
                    onPressed: () async {
                      if (p == PeriodPreset.custom) {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          initialDateRange: _customRange,
                          builder: (ctx, child) => Theme(
                            data: Theme.of(
                              context,
                            ).copyWith(colorScheme: const ColorScheme.dark()),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setState(() {
                            _customRange = picked;
                            _selected = p;
                          });
                        }
                      } else {
                        setState(() {
                          _selected = p;
                        });
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _labelForPreset(p),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _labelForPreset(PeriodPreset p) {
    switch (p) {
      case PeriodPreset.week:
        return 'Minggu';
      case PeriodPreset.month:
        return 'Bulan';
      case PeriodPreset.threeMonths:
        return '3Bln';
      case PeriodPreset.sixMonths:
        return '6Bln';
      case PeriodPreset.year:
        return 'Tahun';
      case PeriodPreset.custom:
        return 'Custom';
    }
  }

  Widget _comparisonCard(double currentExpense, double previousExpense) {
    final diff = currentExpense - previousExpense;
    final pct = previousExpense > 0 ? (diff / previousExpense * 100) : 0.0;
    final up = diff >= 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Perbandingan periode',
                style: TextStyle(color: DesignTokens.neutralLow),
              ),
              const SizedBox(height: 6),
              Text(
                'Pengeluaran: ${CurrencyFormatter.format(currentExpense)}',
                style: const TextStyle(
                  color: DesignTokens.neutralHigh,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sebelumnya: ${CurrencyFormatter.format(previousExpense)}',
                style: const TextStyle(color: DesignTokens.neutralLow, fontSize: 12),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                up ? Icons.trending_up : Icons.trending_down,
                color: up ? DesignTokens.success : DesignTokens.danger,
              ),
              const SizedBox(height: 6),
              Text(
                '${pct.abs().toStringAsFixed(0)}%',
                style: TextStyle(
                  color: up ? DesignTokens.success : DesignTokens.danger,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryBarRow(
    String name,
    double value,
    double maxValue,
    Color color,
  ) {
    final ratio = maxValue > 0 ? (value / maxValue) : 0.0;
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(name, style: const TextStyle(color: DesignTokens.neutralHigh)),
        ),
        const SizedBox(width: 8),
        Expanded(
            flex: 5,
          child: LinearProgressIndicator(
            value: ratio,
            color: color,
            // withOpacity is deprecated; use withAlpha for equivalent opacity
            backgroundColor: DesignTokens.bg.withAlpha((0.12 * 255).round()),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          CurrencyFormatter.format(value),
          style: const TextStyle(color: DesignTokens.neutralLow, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildIncomeExpenseChart(TransactionProvider provider) {
    final now = DateTime.now();
    final months = List.generate(
      6,
      (i) => DateTime(now.year, now.month - (5 - i), 1),
    );
    final List<BarChartGroupData> groups = [];
    for (var i = 0; i < months.length; i++) {
      final m = months[i];
      final inc = provider.monthlyIncome(forMonth: m);
      final exp = provider.monthlyExpense(forMonth: m);
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(toY: inc, color: DesignTokens.success, width: 8),
            BarChartRodData(toY: exp, color: DesignTokens.danger, width: 8),
          ],
          barsSpace: 4,
        ),
      );
    }
    final maxVal =
        groups
            .expand((g) => g.barRods.map((r) => r.toY))
            .fold<double>(0.0, (p, e) => max(p, e)) *
        1.1;

    return Column(
      children: [
        // legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(width: 12, height: 12, color: DesignTokens.success),
                const SizedBox(width: 6),
                const Text('Pemasukan', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(width: 16),
            Row(
              children: [
                Container(width: 12, height: 12, color: DesignTokens.danger),
                const SizedBox(width: 6),
                const Text('Pengeluaran', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              maxY: maxVal < 1 ? 1 : maxVal,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: DesignTokens.surface,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final label = rodIndex == 0 ? 'Pemasukan' : 'Pengeluaran';
                    return BarTooltipItem(
                      '$label\n${CurrencyFormatter.format(rod.toY)}',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
              gridData: FlGridData(show: true, horizontalInterval: maxVal / 4),
              alignment: BarChartAlignment.spaceAround,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (v, meta) {
                      return Text(
                        CurrencyFormatter.format(v),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= months.length) {
                        return const SizedBox.shrink();
                      }
                      final m = months[idx];
                      return Text(
                        '${m.month}/${m.year % 100}',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              barGroups: groups,
            ),
          ),
        ),
      ],
    );
  }
}
