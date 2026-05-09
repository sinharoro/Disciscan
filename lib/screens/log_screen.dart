import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../db/models/scan_log.dart';
import '../providers/log_provider.dart';
import '../theme.dart';
import '../widgets/stats_row.dart';

class LogScreen extends ConsumerStatefulWidget {
  const LogScreen({super.key});

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(logProvider.notifier).loadLogs());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _exportCsv() async {
    final logState = ref.read(logProvider);
    final logs = logState.filteredLogs;
    
    final rows = [
      ['ID', 'Name', 'Grade', 'Time', 'Type', 'Uniform', 'ID Visible', 'Status', 'Reason', 'Gate', 'Scanned By'],
      ...logs.map((l) => [
        l.studentId,
        l.studentName ?? '',
        l.grade ?? '',
        l.scanTime,
        l.scanType,
        l.uniformComplete ? 'Yes' : 'No',
        l.idVisible ? 'Yes' : 'No',
        l.status,
        l.deniedReason ?? '',
        l.gate,
        l.scannedBy,
      ]),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/entry_log_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv');
    await file.writeAsString(csv);
    
    await Share.shareXFiles([XFile(file.path)], text: 'Entry Log Export');
  }

  void _exportPdf() async {
    final logState = ref.read(logProvider);
    final logs = logState.filteredLogs;
    
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('DisciScan Entry Log', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Date: ${DateFormat('MMMM d, yyyy').format(DateTime.now())}'),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: ['Time', 'Name', 'Type', 'Status', 'Reason'],
              data: logs.map((l) => [
                l.formattedTime,
                l.studentName ?? l.studentId,
                l.scanType,
                l.status.toUpperCase(),
                l.deniedReason ?? '-',
              ]).toList(),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  void _showExportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Export Logs',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.table_chart, color: AppColors.amber),
                title: const Text('Export CSV', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _exportCsv();
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: AppColors.amber),
                title: const Text('Export PDF', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _exportPdf();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logState = ref.watch(logProvider);
    final today = DateFormat('MMMM d, yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text('Entry Log — $today'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _showExportSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by name or ID',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: logState.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(logProvider.notifier).setSearchQuery('');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(logProvider.notifier).setSearchQuery(value);
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('All', LogFilter.all),
                const SizedBox(width: 8),
                _buildFilterChip('Granted', LogFilter.granted),
                const SizedBox(width: 8),
                _buildFilterChip('Denied', LogFilter.denied),
                const SizedBox(width: 8),
                _buildFilterChip('Entry', LogFilter.entry),
                const SizedBox(width: 8),
                _buildFilterChip('Exit', LogFilter.exit),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StatsRow(stats: logState.stats),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: logState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : logState.filteredLogs.isEmpty
                    ? const Center(
                        child: Text(
                          'No logs found',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: logState.filteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = logState.filteredLogs[index];
                          return _buildLogCard(log);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, LogFilter filter) {
    final logState = ref.watch(logProvider);
    final isSelected = logState.filter == filter;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        ref.read(logProvider.notifier).setFilter(filter);
      },
      selectedColor: AppColors.deepIndigo,
      checkmarkColor: Colors.white,
      backgroundColor: AppColors.darkCard,
    );
  }

  Widget _buildLogCard(ScanLog log) {
    final isGranted = log.isGranted;
    final color = isGranted ? AppColors.grantedGreen : AppColors.deniedRed;

    return Dismissible(
      key: Key('log_${log.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppColors.deniedRed,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.darkSurface,
            title: const Text('Delete Log', style: TextStyle(color: AppColors.textPrimary)),
            content: const Text('Are you sure you want to delete this log?', style: TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: AppColors.deniedRed)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        if (log.id != null) {
          ref.read(logProvider.notifier).deleteLog(log.id!);
        }
      },
      child: Card(
        color: AppColors.darkCard,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        log.studentName?.isNotEmpty == true
                            ? log.studentName!.split(' ').map((p) => p[0]).take(2).join().toUpperCase()
                            : log.studentId.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.studentName ?? log.studentId,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          log.grade ?? '',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      log.status.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    log.formattedTime,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.door_front_door_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    log.gate,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              if (!isGranted && log.deniedReason != null) ...[
                const SizedBox(height: 8),
                Text(
                  log.deniedReason!,
                  style: const TextStyle(color: AppColors.deniedRed, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}