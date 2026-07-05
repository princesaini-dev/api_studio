import 'package:flutter/material.dart';
import '../../domain/entities/api_log_entity.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class StatusBadge extends StatelessWidget {
  final int? statusCode;
  final LogStatus status;

  const StatusBadge(
      {super.key, required this.statusCode, required this.status});

  Color _color() {
    if (status == LogStatus.loading) return AppColors.warning;
    final code = statusCode ?? 0;
    if (code >= 500) return AppColors.status5xx;
    if (code >= 400) return AppColors.status4xx;
    if (code >= 300) return AppColors.status3xx;
    if (code >= 200) return AppColors.status2xx;
    if (status == LogStatus.error) return AppColors.error;
    return AppColors.warning;
  }

  String _label() {
    if (statusCode != null) return statusCode.toString();
    if (status == LogStatus.loading) return '...';
    if (status == LogStatus.cancelled) return 'CXL';
    return 'ERR';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final label = _label();
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
