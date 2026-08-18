import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/file_type_helper.dart';
import '../../../domain/entities/file_explorer_entry.dart';
import '../../../theme/api_inspector_theme_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/dimensions.dart';

class FileExplorerItem extends StatelessWidget {
  final FileExplorerEntry entry;
  final ApiInspectorThemeData theme;
  final VoidCallback onTap;
  final VoidCallback? onOpen;
  final VoidCallback? onDownload;

  const FileExplorerItem({
    super.key,
    required this.entry,
    required this.theme,
    required this.onTap,
    this.onOpen,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.borderRadius),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.borderColor, width: 0.8),
            borderRadius: BorderRadius.circular(theme.borderRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.md,
            vertical: Dimensions.sm + 2,
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(theme.borderRadius),
                  child: Row(
                    children: [
                      _EntryIcon(entry: entry, theme: theme),
                      const SizedBox(width: Dimensions.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              entry.name,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: theme.textPrimaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_subtitle().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                _subtitle(),
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: theme.textSecondaryColor),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (entry.isFile) ...[
                if (onDownload != null)
                  IconButton(
                    icon: Icon(Icons.download_outlined,
                        size: Dimensions.iconSm,
                        color: theme.textSecondaryColor),
                    tooltip: AppStrings.download,
                    onPressed: onDownload,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
              ],
              if (entry.isFolder)
                Icon(
                  Icons.chevron_right_rounded,
                  size: Dimensions.iconSm,
                  color: theme.textSecondaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle() {
    if (entry.isFolder) {
      return AppStrings.itemCount(entry.childCount ?? 0);
    }
    if (entry.sizeBytes != null) {
      return AppStrings.formatBytes(entry.sizeBytes);
    }
    return '';
  }
}

class _EntryIcon extends StatelessWidget {
  final FileExplorerEntry entry;
  final ApiInspectorThemeData theme;

  const _EntryIcon({required this.entry, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (entry.isFolder) {
      return const Icon(
        Icons.folder_rounded,
        size: Dimensions.iconLg,
        color: AppColors.primary,
      );
    }

    return Icon(
      FileTypeHelper.iconForExtension(entry.extension),
      size: Dimensions.iconLg,
      color: FileTypeHelper.colorForExtension(
          entry.extension, theme.textSecondaryColor),
    );
  }
}
