import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:html' as html;
import '../models/transaction_model.dart';
import '../services/transaction_provider.dart';
import '../services/api_service.dart';
import 'transaction_form.dart';
import '../utils/currency_formatter.dart';
import '../utils/design_tokens.dart';

enum PeriodPreset { week, month, threeMonths, sixMonths, year, custom }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _sortOption =
      'date_desc'; // date_desc, date_asc, amount_desc, amount_asc
  PeriodPreset _selectedPreset = PeriodPreset.month;
  DateTimeRange? _customRange;
  final ApiService _api = ApiService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Transaksi"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              setState(() {
                _sortOption = v;
              });
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'date_desc', child: Text('Terbaru')),
              const PopupMenuItem(value: 'date_asc', child: Text('Terlama')),
              const PopupMenuItem(
                value: 'amount_desc',
                child: Text('Jumlah (besar → kecil)'),
              ),
              const PopupMenuItem(
                value: 'amount_asc',
                child: Text('Jumlah (kecil → besar)'),
              ),
            ],
          ),

          // Period selector
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: _buildPeriodSelector(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Cari kategori, deskripsi, atau nominal...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (v) => setState(() {}),
            ),
          ),

          // Comparison card (current period vs previous)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Consumer<TransactionProvider>(
              builder: (ctx, provider, _) {
                final range = _rangeForPreset(_selectedPreset);
                final currentExpense = provider.transactions
                    .where(
                      (tx) =>
                          !tx.date.isBefore(range.start) &&
                          !tx.date.isAfter(range.end),
                    )
                    .where((t) => t.type == TransactionType.expense)
                    .fold(0.0, (s, t) => s + t.amount);

                final prevRange = DateTimeRange(
                  start: range.start.subtract(
                    Duration(
                      days: range.end.difference(range.start).inDays + 1,
                    ),
                  ),
                  end: range.start.subtract(const Duration(days: 1)),
                );

                final previousExpense = provider.transactions
                    .where(
                      (tx) =>
                          !tx.date.isBefore(prevRange.start) &&
                          !tx.date.isAfter(prevRange.end),
                    )
                    .where((t) => t.type == TransactionType.expense)
                    .fold(0.0, (s, t) => s + t.amount);

                final diff = currentExpense - previousExpense;
                final pct = previousExpense > 0
                    ? (diff / previousExpense * 100)
                    : (currentExpense > 0 ? 100.0 : 0.0);
                final up = diff >= 0;

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    // surfaceContainerHighest.withOpacity deprecated; use withAlpha
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withAlpha((0.12 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Perbandingan periode',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface
                                  .withAlpha((0.7 * 255).round()),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Pengeluaran ${_labelForPreset(_selectedPreset)}: ${CurrencyFormatter.format(currentExpense)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dibandingkan ${_previousLabelForPreset(_selectedPreset)}: ${CurrencyFormatter.format(previousExpense)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface
                                  .withAlpha((0.7 * 255).round()),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Icon(
                            up ? Icons.trending_up : Icons.trending_down,
                            color: up ? Colors.green : Colors.red,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${pct.abs().toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: up ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Top categories (under comparison)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Consumer<TransactionProvider>(
              builder: (ctx, provider, _) {
                final range = _rangeForPreset(_selectedPreset);
                final filtered = provider.transactions
                    .where(
                      (tx) =>
                          !tx.date.isBefore(range.start) &&
                          !tx.date.isAfter(range.end),
                    )
                    .where((t) => t.type == TransactionType.expense)
                    .toList();
                final Map<String, double> totals = {};
                for (var tx in filtered) {
                  totals[tx.category] = (totals[tx.category] ?? 0) + tx.amount;
                }
                final entries = totals.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                final maxVal = entries.isNotEmpty ? entries.first.value : 1.0;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    // Slight background tint using alpha instead of withOpacity
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withAlpha((0.06 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Top kategori (pengeluaran)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (entries.isEmpty)
                        const Text('Tidak ada pengeluaran di periode ini'),
                      for (
                        var i = 0;
                        i < (entries.length < 5 ? entries.length : 5);
                        i++
                      )
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  entries[i].key,
                                  style: const TextStyle(
                                    color: DesignTokens.neutralHigh,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 5,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: maxVal > 0
                                        ? entries[i].value / maxVal
                                        : 0,
                                    valueColor: const AlwaysStoppedAnimation(
                                      DesignTokens.primary,
                                    ),
                                    backgroundColor: DesignTokens.bg.withAlpha(
                                      (0.08 * 255).round(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                CurrencyFormatter.format(entries[i].value),
                                style: const TextStyle(
                                  color: DesignTokens.neutralLow,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Consumer<TransactionProvider>(
              builder: (context, provider, _) {
                return Row(
                  children: [
                    _buildFilterChip(
                      context,
                      provider,
                      label: "Semua",
                      type: null,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      context,
                      provider,
                      label: "Pemasukan",
                      type: TransactionType.income,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      context,
                      provider,
                      label: "Pengeluaran",
                      type: TransactionType.expense,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.file_download_outlined),
                      onPressed: () => _showExportImportDialog(context),
                      tooltip: 'Export/Import Data',
                    ),
                  ],
                );
              },
            ),
          ),

          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, provider, child) {
                final transactions = provider.transactions;

                // Apply search filter
                final query = _searchController.text.toLowerCase().trim();
                List<Transaction> displayed = transactions.where((tx) {
                  if (query.isEmpty) return true;
                  final amountStr = tx.amount.toString();
                  final dateStr = DateFormat(
                    'dd MMM yyyy',
                  ).format(tx.date).toLowerCase();
                  return tx.category.toLowerCase().contains(query) ||
                      tx.description.toLowerCase().contains(query) ||
                      amountStr.contains(query) ||
                      dateStr.contains(query);
                }).toList();

                // Apply date range filter
                final range = _rangeForPreset(_selectedPreset);
                displayed = displayed.where((tx) {
                  final d = tx.date;
                  return !d.isBefore(range.start) && !d.isAfter(range.end);
                }).toList();

                // Sort according to option
                switch (_sortOption) {
                  case 'date_asc':
                    displayed.sort((a, b) => a.date.compareTo(b.date));
                    break;
                  case 'amount_desc':
                    displayed.sort((a, b) => b.amount.compareTo(a.amount));
                    break;
                  case 'amount_asc':
                    displayed.sort((a, b) => a.amount.compareTo(b.amount));
                    break;
                  case 'date_desc':
                  default:
                    displayed.sort((a, b) => b.date.compareTo(a.date));
                }

                if (displayed.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          "Tidak ada riwayat transaksi",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayed.length,
                  itemBuilder: (context, index) {
                    final tx = displayed[index];
                    return _buildTransactionItem(context, provider, tx);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    TransactionProvider provider, {
    required String label,
    required TransactionType? type,
  }) {
    final isSelected = provider.typeFilter == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        provider.setTypeFilter(type);
      },
      showCheckmark: false,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

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
        return DateTimeRange(
          start: DateTime(now.year, now.month - 2, 1),
          end: now,
        );
      case PeriodPreset.sixMonths:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 5, 1),
          end: now,
        );
      case PeriodPreset.year:
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
      case PeriodPreset.custom:
        return _customRange ??
            DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
    }
  }

  Widget _buildPeriodSelector(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var p in PeriodPreset.values)
          Flexible(
            fit: FlexFit.loose,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedPreset == p
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface,
                  foregroundColor: _selectedPreset == p
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 8),
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
                        _selectedPreset = p;
                      });
                    }
                  } else {
                    setState(() {
                      _selectedPreset = p;
                    });
                  }
                },
                child: Text(
                  _labelForPreset(p),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _labelForPreset(PeriodPreset p) {
    switch (p) {
      case PeriodPreset.week:
        return 'Minggu Ini';
      case PeriodPreset.month:
        return 'Bulan Ini';
      case PeriodPreset.threeMonths:
        return '3 Bulan';
      case PeriodPreset.sixMonths:
        return '6 Bulan';
      case PeriodPreset.year:
        return 'Tahun Ini';
      case PeriodPreset.custom:
        return 'Custom';
    }
  }

  String _previousLabelForPreset(PeriodPreset p) {
    switch (p) {
      case PeriodPreset.week:
        return 'minggu lalu';
      case PeriodPreset.month:
        return 'bulan lalu';
      case PeriodPreset.threeMonths:
        return '3 bulan sebelumnya';
      case PeriodPreset.sixMonths:
        return '6 bulan sebelumnya';
      case PeriodPreset.year:
        return 'tahun lalu';
      case PeriodPreset.custom:
        return 'periode sebelumnya';
    }
  }

  void _showExportImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.surface,
        title: const Text(
          'Export/Import Data',
          style: TextStyle(color: DesignTokens.neutralHigh),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.file_download,
                color: DesignTokens.primary,
              ),
              title: const Text('Export ke CSV'),
              subtitle: const Text('Unduh transaksi sebagai file CSV'),
              onTap: () {
                Navigator.of(ctx).pop();
                _exportTransactions(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.file_upload,
                color: DesignTokens.primary,
              ),
              title: const Text('Import dari CSV'),
              subtitle: const Text('Pilih file CSV untuk import'),
              onTap: () {
                Navigator.of(ctx).pop();
                _importTransactions(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportTransactions(BuildContext context) async {
    try {
      final userId = await _api.getUserId();
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User ID tidak ditemukan')),
          );
        }
        return;
      }

      final result = await _api.exportTransactionsApi(userId);

      // Check if result is valid
      if (result == null || result['status'] != 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result?['message'] ?? 'Gagal export: Response tidak valid',
              ),
            ),
          );
        }
        return;
      }

      // Get CSV data safely
      final csvBase64 = result['csv'] as String?;
      final fileName = result['filename'] as String?;

      if (csvBase64 == null || csvBase64.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal export: Data CSV kosong')),
          );
        }
        return;
      }

      if (fileName == null || fileName.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal export: Nama file kosong')),
          );
        }
        return;
      }

      // Decode base64 CSV
      try {
        final csvBytes = base64Decode(csvBase64);
        final csvContent = utf8.decode(csvBytes);

        // Create blob and download link for web
        final blob = html.Blob([csvContent], 'text/csv');
        final url = html.Url.createObjectUrl(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export berhasil! ($fileName)')),
          );
        }
      } catch (decodeError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal decode CSV: $decodeError')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal export: $e')));
      }
    }
  }

  Widget _buildTransactionItem(
    BuildContext context,
    TransactionProvider provider,
    Transaction tx,
  ) {
    final isExpense = tx.type == TransactionType.expense;

    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Hapus Transaksi?"),
            content: const Text("Transaksi ini akan dihapus permanen."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text("Batal"),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text("Hapus", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        // Keep a copy to allow undo
        final deletedTx = tx;
        await provider.deleteTransaction(tx);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Transaksi dihapus'),
              action: SnackBarAction(
                label: 'UNDO',
                onPressed: () async {
                  // Recreate the transaction on backend and refresh
                  await provider.addTransaction(deletedTx);
                },
              ),
              duration: const Duration(seconds: 6),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).round()),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isExpense
                ? Colors.red.withAlpha((0.1 * 255).round())
                : Colors.green.withAlpha((0.1 * 255).round()),
            child: Icon(
              isExpense ? Icons.arrow_upward : Icons.arrow_downward,
              color: isExpense ? Colors.red : Colors.green,
              size: 20,
            ),
          ),
          title: Text(tx.category),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tx.description.isNotEmpty) Text(tx.description),
              Text(
                DateFormat('dd MMM yyyy, HH:mm').format(tx.date),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                CurrencyFormatter.format(tx.amount),
                style: TextStyle(
                  color: isExpense ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    // Open the form in a modal bottom sheet for quicker edits
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (ctx) => Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(ctx).viewInsets.bottom,
                        ),
                        child: TransactionForm(
                          existingTransaction: tx,
                          shrinkWrap: true,
                          onSaved: () async {
                            // Parent will refresh after the sheet is closed
                            await provider.fetchTransactions();
                          },
                        ),
                      ),
                    );
                  } else if (value == 'delete') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Hapus Transaksi?"),
                        content: const Text(
                          "Transaksi ini akan dihapus permanen.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text("Batal"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text(
                              "Hapus",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      final deletedTx = tx;
                      await provider.deleteTransaction(tx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Transaksi dihapus'),
                            action: SnackBarAction(
                              label: 'UNDO',
                              onPressed: () async {
                                await provider.addTransaction(deletedTx);
                              },
                            ),
                            duration: const Duration(seconds: 6),
                          ),
                        );
                      }
                    }
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importTransactions(BuildContext context) async {
    // Create file input element
    final input = html.FileUploadInputElement()..accept = '.csv';
    input.click();

    input.onChange.listen((e) {
      final files = input.files;
      if (files == null || files.isEmpty) return;

      final file = files.first;
      final reader = html.FileReader();

      reader.onLoadEnd.listen((loadEnd) async {
        final result = reader.result as String;
        final lines = result.split('\n');

        // Skip header row
        if (lines.isEmpty) return;

        final transactions = <Map<String, dynamic>>[];

        for (int i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;

          // Parse CSV line (simple parsing, doesn't handle quoted fields)
          final parts = line.split(',');
          if (parts.length >= 5) {
            transactions.add({
              'type': parts[1].trim(),
              'amount': double.tryParse(parts[2].trim()) ?? 0,
              'description': parts[3].trim().replaceAll('"', ''),
              'date': parts[4].trim(),
              'category': parts.length > 5
                  ? parts[5].trim().replaceAll('"', '')
                  : 'Lainnya',
            });
          }
        }

        final userId = await _api.getUserId();
        if (userId == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User ID tidak ditemukan')),
            );
          }
          return;
        }

        final importResult = await _api.importTransactions(
          userId,
          transactions,
        );

        if (importResult['status'] == 'success') {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(importResult['message'])));
            // Refresh transactions
            final provider = Provider.of<TransactionProvider>(
              context,
              listen: false,
            );
            await provider.fetchTransactions();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(importResult['message'] ?? 'Gagal import'),
              ),
            );
          }
        }
      });

      reader.readAsText(file);
    });
  }
}
