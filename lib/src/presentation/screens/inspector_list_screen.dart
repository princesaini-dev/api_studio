import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../services/di_service.dart';
import '../../theme/api_inspector_theme.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/dimensions.dart';
import '../states/export_state.dart';
import '../states/inspector_list_state.dart';
import '../controllers/export_controller.dart';
import '../controllers/inspector_list_controller.dart';
import '../widgets/filter_chip_bar.dart';
import '../widgets/log_card.dart';
import '../widgets/search_bar_widget.dart';
import 'inspector_detail_screen.dart';

class InspectorListScreen extends StatefulWidget {
  const InspectorListScreen({super.key});

  static Route<void> route() {
    return PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => const InspectorListScreen(),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  @override
  State<InspectorListScreen> createState() => _InspectorListScreenState();
}

class _InspectorListScreenState extends State<InspectorListScreen> {
  late final InspectorListController _listController;
  late final ExportController _exportController;

  @override
  void initState() {
    super.initState();
    _listController = DiService.createListController();
    _exportController = DiService.createExportController();
    _listController.loadLogs();
  }

  @override
  void dispose() {
    _listController.dispose();
    _exportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InspectorListView(
      listController: _listController,
      exportController: _exportController,
    );
  }
}

class _InspectorListView extends StatefulWidget {
  final InspectorListController listController;
  final ExportController exportController;

  const _InspectorListView({
    required this.listController,
    required this.exportController,
  });

  @override
  State<_InspectorListView> createState() => _InspectorListViewState();
}

class _InspectorListViewState extends State<_InspectorListView> {
  ExportStatus? _lastExportStatus;

  @override
  void initState() {
    super.initState();
    widget.exportController.addListener(_onExportChanged);
  }

  @override
  void dispose() {
    widget.exportController.removeListener(_onExportChanged);
    super.dispose();
  }

