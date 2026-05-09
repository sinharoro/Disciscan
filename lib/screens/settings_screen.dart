import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../providers/settings_provider.dart';
import '../providers/scan_provider.dart';
import '../db/database_helper.dart';
import '../db/models/student.dart';
import '../theme.dart';
import '../widgets/pin_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _gateController = TextEditingController();
  final _guardController = TextEditingController();
  final _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _gateController.text = settings.gateName;
    _guardController.text = settings.guardName;
    _pinController.text = settings.adminPin;
  }

  @override
  void dispose() {
    _gateController.dispose();
    _guardController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _saveGateName() {
    ref.read(settingsProvider.notifier).setGateName(_gateController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gate name saved')),
    );
  }

  void _saveGuardName() {
    ref.read(settingsProvider.notifier).setGuardName(_guardController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Guard name saved')),
    );
  }

  void _changePin() async {
    final verified = await showPinDialog(
      context,
      expectedPin: ref.read(settingsProvider).adminPin,
      onVerify: (_) {},
    );

    if (verified == true && mounted) {
      final newPin = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            backgroundColor: AppColors.darkSurface,
            title: const Text('New PIN', style: TextStyle(color: AppColors.textPrimary)),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              autofocus: true,
              decoration: const InputDecoration(counterText: '', hintText: 'Enter new 4-digit PIN'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );

      if (newPin != null && newPin.length == 4) {
        await ref.read(settingsProvider.notifier).setAdminPin(newPin);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN updated')),
          );
        }
      }
    }
  }

  Future<void> _importCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final rows = const CsvToListConverter().convert(content);

        if (rows.isEmpty) {
          _showError('CSV file is empty');
          return;
        }

        final header = rows.first.map((e) => e.toString().toLowerCase()).toList();
        final idIdx = header.indexOf('id');
        final nameIdx = header.indexOf('name');
        final gradeIdx = header.indexOf('grade');
        final sectionIdx = header.indexOf('section');

        if (idIdx == -1 || nameIdx == -1) {
          _showError('CSV must have "id" and "name" columns');
          return;
        }

        int imported = 0;
        final now = DateTime.now().toIso8601String();

        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];
          if (row.length > idIdx && row.length > nameIdx) {
            final student = Student(
              id: row[idIdx].toString().trim(),
              name: row[nameIdx].toString().trim(),
              grade: gradeIdx != -1 && row.length > gradeIdx
                  ? row[gradeIdx].toString().trim()
                  : 'Unknown',
              section: sectionIdx != -1 && row.length > sectionIdx
                  ? row[sectionIdx].toString().trim()
                  : null,
              createdAt: now,
            );
            await DatabaseHelper.instance.upsertStudent(student);
            imported++;
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported $imported students')),
          );
        }
      }
    } catch (e) {
      _showError('Failed to import: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.deniedRed),
    );
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Clear Today\'s Logs', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Are you sure you want to clear all logs for today? This cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: AppColors.deniedRed)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.clearTodayLogs();
      ref.invalidate(todayLogsProvider);
      ref.invalidate(todayStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Today\'s logs cleared')),
        );
      }
    }
  }

  Future<void> _backupDb() async {
    try {
      final dbPath = await DatabaseHelper.instance.getDbPath();
      final dbFile = File(dbPath);
      
      if (!await dbFile.exists()) {
        _showError('Database file not found');
        return;
      }

      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) {
        _showError('Could not access downloads folder');
        return;
      }

      final backupPath = '${downloadsDir.path}/disciscan_backup_${DateTime.now().millisecondsSinceEpoch}.db';
      await dbFile.copy(backupPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup saved to $backupPath')),
        );
      }
    } catch (e) {
      _showError('Backup failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            'Gate Configuration',
            [
              _buildTextField(
                label: 'Gate Name',
                controller: _gateController,
                onSave: _saveGateName,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Guard Name',
                controller: _guardController,
                onSave: _saveGuardName,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Security',
            [
              ListTile(
                leading: const Icon(Icons.pin, color: AppColors.amber),
                title: const Text('Change Admin PIN', style: TextStyle(color: AppColors.textPrimary)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                onTap: _changePin,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Data Management',
            [
              ListTile(
                leading: const Icon(Icons.upload_file, color: AppColors.amber),
                title: const Text('Import Students CSV', style: TextStyle(color: AppColors.textPrimary)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                onTap: _importCsv,
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: AppColors.deniedRed),
                title: const Text('Clear Today\'s Logs', style: TextStyle(color: AppColors.textPrimary)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                onTap: _clearLogs,
              ),
              ListTile(
                leading: const Icon(Icons.backup, color: AppColors.amber),
                title: const Text('Backup Database', style: TextStyle(color: AppColors.textPrimary)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                onTap: _backupDb,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'DisciScan v1.0.0',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.amber,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onSave,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onSave,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}