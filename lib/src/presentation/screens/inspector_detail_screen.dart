import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/entities/api_log_entity.dart';
import '../../services/di_service.dart';
import '../../theme/api_inspector_theme.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/dimensions.dart';
import '../blocs/inspector_detail/inspector_detail_bloc.dart';
import '../blocs/inspector_detail/inspector_detail_event.dart';
import '../blocs/inspector_detail/inspector_detail_state.dart';
import '../widgets/curl_preview_sheet.dart';
import '../widgets/edited_badge.dart';
import '../widgets/json_viewer.dart';
import '../widgets/method_badge.dart';
import '../widgets/status_badge.dart';
import 'edit_run_screen.dart';

class InspectorDetailScreen extends StatelessWidget {
  final String logId;

  const InspectorDetailScreen({super.key, required this.logId});

  static Route<void> route({required String logId}) {
    return PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => InspectorDetailScreen(logId: logId),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DiService.createDetailBloc()..add(LoadDetailEvent(logId)),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  @override
  Widget build(BuildContext context) {
    final theme = ApiInspectorTheme.of(context);

    return BlocConsumer<InspectorDetailBloc, InspectorDetailState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) {
        if (state.status == DetailStatus.deleted) {
          Navigator.of(context).pop();
        }
        if (state.curlCopied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CURL copied to clipboard'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.status == DetailStatus.loading ||
            state.status == DetailStatus.initial) {
          return Scaffold(
            backgroundColor: theme.backgroundColor,
            body: Center(
                child: CircularProgressIndicator(color: theme.primaryColor)),
          );
        }

        if (state.status == DetailStatus.failure || state.log == null) {
          return Scaffold(
            backgroundColor: theme.backgroundColor,
            appBar: AppBar(backgroundColor: theme.surfaceColor),
            body: Center(
              child: Text(state.errorMessage ?? 'Log not found',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: theme.textSecondaryColor)),
            ),
          );
        }

        final log = state.log!;
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            backgroundColor: theme.backgroundColor,
            appBar: _buildAppBar(context, theme, log),
            body: TabBarView(
              children: [
                _OverviewTab(log: log),
                _RequestTab(log: log),
                _ResponseTab(log: log),
                _ErrorTab(log: log),
              ],
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, dynamic theme, ApiLogEntity log) {
    return AppBar(
      backgroundColor: theme.surfaceColor,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(left: Dimensions.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MethodBadge(method: log.method),
                const SizedBox(width: Dimensions.xs + 2),
                StatusBadge(statusCode: log.statusCode, status: log.status),
                if (log.isEdited) ...[
                  const SizedBox(width: Dimensions.xs + 2),
                  const EditedBadge(),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              log.shortUrl,
              style: AppTextStyles.bodySmall
                  .copyWith(color: theme.textSecondaryColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.terminal_rounded,
              color: theme.textSecondaryColor, size: Dimensions.iconMd),
          tooltip: AppStrings.copyCurl,
          onPressed: () => CurlPreviewSheet.show(context, log),
        ),
        IconButton(
          icon: Icon(Icons.edit_rounded,
              color: theme.primaryColor, size: Dimensions.iconMd),
          tooltip: AppStrings.editAndRun,
          onPressed: () => Navigator.of(context).push(
            EditRunScreen.route(log: log),
          ),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline_rounded,
              color: theme.textSecondaryColor, size: Dimensions.iconMd),
          tooltip: AppStrings.deleteLog,
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: theme.cardColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.radiusLg)),
                title: Text(AppStrings.confirmDeleteTitle,
                    style: AppTextStyles.headlineSmall
                        .copyWith(color: theme.textPrimaryColor)),
                content: Text(AppStrings.confirmDeleteMessage,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: theme.textSecondaryColor)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(AppStrings.cancel,
                        style: AppTextStyles.labelLarge
                            .copyWith(color: theme.textSecondaryColor)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(AppStrings.delete,
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.error)),
                  ),
                ],
              ),
            );
            if (confirmed == true && context.mounted) {
              context
                  .read<InspectorDetailBloc>()
                  .add(const DeleteDetailLogEvent());
            }
          },
        ),
        const SizedBox(width: Dimensions.xs),
      ],
      bottom: TabBar(
        labelColor: theme.primaryColor,
        unselectedLabelColor: theme.textSecondaryColor,
        indicatorColor: theme.primaryColor,
        indicatorWeight: 2.5,
        labelStyle: AppTextStyles.labelLarge,
        tabs: const [
          Tab(text: AppStrings.tabOverview),
          Tab(text: AppStrings.tabRequest),
          Tab(text: AppStrings.tabResponse),
          Tab(text: AppStrings.tabError),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final ApiLogEntity log;
  const _OverviewTab({required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = ApiInspectorTheme.of(context);
    final uri = Uri.tryParse(log.url);

    return ListView(
      padding: const EdgeInsets.all(Dimensions.lg),
      children: [
        // Status summary card
        _StatusSummaryCard(log: log, theme: theme),
        const SizedBox(height: Dimensions.md),

        // Timing & size metrics row
        _MetricsRow(log: log, theme: theme),
        const SizedBox(height: Dimensions.md),

        // Request info card
        _SectionTitle(title: AppStrings.tabRequest, theme: theme),
        _InfoCard(theme: theme, children: [
          _IconInfoRow(
              icon: Icons.link_rounded,
              label: AppStrings.labelUrl,
              value: log.url,
              selectable: true,
              theme: theme),
          _IconInfoRow(
              icon: Icons.http_rounded,
              label: AppStrings.labelMethod,
              value: log.methodLabel,
              theme: theme),
          if (uri != null && uri.host.isNotEmpty)
            _IconInfoRow(
                icon: Icons.dns_rounded,
                label: AppStrings.labelHost,
                value: uri.host,
                theme: theme),
          if (uri != null && uri.path.isNotEmpty)
            _IconInfoRow(
                icon: Icons.route_rounded,
                label: AppStrings.labelPath,
                value: uri.path,
                theme: theme),
        ]),
        const SizedBox(height: Dimensions.md),

        // Response info card
        _SectionTitle(title: AppStrings.tabResponse, theme: theme),
        _InfoCard(theme: theme, children: [
          _IconInfoRow(
              icon: Icons.tag_rounded,
              label: AppStrings.labelStatus,
              value: log.statusCode?.toString() ?? AppStrings.labelNotAvailable,
              valueColor: _statusColor(log),
              theme: theme),
          _IconInfoRow(
              icon: Icons.schedule_rounded,
              label: AppStrings.labelDuration,
              value: AppStrings.formatDuration(log.durationMs),
              theme: theme),
          _IconInfoRow(
              icon: Icons.arrow_downward_rounded,
              label: AppStrings.labelResponseSize,
              value: AppStrings.formatBytes(log.responseSizeBytes),
              theme: theme),
          _IconInfoRow(
              icon: Icons.arrow_upward_rounded,
              label: AppStrings.labelRequestSize,
              value: AppStrings.formatBytes(log.requestSizeBytes),
              theme: theme),
          _IconInfoRow(
              icon: Icons.calendar_today_rounded,
              label: AppStrings.labelTimestamp,
              value: log.timestamp.toLocal().toString().substring(0, 19),
              theme: theme),
        ]),
        const SizedBox(height: Dimensions.lg),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.terminal_rounded, size: 16),
                label: const Text(AppStrings.copyCurl),
                onPressed: () => CurlPreviewSheet.show(context, log),
              ),
            ),
            const SizedBox(width: Dimensions.sm),
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text(AppStrings.editAndRun),
                onPressed: () => Navigator.of(context).push(
                  EditRunScreen.route(log: log),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Dimensions.lg),
      ],
    );
  }

  Color _statusColor(ApiLogEntity log) {
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
}