  void _onExportChanged() {
    final status = widget.exportController.state.status;
    if (status == ExportStatus.failure &&
        _lastExportStatus != ExportStatus.failure) {
      _lastExportStatus = status;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(widget.exportController.state.errorMessage ??
                    'Export failed')),
          );
        }
      });
    } else {
      _lastExportStatus = status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ApiInspectorTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: _buildAppBar(context, theme),
      body: Column(
        children: [
          _SearchAndFilterSection(
            theme: theme,
            controller: widget.listController,
          ),
          Expanded(
            child: _LogListSection(controller: widget.listController),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, dynamic theme) {
    return AppBar(
      backgroundColor: theme.surfaceColor,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleSpacing: Dimensions.lg,
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Dimensions.radiusSm),
            ),
            child: const Icon(Icons.radar_rounded,
                size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: Dimensions.sm),
          Text(
            AppStrings.appTitle,
            style: AppTextStyles.headlineMedium
                .copyWith(color: theme.textPrimaryColor),
          ),
        ],
      ),
      actions: [
        AnimatedBuilder(
          animation: widget.listController,
          builder: (context, child) {
            final logs = widget.listController.state.logs;
            return logs.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.delete_sweep_outlined,
                        color: theme.textSecondaryColor,
                        size: Dimensions.iconMd),
                    tooltip: AppStrings.clearAllLogs,
                    onPressed: () => _confirmClear(context, theme),
                  )
                : const SizedBox.shrink();
          },
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.ios_share_rounded,
              color: theme.textSecondaryColor, size: Dimensions.iconMd),
          tooltip: AppStrings.exportLogs,
          color: theme.cardColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusMd)),
          onSelected: (v) {
            if (v == 'json') widget.exportController.exportAsJson();
            if (v == 'txt') widget.exportController.exportAsTxt();
          },
          itemBuilder: (_) => [
            PopupMenuItem(
                value: 'json',
                child: Row(
                  children: [
                    const Icon(Icons.data_object_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: Dimensions.sm),
                    Text(AppStrings.exportAsJson,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: theme.textPrimaryColor)),
                  ],
                )),
            PopupMenuItem(
                value: 'txt',
                child: Row(
                  children: [
                    Icon(Icons.text_snippet_outlined,
                        size: 16, color: theme.textSecondaryColor),
                    const SizedBox(width: Dimensions.sm),
                    Text(AppStrings.exportAsTxt,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: theme.textPrimaryColor)),
                  ],
                )),
          ],
        ),
        const SizedBox(width: Dimensions.xs),
      ],
    );
  }

  void _confirmClear(BuildContext context, dynamic theme) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusLg)),
        title: Text(AppStrings.confirmClearTitle,
            style: AppTextStyles.headlineSmall
                .copyWith(color: theme.textPrimaryColor)),
        content: Text(AppStrings.confirmClearMessage,
            style: AppTextStyles.bodyMedium
                .copyWith(color: theme.textSecondaryColor)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.cancel,
                  style: AppTextStyles.labelLarge
                      .copyWith(color: theme.textSecondaryColor))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.listController.clearAllLogs();
            },
            child: Text(AppStrings.clear,
                style:
                    AppTextStyles.labelLarge.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SearchAndFilterSection extends StatelessWidget {
  final dynamic theme;
  final InspectorListController controller;
  const _SearchAndFilterSection(
      {required this.theme, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.surfaceColor,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          SearchBarWidget(
            onChanged: (q) => controller.searchLogs(q),
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final state = controller.state;
              return FilterChipBar(
                selectedMethod: state.methodFilter,
                selectedStatus: state.statusFilter,
                selectedSort: state.sortOrder,
                onMethodChanged: (f) => controller.filterMethod(f),
                onStatusChanged: (f) => controller.filterStatus(f),
                onSortChanged: (s) => controller.sortLogs(s),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LogListSection extends StatefulWidget {
  final InspectorListController controller;
  const _LogListSection({required this.controller});

  @override
  State<_LogListSection> createState() => _LogListSectionState();
}

class _LogListSectionState extends State<_LogListSection> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.controller.loadMoreLogs();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ApiInspectorTheme.of(context);
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        if (state.status == InspectorListStatus.loading && state.logs.isEmpty) {
          return ListView.separated(
            padding: const EdgeInsets.all(Dimensions.lg),
            itemCount: 6,
            separatorBuilder: (_, __) => const SizedBox(height: Dimensions.sm),
            itemBuilder: (_, __) => const _ShimmerCard(),
          );
        }

        if (state.status == InspectorListStatus.failure) {
          return Center(
            child: Text(state.errorMessage ?? 'Something went wrong',
                style:
                    AppTextStyles.bodyMedium.copyWith(color: theme.errorColor)),
          );
        }

        if (state.logs.isEmpty) {
          return _EmptyState(theme: theme);
        }

        return ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.all(Dimensions.lg),
          itemCount:
              state.hasReachedMax ? state.logs.length : state.logs.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: Dimensions.sm),
          itemBuilder: (context, i) {
            if (i >= state.logs.length) {
              return Center(
                  child: CircularProgressIndicator(color: theme.primaryColor));
            }
            final log = state.logs[i];
            return LogCard(
              log: log,
              onTap: () => Navigator.of(context).push(
                InspectorDetailScreen.route(logId: log.id),
              ),
              onDelete: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: theme.cardColor,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusLg)),
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
                  widget.controller.deleteLog(log.id);
                }
              },
            );
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final dynamic theme;
  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Dimensions.radiusXl),
              ),
              child: const Icon(Icons.wifi_tethering_rounded,
                  size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: Dimensions.lg),
            Text(AppStrings.noLogsTitle,
                style: AppTextStyles.headlineSmall
                    .copyWith(color: theme.textPrimaryColor),
                textAlign: TextAlign.center),
            const SizedBox(height: Dimensions.xs),
            Text(AppStrings.noLogsSubtitle,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: theme.textSecondaryColor),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _anim = Tween<double>(begin: -1.5, end: 1.5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ApiInspectorTheme.of(context);
    final base =
        theme.isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBase;
    final highlight = theme.isDark
        ? AppColors.shimmerHighlightDark
        : AppColors.shimmerHighlight;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: 76,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(theme.borderRadius),
          border: Border.all(color: theme.borderColor, width: 0.8),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [base, highlight, base],
            stops: [
              (_anim.value + 1.5) / 3 - 0.3,
              (_anim.value + 1.5) / 3,
              (_anim.value + 1.5) / 3 + 0.3,
            ].map((s) => s.clamp(0.0, 1.0)).toList(),
          ),
        ),
      ),
    );
  }
}
