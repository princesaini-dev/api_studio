import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/di_service.dart';
import '../../theme/api_inspector_theme.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/dimensions.dart';
import '../blocs/export/export_bloc.dart';
import '../blocs/export/export_event.dart';
import '../blocs/export/export_state.dart';
import '../blocs/inspector_list/inspector_list_bloc.dart';
import '../blocs/inspector_list/inspector_list_event.dart';
import '../blocs/inspector_list/inspector_list_state.dart';
import '../widgets/filter_chip_bar.dart';
import '../widgets/log_card.dart';
import '../widgets/search_bar_widget.dart';
import 'inspector_detail_screen.dart';

class InspectorListScreen extends StatelessWidget {
  const InspectorListScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => const InspectorListScreen());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (_) =>
                DiService.createListBloc()..add(const LoadLogsEvent())),
        BlocProvider(create: (_) => DiService.createExportBloc()),
      ],
      child: const _InspectorListView(),
    );
  }
}

class _InspectorListView extends StatelessWidget {
  const _InspectorListView();

  @override
  Widget build(BuildContext context) {
    final theme = ApiInspectorTheme.of(context);

    return BlocListener<ExportBloc, ExportState>(
      listener: (context, state) {
        if (state.status == ExportStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Export failed')),
          );
        }
      },
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: _buildAppBar(context, theme),
        body: Column(
          children: [
            _SearchAndFilterSection(theme: theme),
            const Expanded(child: _LogListSection()),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, dynamic theme) {
    return AppBar(
      backgroundColor: theme.surfaceColor,
      elevation: 0,
      scrolledUnderElevation: 1,
      title: Text(
        'API Inspector',
        style: AppTextStyles.headlineMedium
            .copyWith(color: theme.textPrimaryColor),
      ),
      actions: [
        BlocBuilder<InspectorListBloc, InspectorListState>(
          buildWhen: (p, c) => p.logs.length != c.logs.length,
          builder: (context, state) => state.logs.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.delete_sweep_outlined,
                      color: theme.textSecondaryColor),
                  tooltip: 'Clear all logs',
                  onPressed: () => _confirmClear(context),
                )
              : const SizedBox.shrink(),
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.ios_share_rounded, color: theme.textSecondaryColor),
          tooltip: 'Export',
          color: theme.cardColor,
          onSelected: (v) {
            final bloc = context.read<ExportBloc>();
            if (v == 'json') bloc.add(const ExportAsJsonEvent());
            if (v == 'txt') bloc.add(const ExportAsTxtEvent());
          },
          itemBuilder: (_) => [
            PopupMenuItem(
                value: 'json',
                child: Text('Export as JSON',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: theme.textPrimaryColor))),
            PopupMenuItem(
                value: 'txt',
                child: Text('Export as TXT',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: theme.textPrimaryColor))),
          ],
        ),
      ],
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all logs?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<InspectorListBloc>().add(const ClearAllLogsEvent());
            },
            child:
                const Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SearchAndFilterSection extends StatelessWidget {
  final dynamic theme;
  const _SearchAndFilterSection({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.surfaceColor,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          SearchBarWidget(
            onChanged: (q) =>
                context.read<InspectorListBloc>().add(SearchLogsEvent(q)),
          ),
          const SizedBox(height: 10),
          BlocBuilder<InspectorListBloc, InspectorListState>(
            buildWhen: (p, c) =>
                p.methodFilter != c.methodFilter ||
                p.statusFilter != c.statusFilter ||
                p.sortOrder != c.sortOrder,
            builder: (context, state) => FilterChipBar(
              selectedMethod: state.methodFilter,
              selectedStatus: state.statusFilter,
              selectedSort: state.sortOrder,
              onMethodChanged: (f) =>
                  context.read<InspectorListBloc>().add(FilterMethodEvent(f)),
              onStatusChanged: (f) =>
                  context.read<InspectorListBloc>().add(FilterStatusEvent(f)),
              onSortChanged: (s) =>
                  context.read<InspectorListBloc>().add(SortLogsEvent(s)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogListSection extends StatefulWidget {
  const _LogListSection();

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
      context.read<InspectorListBloc>().add(const LoadMoreLogsEvent());
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
    return BlocBuilder<InspectorListBloc, InspectorListState>(
      builder: (context, state) {
        if (state.status == InspectorListStatus.loading && state.logs.isEmpty) {
          return Center(
              child: CircularProgressIndicator(color: theme.primaryColor));
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
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  context.read<InspectorListBloc>().add(DeleteLogEvent(log.id));
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_tethering_rounded,
              size: 64, color: theme.textSecondaryColor),
          const SizedBox(height: 16),
          Text('No API logs yet',
              style: AppTextStyles.headlineSmall
                  .copyWith(color: theme.textPrimaryColor)),
          const SizedBox(height: 8),
          Text('Make some requests to see them here',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: theme.textSecondaryColor)),
        ],
      ),
    );
  }
}
