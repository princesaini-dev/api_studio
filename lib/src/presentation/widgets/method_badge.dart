import 'package:flutter/material.dart';
import '../../domain/entities/api_log_entity.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class MethodBadge extends StatelessWidget {
  final HttpMethod method;
  final double? fontSize;

  const MethodBadge({super.key, required this.method, this.fontSize});

  Color _color() {
    return switch (method) {
      HttpMethod.get => AppColors.methodGet,
      HttpMethod.post => AppColors.methodPost,
      HttpMethod.put => AppColors.methodPut,
      HttpMethod.patch => AppColors.methodPatch,
      HttpMethod.delete => AppColors.methodDelete,
      HttpMethod.head => AppColors.methodHead,
      HttpMethod.options => AppColors.methodOptions,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        method.name.toUpperCase(),
        style: AppTextStyles.labelLarge.copyWith(color: color, fontSize: fontSize ?? 11),
      ),
    );
  }
}
