import 'package:flutter/material.dart';

import '../../domain/entities/breadcrumb.dart';
import '../../theme/api_inspector_theme.dart';
import '../../theme/api_inspector_theme_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/dimensions.dart';

class BreadcrumbBar extends StatelessWidget {
  final List<Breadcrumb> breadcrumbs;
  final ValueChanged<String> onNavigate;

  const BreadcrumbBar({
    super.key,
    required this.breadcrumbs,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ApiInspectorTheme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.lg,
        vertical: Dimensions.sm,
      ),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        border: Border(
          bottom: BorderSide(color: theme.borderColor, width: 0.8),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _buildSegments(theme),
        ),
      ),
    );
  }

  List<Widget> _buildSegments(ApiInspectorThemeData theme) {
    final segments = <Widget>[];

    for (int i = 0; i < breadcrumbs.length; i++) {
      if (i > 0) {
        segments.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            Icons.chevron_right_rounded,
            size: 16,
          ),
        ));
      }

      final crumb = breadcrumbs[i];
      segments.add(BreadcrumbItem(
        breadcrumb: crumb,
        theme: theme,
        onTap: crumb.isCurrent ? null : () => onNavigate(crumb.path),
      ));
    }

    return segments;
  }
}

class BreadcrumbItem extends StatelessWidget {
  final Breadcrumb breadcrumb;
  final ApiInspectorThemeData theme;
  final VoidCallback? onTap;

  const BreadcrumbItem({
    super.key,
    required this.breadcrumb,
    required this.theme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = breadcrumb.isCurrent
        ? theme.textPrimaryColor
        : theme.textSecondaryColor;

    if (onTap == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Text(
          breadcrumb.label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusSm),
        hoverColor: AppColors.primary.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            breadcrumb.label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
