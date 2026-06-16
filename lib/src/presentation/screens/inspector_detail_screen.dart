import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    return MaterialPageRoute(
      builder: (_) => InspectorDetailScreen(logId: logId),
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MethodBadge(method: log.method),
              const SizedBox(width: 8),
              if (log.isEdited) const EditedBadge(),
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
      actions: [
        IconButton(
          icon: Icon(Icons.terminal_rounded, color: theme.textSecondaryColor),
          tooltip: 'Copy CURL',
          onPressed: () => CurlPreviewSheet.show(context, log),
        ),
        IconButton(
          icon: Icon(Icons.edit_rounded, color: theme.primaryColor),
          tooltip: 'Edit & Run',
          onPressed: () => Navigator.of(context).push(
            EditRunScreen.route(log: log),
          ),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline_rounded,
              color: theme.textSecondaryColor),
          tooltip: 'Delete',
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Request'),
                content: const Text(
                    'Are you sure you want to delete this request log? This cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
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
      ],
      bottom: TabBar(
        labelColor: theme.primaryColor,
        unselectedLabelColor: theme.textSecondaryColor,
        indicatorColor: theme.primaryColor,
        labelStyle: AppTextStyles.labelLarge,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Request'),
          Tab(text: 'Response'),
          Tab(text: 'Error'),
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
    return ListView(
      padding: const EdgeInsets.all(Dimensions.lg),
      children: [
        _InfoCard(theme: theme, children: [
          _InfoRow(
              label: 'URL', value: log.url, selectable: true, theme: theme),
          _InfoRow(label: 'Method', value: log.methodLabel, theme: theme),
          _InfoRow(
              label: 'Status',
              value: log.statusCode?.toString() ?? 'N/A',
              theme: theme),
          _InfoRow(
              label: 'Duration',
              value: log.durationMs != null ? '${log.durationMs}ms' : 'N/A',
              theme: theme),
          _InfoRow(
              label: 'Timestamp',
              value: log.timestamp.toIso8601String(),
              theme: theme),
          _InfoRow(
              label: 'Request Size',
              value: log.requestSizeBytes != null
                  ? '${log.requestSizeBytes} bytes'
                  : 'N/A',
              theme: theme),
          _InfoRow(
              label: 'Response Size',
              value: log.responseSizeBytes != null
                  ? '${log.responseSizeBytes} bytes'
                  : 'N/A',
              theme: theme),
        ]),
        const SizedBox(height: Dimensions.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.terminal_rounded, size: 16),
                label: const Text('Copy CURL'),
                onPressed: () => CurlPreviewSheet.show(context, log),
              ),
            ),
            const SizedBox(width: Dimensions.sm),
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Edit & Run'),
                onPressed: () => Navigator.of(context).push(
                  EditRunScreen.route(log: log),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RequestTab extends StatelessWidget {
  final ApiLogEntity log;
  const _RequestTab({required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = ApiInspectorTheme.of(context);
    return ListView(
      padding: const EdgeInsets.all(Dimensions.lg),
      children: [
        if (log.requestHeaders.isNotEmpty) ...[
          _SectionTitle(title: 'Headers', theme: theme),
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
          _SectionTitle(title: 'Query Params', theme: theme),
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
          _SectionTitle(title: 'Body', theme: theme, copyText: log.requestBody),
          JsonViewer(raw: log.requestBody),
          const SizedBox(height: Dimensions.lg),
        ],
        if (log.formData != null && log.formData!.isNotEmpty) ...[
          _SectionTitle(title: 'Form Data', theme: theme),
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
        StatusBadge(
            statusCode: widget.log.statusCode, status: widget.log.status),
        const SizedBox(height: Dimensions.sm),
        if (allHeaders.isNotEmpty) ...[
          _SectionTitle(title: 'Response Headers', theme: theme),
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
                        const SizedBox(width: 4),
                        Text(
                          _showAllHeaders
                              ? 'Show less'
                              : 'Show $hiddenCount more header${hiddenCount > 1 ? 's' : ''}',
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
          title: 'Response Body',
          theme: theme,
          copyText: widget.log.responseBody,
        ),
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 48, color: AppColors.success),
            const SizedBox(height: 12),
            Text('No errors',
                style: AppTextStyles.headlineSmall
                    .copyWith(color: theme.textPrimaryColor)),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(Dimensions.lg),
      children: [
        if (log.errorMessage != null) ...[
          _SectionTitle(
              title: 'Error Message', theme: theme, copyText: log.errorMessage),
          _CopyableBlock(content: log.errorMessage!, theme: theme),
          const SizedBox(height: Dimensions.lg),
        ],
        if (log.stackTrace != null) ...[
          _SectionTitle(
              title: 'Stack Trace', theme: theme, copyText: log.stackTrace),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor),
      ),
      child: SelectableText(
        content,
        style: AppTextStyles.monoSmall
            .copyWith(color: theme.textPrimaryColor, height: 1.6),
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
  final bool selectable;
  final dynamic theme;
  const _InfoRow(
      {required this.label,
      required this.value,
      this.selectable = false,
      required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            child: selectable
                ? SelectableText(value,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: theme.textPrimaryColor))
                : Text(value,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: theme.textPrimaryColor)),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(title,
              style: AppTextStyles.titleMedium
                  .copyWith(color: theme.textSecondaryColor)),
          if (copyText != null) ...[
            const Spacer(),
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                Clipboard.setData(ClipboardData(text: copyText!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy_rounded,
                        size: 13, color: theme.primaryColor),
                    const SizedBox(width: 4),
                    Text('Copy',
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
