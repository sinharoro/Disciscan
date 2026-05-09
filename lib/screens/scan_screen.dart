import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/scan_provider.dart';
import '../providers/settings_provider.dart';
import '../theme.dart';
import '../widgets/scan_bracket.dart';
import '../widgets/student_card.dart';
import '../widgets/pin_dialog.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  MobileScannerController? _scannerController;
  final _idController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _clockTimer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _initScanner();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
  }

  void _initScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  void _updateClock() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    setState(() {
      _currentTime = '$displayHour:$minute:$second $period';
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _idController.dispose();
    _focusNode.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue?.trim();
      if (code != null && code.isNotEmpty) {
        _idController.text = code;
        ref.read(scanProvider.notifier).lookupStudent(code);
        _focusNode.unfocus();
      }
    }
  }

  Future<void> _confirmEntry() async {
    final settings = ref.read(settingsProvider);
    final scanLog = await ref.read(scanProvider.notifier).confirmEntry(
      settings.gateName,
      settings.guardName,
    );

    if (scanLog != null && mounted) {
      context.pushReplacement('/result', extra: scanLog);
      ref.read(scanProvider.notifier).reset();
      _idController.clear();
    }
  }

  void _openLogScreen() async {
    final settings = ref.read(settingsProvider);
    final verified = await showPinDialog(
      context,
      expectedPin: settings.adminPin,
      onVerify: (_) {},
    );
    if (verified == true && mounted) {
      context.push('/log');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(settings.gateName),
            Expanded(
              flex: 11,
              child: _buildCameraSection(),
            ),
            Expanded(
              flex: 9,
              child: _buildFormSection(scanState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(String gateName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.darkSurface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.door_front_door_outlined,
                color: AppColors.amber,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                gateName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            _currentTime,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history, size: 20),
            color: AppColors.textSecondary,
            onPressed: _openLogScreen,
            tooltip: 'View Log',
          ),
        ],
      ),
    );
  }

  Widget _buildCameraSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _scannerController != null
                ? MobileScanner(
                    controller: _scannerController!,
                    onDetect: _onDetect,
                    errorBuilder: (context, error, child) {
                      return _buildCameraError(error.errorCode.name);
                    },
                  )
                : _buildCameraError('uninitialized'),
            Center(
              child: ScanBracket(size: 240),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraError(String message) {
    return Container(
      color: AppColors.darkSurface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Camera: $message',
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection(ScanState scanState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _idController,
            focusNode: _focusNode,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
            ),
            decoration: InputDecoration(
              hintText: 'Student ID',
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              prefixIcon: const Icon(
                Icons.qr_code,
                color: AppColors.amber,
              ),
              suffixIcon: scanState.studentId.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      color: AppColors.textSecondary,
                      onPressed: () {
                        _idController.clear();
                        ref.read(scanProvider.notifier).reset();
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              ref.read(scanProvider.notifier).setStudentId(value);
            },
            onSubmitted: (value) {
              ref.read(scanProvider.notifier).lookupStudent(value);
            },
          ),
          if (scanState.error != null) ...[
            const SizedBox(height: 8),
            Text(
              scanState.error!,
              style: const TextStyle(
                color: AppColors.deniedRed,
                fontSize: 13,
              ),
            ),
          ],
          if (scanState.student != null) ...[
            const SizedBox(height: 12),
            StudentCard(student: scanState.student!),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildToggleRow(
                  'Complete uniform',
                  scanState.uniformComplete,
                  () => ref.read(scanProvider.notifier).toggleUniformComplete(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildToggleRow(
                  'ID visible',
                  scanState.idVisible,
                  () => ref.read(scanProvider.notifier).toggleIdVisible(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: scanState.canConfirm ? _confirmEntry : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: scanState.canConfirm
                  ? AppColors.deepIndigo
                  : AppColors.darkCard,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              scanState.scanType == 'entry'
                  ? 'CONFIRM ENTRY'
                  : 'CONFIRM EXIT',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {
                ref.read(scanProvider.notifier).toggleScanType();
              },
              child: Text(
                'Scan type: ${scanState.scanType.toUpperCase()} | Tap to toggle',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String label, bool value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: value
              ? AppColors.grantedGreen.withOpacity(0.2)
              : AppColors.darkCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? AppColors.grantedGreen : AppColors.divider,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              value ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: value ? AppColors.grantedGreen : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: value ? AppColors.grantedGreen : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}