class _StatusSummaryCard extends StatelessWidget {
  final ApiLogEntity log;
  final dynamic theme;
  const _StatusSummaryCard({required this.log, required this.theme});

  Color get _color {
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

  String get _statusLabel {
    if (log.status == LogStatus.loading) return 'In Progress';
    if (log.status == LogStatus.cancelled) return 'Cancelled';
    final code = log.statusCode ?? 0;
    if (code >= 500) return 'Server Error';
    if (code >= 400) return 'Client Error';
    if (code >= 300) return 'Redirect';
    if (code >= 200) return 'Success';
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.all(Dimensions.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(theme.borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Dimensions.radiusMd),
            ),
            child: Center(
              child: log.statusCode != null
                  ? Text(
                      log.statusCode.toString(),
                      style: AppTextStyles.titleLarge
                          .copyWith(color: color, fontWeight: FontWeight.w700),
                    )
                  : Icon(Icons.error_outline_rounded, color: color, size: 22),
            ),
          ),
          const SizedBox(width: Dimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_statusLabel,
                    style: AppTextStyles.titleMedium.copyWith(
                        color: theme.textPrimaryColor,
                        fontWeight: FontWeight.w600)),
                Text(log.shortUrl,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: theme.textSecondaryColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  final ApiLogEntity log;
  final dynamic theme;
  const _MetricsRow({required this.log, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MetricTile(
          icon: Icons.speed_rounded,
          label: 'Duration',
          value: AppStrings.formatDuration(log.durationMs),
          color: _durationColor(log.durationMs),
          theme: theme,
        ),
        const SizedBox(width: Dimensions.sm),
        _MetricTile(
          icon: Icons.arrow_downward_rounded,
          label: 'Response',
          value: AppStrings.formatBytes(log.responseSizeBytes),
          color: theme.textSecondaryColor,
          theme: theme,
        ),
        const SizedBox(width: Dimensions.sm),
        _MetricTile(
          icon: Icons.arrow_upward_rounded,
          label: 'Request',
          value: AppStrings.formatBytes(log.requestSizeBytes),
          color: theme.textSecondaryColor,
          theme: theme,
        ),
      ],
    );
  }

  Color _durationColor(int? ms) {
    if (ms == null) return AppColors.statusLoading;
    if (ms < 300) return AppColors.durationFast;
    if (ms < 1000) return AppColors.durationMedium;
    return AppColors.durationSlow;
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final dynamic theme;
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.md, vertical: Dimensions.sm + 2),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(theme.borderRadius),
          border: Border.all(color: theme.borderColor, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: Dimensions.xs),
            Text(value, style: AppTextStyles.labelLarge.copyWith(color: color)),
            Text(label,
                style: AppTextStyles.labelSmall
                    .copyWith(color: theme.textSecondaryColor)),
          ],
        ),
      ),
    );
  }
}

