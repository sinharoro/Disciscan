import 'package:flutter/material.dart';
import '../theme.dart';

class ComplianceBadge extends StatelessWidget {
  final bool isCompliant;
  final String label;
  final IconData? icon;

  const ComplianceBadge({
    super.key,
    required this.isCompliant,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCompliant
            ? AppColors.grantedGreen.withOpacity(0.2)
            : AppColors.deniedRed.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompliant ? AppColors.grantedGreen : AppColors.deniedRed,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? (isCompliant ? Icons.check : Icons.close),
            size: 16,
            color: isCompliant ? AppColors.grantedGreen : AppColors.deniedRed,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isCompliant ? AppColors.grantedGreen : AppColors.deniedRed,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}