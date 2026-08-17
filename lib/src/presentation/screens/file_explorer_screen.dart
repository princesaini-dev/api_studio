import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/entities/file_explorer_entry.dart';
import '../../services/di_service.dart';
import '../../theme/api_inspector_theme.dart';
import '../../theme/api_inspector_theme_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/dimensions.dart';
import '../blocs/file_explorer/file_explorer_bloc.dart';
import '../blocs/file_explorer/file_explorer_event.dart';
import '../blocs/file_explorer/file_explorer_state.dart';
import '../widgets/breadcrumb_bar.dart';
import '../widgets/file_explorer/external_open_failure_dialog.dart';
import '../widgets/file_explorer/file_explorer_empty_state.dart';
import '../widgets/file_explorer/file_explorer_error_state.dart';
import '../widgets/file_explorer/file_explorer_header.dart';
import '../widgets/file_explorer/file_explorer_item.dart';
import '../widgets/file_explorer/file_explorer_loading_state.dart';

class FileExplorerScreen extends StatelessWidget {
  const FileExplorerScreen({super.key});

  static Route<void> route() {
    return PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => const FileExplorerScreen(),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DiService.createFileExplorerBloc()
        ..add(const FileExplorerLoadDirectoryEvent('')),
      child: const FileExplorerView(),
    );
  }
}

class FileExplorerView extends StatelessWidget {
  const FileExplorerView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ApiInspectorTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: FileExplorerHeader(
        theme: theme,
        isLoading: context.select<FileExplorerBloc, bool>(
          (bloc) => bloc.state.status == FileExplorerStatus.loading,
        ),
        onRefresh: () => context
            .read<FileExplorerBloc>()
            .add(const FileExplorerRefreshEvent()),
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Column(
        children: [
          BlocBuilder<FileExplorerBloc, FileExplorerState>(
            buildWhen: (p, c) => p.currentPath != c.currentPath,
            builder: (context, state) => BreadcrumbBar(
              breadcrumbs: state.breadcrumbs,
              onNavigate: (path) => context
                  .read<FileExplorerBloc>()
                  .add(FileExplorerNavigateToEvent(path)),
            ),
          ),
          const Expanded(child: FileExplorerContent()),
        ],
      ),
    );
  }
}

class FileExplorerContent extends StatelessWidget {
  const FileExplorerContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ApiInspectorTheme.of(context);

    return BlocBuilder<FileExplorerBloc, FileExplorerState>(
      buildWhen: (p, c) =>
          p.status != c.status ||
          p.entries != c.entries ||
          p.errorMessage != c.errorMessage,
      builder: (context, state) {
        switch (state.status) {
          case FileExplorerStatus.loading:
          case FileExplorerStatus.initial:
            return const FileExplorerLoadingState();
          case FileExplorerStatus.error:
            return FileExplorerErrorState(
              theme: theme,
              message: state.errorMessage ?? AppStrings.folderLoadFailed,
              onRetry: () => context
                  .read<FileExplorerBloc>()
                  .add(const FileExplorerRefreshEvent()),
            );
          case FileExplorerStatus.empty:
            return FileExplorerEmptyState(theme: theme);
          case FileExplorerStatus.loaded:
            if (state.entries.isEmpty) {
              return FileExplorerEmptyState(theme: theme);
            }
            return FileExplorerList(entries: state.entries, theme: theme);
        }
      },
    );
  }
}

class FileExplorerList extends StatelessWidget {
  final List<FileExplorerEntry> entries;
  final ApiInspectorThemeData theme;

  const FileExplorerList({
    super.key,
    required this.entries,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(Dimensions.lg),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: Dimensions.xs),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return FileExplorerItem(
          entry: entry,
          theme: theme,
          onTap: () => _onEntryTap(context, entry),
          onOpen: entry.isFile ? () => _openExternally(context, entry) : null,
          onDownload: entry.isFile ? () => _onDownload(context, entry) : null,
        );
      },
    );
  }

  void _onEntryTap(BuildContext context, FileExplorerEntry entry) {
    if (entry.isFolder) {
      context
          .read<FileExplorerBloc>()
          .add(FileExplorerNavigateToEvent(entry.path));
    } else {
      _openExternally(context, entry);
    }
  }

  void _openExternally(BuildContext context, FileExplorerEntry entry) async {
    try {
      final filePath =
          await DiService.fileActionService.getFilePath(entry.path);
      await Share.shareXFiles(
        [XFile(filePath)],
        text: entry.name,
      );
    } catch (_) {
      if (!context.mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => ExternalOpenFailureDialog(
          theme: theme,
          onDownload: () => _onDownload(context, entry),
        ),
      );
    }
  }

  void _onDownload(BuildContext context, FileExplorerEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusLg),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Dimensions.radiusXl),
              ),
              child: const Icon(Icons.download_rounded,
                  size: 28, color: AppColors.primary),
            ),
            const SizedBox(height: Dimensions.lg),
            Text(
              AppStrings.downloadConfirmation,
              style: AppTextStyles.headlineSmall
                  .copyWith(color: theme.textPrimaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimensions.xs),
            Text(
              AppStrings.downloadConfirmationSubtitle(entry.name),
              style: AppTextStyles.bodyMedium
                  .copyWith(color: theme.textSecondaryColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              AppStrings.cancel,
              style: AppTextStyles.titleMedium
                  .copyWith(color: theme.textSecondaryColor),
            ),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: Text(AppStrings.download),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surfaceLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusMd),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await DiService.fileActionService.download(entry.path, entry.name);
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppStrings.downloadSuccess),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppStrings.downloadFailed),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