class _RequestTab extends StatelessWidget {
  final ApiLogEntity log;
  const _RequestTab({required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = ApiInspectorTheme.of(context);
    final hasContent = log.requestHeaders.isNotEmpty ||
        log.queryParams.isNotEmpty ||
        (log.requestBody != null && log.requestBody!.isNotEmpty) ||
        (log.formData != null && log.formData!.isNotEmpty);

    if (!hasContent) {
      return _EmptyTabState(
        icon: Icons.upload_rounded,
        title: AppStrings.noBody,
        subtitle: 'This request had no body, headers, or parameters.',
        theme: theme,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(Dimensions.lg),
      children: [
        if (log.requestHeaders.isNotEmpty) ...[
          _SectionTitle(
              title: AppStrings.sectionHeaders,
              theme: theme,
              copyText: log.requestHeaders.entries
                  .map((e) => '${e.key}: ${e.value}')
                  .join('\n')),
          _InfoCard(
            theme: theme,
            children: log.requestHeaders.entries
                .map((e) => _InfoRow(
                    label: e.key, value: e.value.toString(), theme: theme))
                .toList(),
          ),
          const SizedBox(height: Dimensions.lg),
        ],
        if (log.queryParams.isNotEmpty) ...[
          _SectionTitle(title: AppStrings.sectionQueryParams, theme: theme),
          _InfoCard(
            theme: theme,
            children: log.queryParams.entries
                .map((e) => _InfoRow(
                    label: e.key, value: e.value.toString(), theme: theme))
                .toList(),
          ),
          const SizedBox(height: Dimensions.lg),
        ],
        if (log.requestBody != null && log.requestBody!.isNotEmpty) ...[
          _SectionTitle(
              title: AppStrings.sectionBody,
              theme: theme,
              copyText: log.requestBody),
          JsonViewer(raw: log.requestBody),
          const SizedBox(height: Dimensions.lg),
        ],
        if (log.formData != null && log.formData!.isNotEmpty) ...[
          _SectionTitle(title: AppStrings.sectionFormData, theme: theme),
          _InfoCard(
            theme: theme,
            children: log.formData!.entries
                .map((e) => _InfoRow(
                    label: e.key, value: e.value.toString(), theme: theme))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _ResponseTab extends StatefulWidget {
  final ApiLogEntity log;
  const _ResponseTab({required this.log});

  @override
  State<_ResponseTab> createState() => _ResponseTabState();
}

class _ResponseTabState extends State<_ResponseTab> {
  static const _importantKeys = {
    'content-type',
    'content-length',
    'content-encoding',
    'cache-control',
    'date',
    'server',
    'etag',
    'last-modified',
    'location',
    'x-request-id',
    'x-correlation-id',
    'x-ratelimit-limit',
    'x-ratelimit-remaining',
    'x-ratelimit-reset',
  };

  bool _showAllHeaders = false;

  @override
  Widget build(BuildContext context) {
    final theme = ApiInspectorTheme.of(context);
    final allHeaders = widget.log.responseHeaders;
    final importantHeaders = Map.fromEntries(
      allHeaders.entries
          .where((e) => _importantKeys.contains(e.key.toLowerCase())),
    );
    final hiddenCount = allHeaders.length - importantHeaders.length;
    final displayedHeaders = _showAllHeaders ? allHeaders : importantHeaders;

    return ListView(
      padding: const EdgeInsets.all(Dimensions.lg),
      children: [
        if (allHeaders.isNotEmpty) ...[
          _SectionTitle(
              title: AppStrings.sectionResponseHeaders,
              theme: theme,
              copyText: allHeaders.entries
                  .map((e) => '${e.key}: ${e.value}')
                  .join('\n')),
          _InfoCard(
            theme: theme,
            children: [
              ...displayedHeaders.entries.map((e) => _InfoRow(
                  label: e.key, value: e.value.toString(), theme: theme)),
              if (hiddenCount > 0)
                InkWell(
                  onTap: () =>
                      setState(() => _showAllHeaders = !_showAllHeaders),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showAllHeaders
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: 16,
                          color: theme.primaryColor,
                        ),
                        const SizedBox(width: Dimensions.xs),
                        Text(
                          _showAllHeaders
                              ? AppStrings.showLess
                              : AppStrings.showMoreHeaders(hiddenCount),
                          style: AppTextStyles.bodySmall
                              .copyWith(color: theme.primaryColor),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Dimensions.lg),
        ],
        _SectionTitle(
          title: AppStrings.sectionResponseBody,
          theme: theme,
          copyText: widget.log.responseBody,
        ),
        if (widget.log.responseBody == null || widget.log.responseBody!.isEmpty)
          _EmptyTabState(
            icon: Icons.inbox_rounded,
            title: AppStrings.noResponse,
            subtitle: AppStrings.noResponseSubtitle,
            theme: theme,
          )
        else
          JsonViewer(raw: widget.log.responseBody),
      ],
    );
  }
}

class _ErrorTab extends StatelessWidget {
  final ApiLogEntity log;
  const _ErrorTab({required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = ApiInspectorTheme.of(context);
    if (!log.hasError && log.errorMessage == null) {
      return _EmptyTabState(
        icon: Icons.check_circle_rounded,
        iconColor: AppColors.success,
        title: AppStrings.noErrors,
        subtitle: AppStrings.noErrorsSubtitle,
        theme: theme,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(Dimensions.lg),
      children: [
        // Error summary banner
        Container(
          padding: const EdgeInsets.all(Dimensions.md),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(theme.borderRadius),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                ),
                child: const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 20),
              ),
              const SizedBox(width: Dimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.statusCode != null
                          ? 'HTTP ${log.statusCode}'
                          : 'Network Error',
                      style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.error, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      log.timestamp.toLocal().toString().substring(0, 19),
                      style: AppTextStyles.labelSmall
                          .copyWith(color: theme.textSecondaryColor),
                    ),
                  ],
                ),
              ),
              if (log.durationMs != null)
                Text(
                  AppStrings.formatDuration(log.durationMs),
                  style: AppTextStyles.labelMedium
                      .copyWith(color: theme.textSecondaryColor),
                ),
            ],
          ),
        ),
        const SizedBox(height: Dimensions.lg),

        if (log.errorMessage != null) ...[
          _SectionTitle(
              title: AppStrings.sectionErrorMessage,
              theme: theme,
              copyText: log.errorMessage),
          _CopyableBlock(content: log.errorMessage!, theme: theme),
          const SizedBox(height: Dimensions.lg),
        ],
        if (log.stackTrace != null) ...[
          _SectionTitle(
              title: AppStrings.sectionStackTrace,
              theme: theme,
              copyText: log.stackTrace),
          _CopyableBlock(content: log.stackTrace!, theme: theme),
        ],
      ],
    );
  }
}

class _CopyableBlock extends StatelessWidget {
  final String content;
  final dynamic theme;
  const _CopyableBlock({required this.content, required this.theme});

  @override
  Widget build(BuildContext context) {
    final codeColor =
        theme.isDark ? AppColors.codeBlockDark : AppColors.codeBlockLight;
    final codeBorder = theme.isDark
        ? AppColors.codeBlockBorderDark
        : AppColors.codeBlockBorderLight;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.md),
      decoration: BoxDecoration(
        color: codeColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusMd),
        border: Border.all(color: codeBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          content,
          style: AppTextStyles.monoSmall
              .copyWith(color: theme.textPrimaryColor, height: 1.65),
        ),
      ),
    );
  }
}

class _EmptyTabState extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final dynamic theme;
  const _EmptyTabState({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Dimensions.radiusXl),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: Dimensions.md),
            Text(title,
                style: AppTextStyles.headlineSmall
                    .copyWith(color: theme.textPrimaryColor),
                textAlign: TextAlign.center),
            const SizedBox(height: Dimensions.xs),
            Text(subtitle,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: theme.textSecondaryColor),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  final dynamic theme;
  const _InfoCard({required this.children, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.borderRadius),
        border: Border.all(color: theme.borderColor, width: 0.8),
      ),
      child: Column(
        children: children
            .asMap()
            .entries
            .map((e) => Column(
                  children: [
                    e.value,
                    if (e.key < children.length - 1)
                      Divider(height: 1, color: theme.borderColor),
                  ],
                ))
            .toList(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final dynamic theme;
  const _InfoRow(
      {required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.md, vertical: Dimensions.sm + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: theme.textSecondaryColor)),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: AppTextStyles.bodySmall
                  .copyWith(color: theme.textPrimaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final dynamic theme;
  final String? copyText;
  const _SectionTitle(
      {required this.title, required this.theme, this.copyText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.sm),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusFull),
            ),
          ),
          const SizedBox(width: Dimensions.sm),
          Text(title,
              style: AppTextStyles.labelLarge
                  .copyWith(color: theme.textPrimaryColor, letterSpacing: 0.3)),
          if (copyText != null) ...[
            const Spacer(),
            InkWell(
              borderRadius: BorderRadius.circular(Dimensions.radiusSm),
              onTap: () {
                Clipboard.setData(ClipboardData(text: copyText!));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppStrings.copied),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    width: 140,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.sm, vertical: Dimensions.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy_rounded,
                        size: 12, color: theme.primaryColor),
                    const SizedBox(width: Dimensions.xs),
                    Text(AppStrings.copy,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: theme.primaryColor)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IconInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool selectable;
  final Color? valueColor;
  final dynamic theme;
  const _IconInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
    this.selectable = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final vColor = valueColor ?? theme.textPrimaryColor;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.md, vertical: Dimensions.sm + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: theme.textSecondaryColor),
          const SizedBox(width: Dimensions.sm),
          SizedBox(
            width: 100,
            child: Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: theme.textSecondaryColor)),
          ),
          Expanded(
            child: selectable
                ? SelectableText(value,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: vColor, fontWeight: FontWeight.w500))
                : Text(value,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: vColor, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
