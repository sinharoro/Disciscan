import 'package:flutter/material.dart';
import '../theme.dart';

class StatsRow extends StatelessWidget {
  final Map<String, int> stats;

  const StatsRow({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          label: 'Total',
          value: stats['total'] ?? 0,
          color: AppColors.textPrimary,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Granted',
          value: stats['granted'] ?? 0,
          color: AppColors.grantedGreen,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Denied',
          value: stats['denied'] ?? 0,
          color: AppColors.deniedRed,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Exit',
          value: stats['exit'] ?? 0,
          color: AppColors.amber,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}