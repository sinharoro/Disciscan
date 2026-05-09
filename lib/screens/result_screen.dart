import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import '../db/models/scan_log.dart';
import '../theme.dart';
import '../widgets/compliance_badge.dart';
import '../widgets/countdown_bar.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final ScanLog scanLog;

  const ResultScreen({super.key, required this.scanLog});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _soundPlayed = false;

  @override
  void initState() {
    super.initState();
    _playSound();
  }

  Future<void> _playSound() async {
    if (_soundPlayed) return;
    _soundPlayed = true;

    try {
      if (widget.scanLog.isGranted) {
        await _audioPlayer.play(AssetSource('sounds/success.mp3'));
      } else {
        await _audioPlayer.play(AssetSource('sounds/denied.mp3'));
      }
    } catch (e) {
      debugPrint('Audio playback error: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onComplete() {
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGranted = widget.scanLog.isGranted;
    final bgColor = isGranted ? AppColors.deepGreen : AppColors.deepRed;
    final icon = isGranted ? Icons.check_circle : Icons.cancel;
    final statusText = isGranted ? 'ACCESS GRANTED' : 'ENTRY DENIED';

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                icon,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              _buildInfoCard(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ComplianceBadge(
                    isCompliant: widget.scanLog.uniformComplete,
                    label: 'Uniform',
                  ),
                  const SizedBox(width: 12),
                  ComplianceBadge(
                    isCompliant: widget.scanLog.idVisible,
                    label: 'ID visible',
                  ),
                ],
              ),
              if (!isGranted && widget.scanLog.deniedReason != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.amber,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.amber,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.scanLog.deniedReason!,
                          style: const TextStyle(
                            color: AppColors.amber,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              CountdownBar(
                onComplete: _onComplete,
                onDismiss: _onComplete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            widget.scanLog.studentName ?? widget.scanLog.studentId,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.scanLog.grade != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.scanLog.grade!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            widget.scanLog.formattedTime,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}