import 'package:flutter/material.dart';
import '../../domain/entities/api_log_entity.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class StatusBadge extends StatelessWidget {
  final int? statusCode;
  final LogStatus status;

  const StatusBadge({super.key, required this.statusCode, required this.status});

  Color _color() {
    if (status == LogStatus.error) return AppColors.error;
    if (status == LogStatus.loading) return AppColors.warning;
    final code = statusCode ?? 0;
    if (code >= 200 && code < 300) return AppColors.success;
    if (code >= 300 && code < 400) return AppColors.info;
    if (code >= 400) return AppColors.error;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final label = statusCode?.toString() ?? (status == LogStatus.loading ? '...' : 'ERR');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelLarge.copyWith(color: color, fontSize: 11),
      ),
    );
  }
}
