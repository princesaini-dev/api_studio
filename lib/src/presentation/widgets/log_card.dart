import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/extensions/datetime_extensions.dart';
import '../../domain/entities/api_log_entity.dart';
import '../../theme/api_inspector_theme.dart';
import '../../theme/app_colors.dart';
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

  Color _statusLineColor() {
    if (log.status == LogStatus.loading) return AppColors.statusLoading;
    if (log.status == LogStatus.cancelled) return AppColors.statusCancelled;
    if (log.status == LogStatus.error && log.statusCode == null) {
      return AppColors.statusNetwork;
    }
    final code = log.statusCode ?? 0;
    if (code >= 500) return AppColors.status5xx;
    if (code >= 400) return AppColors.status4xx;
    if (code >= 300) return AppColors.status3xx;
    if (code >= 200) return AppColors.status2xx;
    return AppColors.statusLoading;
  }

  Color _durationColor() {
    final ms = log.durationMs ?? 0;
    if (ms < 300) return AppColors.durationFast;
    if (ms < 1000) return AppColors.durationMedium;
    return AppColors.durationSlow;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ApiInspectorTheme.of(context);
    final statusLineColor = _statusLineColor();

    return RepaintBoundary(
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(theme.borderRadius),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.borderColor, width: 0.8),
              borderRadius: BorderRadius.circular(theme.borderRadius),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(theme.borderRadius - 0.8),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left status accent bar
                    Container(width: 3, color: statusLineColor),
                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Dimensions.md,
                          Dimensions.sm + 2,
                          Dimensions.sm,
                          Dimensions.sm + 2,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Top row — badges + overflow
                            Row(
                              children: [
                                MethodBadge(method: log.method),
                                const SizedBox(width: Dimensions.xs + 2),
                                StatusBadge(
                                    statusCode: log.statusCode,
                                    status: log.status),
                                if (log.isEdited) ...[
                                  const SizedBox(width: Dimensions.xs + 2),
                                  const EditedBadge(),
                                ],
                                if (log.isMultipart) ...[
                                  const SizedBox(width: Dimensions.xs + 2),
                                  _MultipartBadge(),
                                ],
                                const Spacer(),
                                if (onDelete != null)
                                  _DeleteButton(onDelete: onDelete!),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // URL — host dimmed, path prominent
                            _UrlDisplay(url: log.url, theme: theme),
                            const SizedBox(height: 6),
                            // Bottom row — meta info
                            Row(
                              children: [
                                _MetaChip(
                                  icon: Icons.access_time_rounded,
                                  label: log.timestamp.relativeTime,
                                  theme: theme,
                                ),
                                if (log.durationMs != null) ...[
                                  const SizedBox(width: Dimensions.sm),
                                  _DurationChip(
                                    ms: log.durationMs!,
                                    color: _durationColor(),
                                    theme: theme,
                                  ),
                                ],
                                if (log.responseSizeBytes != null) ...[
                                  const SizedBox(width: Dimensions.sm),
                                  _MetaChip(
                                    icon: Icons.arrow_downward_rounded,
                                    label: AppStrings.formatBytes(
                                        log.responseSizeBytes),
                                    theme: theme,
                                  ),
                                ],
                                if (log.requestSizeBytes != null &&
                                    log.requestSizeBytes! > 0) ...[
                                  const SizedBox(width: Dimensions.sm),
                                  _MetaChip(
                                    icon: Icons.arrow_upward_rounded,
                                    label: AppStrings.formatBytes(
                                        log.requestSizeBytes),
                                    theme: theme,
                                  ),
                                ],
                                const Spacer(),
                                Icon(Icons.chevron_right_rounded,
                                    color: theme.textSecondaryColor,
                                    size: Dimensions.iconMd),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UrlDisplay extends StatelessWidget {
  final String url;
  final dynamic theme;
  const _UrlDisplay({required this.url, required this.theme});

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return Text(
        url,
        style: AppTextStyles.bodyMedium.copyWith(
          color: theme.textPrimaryColor,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    final host = uri.host.isNotEmpty ? '${uri.host} ' : '';
    final path = uri.path.isNotEmpty ? uri.path : '/';

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          if (host.isNotEmpty)
            TextSpan(
              text: host,
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.textSecondaryColor,
                fontWeight: FontWeight.w400,
              ),
            ),
          TextSpan(
            text: path,
            style: AppTextStyles.bodyMedium.copyWith(
              color: theme.textPrimaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic theme;
  const _MetaChip(
      {required this.icon, required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: theme.textSecondaryColor),
        const SizedBox(width: 3),
        Text(label,
            style: AppTextStyles.labelSmall
                .copyWith(color: theme.textSecondaryColor)),
      ],
    );
  }
}

class _DurationChip extends StatelessWidget {
  final int ms;
  final Color color;
  final dynamic theme;
  const _DurationChip(
      {required this.ms, required this.color, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.speed_rounded, size: 10, color: color),
        const SizedBox(width: 3),
        Text(
          AppStrings.formatDuration(ms),
          style: AppTextStyles.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback onDelete;
  const _DeleteButton({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDelete,
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.xs),
        child: Icon(
          Icons.delete_outline_rounded,
          size: Dimensions.iconSm,
          color: AppColors.textSecondaryLight.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _MultipartBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusSm),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.35)),
      ),
      child: Text(
        AppStrings.multipartBadge,
        style: AppTextStyles.labelSmall
            .copyWith(color: AppColors.info, fontSize: 9),
      ),
    );
  }
}
