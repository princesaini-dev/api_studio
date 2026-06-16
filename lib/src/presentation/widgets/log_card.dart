import 'package:flutter/material.dart';
import '../../core/extensions/datetime_extensions.dart';
import '../../domain/entities/api_log_entity.dart';
import '../../theme/api_inspector_theme.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/dimensions.dart';
import 'edited_badge.dart';
import 'method_badge.dart';
import 'status_badge.dart';

class LogCard extends StatelessWidget {
  final ApiLogEntity log;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const LogCard({
    super.key,
    required this.log,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ApiInspectorTheme.of(context);

    return RepaintBoundary(
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(theme.borderRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.lg,
              vertical: Dimensions.md,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: theme.borderColor, width: 0.8),
              borderRadius: BorderRadius.circular(theme.borderRadius),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          MethodBadge(method: log.method),
                          const SizedBox(width: Dimensions.sm),
                          StatusBadge(statusCode: log.statusCode, status: log.status),
                          if (log.isEdited) ...[
                            const SizedBox(width: Dimensions.sm),
                            const EditedBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        log.url,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: theme.textPrimaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 11, color: theme.textSecondaryColor),
                          const SizedBox(width: 3),
                          Text(
                            log.timestamp.relativeTime,
                            style: AppTextStyles.labelSmall
                                .copyWith(color: theme.textSecondaryColor),
                          ),
                          if (log.durationMs != null) ...[
                            const SizedBox(width: Dimensions.sm),
                            Icon(Icons.speed_rounded,
                                size: 11, color: theme.textSecondaryColor),
                            const SizedBox(width: 3),
                            Text(
                              '${log.durationMs}ms',
                              style: AppTextStyles.labelSmall
                                  .copyWith(color: theme.textSecondaryColor),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        size: Dimensions.iconMd, color: theme.textSecondaryColor),
                    onPressed: onDelete,
                    splashRadius: 20,
                  ),
                Icon(Icons.chevron_right_rounded,
                    color: theme.textSecondaryColor, size: Dimensions.iconMd),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
