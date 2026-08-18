import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../theme/api_inspector_theme_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/dimensions.dart';

class PerformanceGraph extends StatelessWidget {
  final List<double> dataPoints;
  final double maxValue;
  final double warningThreshold;
  final double criticalThreshold;
  final String unit;
  final ApiInspectorThemeData theme;
  final String label;

  const PerformanceGraph({
    super.key,
    required this.dataPoints,
    required this.maxValue,
    required this.warningThreshold,
    required this.criticalThreshold,
    required this.unit,
    required this.theme,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border.all(color: theme.borderColor, width: 0.8),
          borderRadius: BorderRadius.circular(theme.borderRadius),
        ),
        padding: const EdgeInsets.all(Dimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.labelMedium
                  .copyWith(color: theme.textSecondaryColor),
            ),
            const SizedBox(height: Dimensions.sm),
            SizedBox(
              height: Dimensions.performanceGraphHeight,
              child: dataPoints.isEmpty
                  ? Center(
                      child: Text(
                        AppStrings.waitingForData,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: theme.textSecondaryColor),
                      ),
                    )
                  : CustomPaint(
                      size: Size.infinite,
                      painter: _GraphPainter(
                        dataPoints: dataPoints,
                        maxValue: maxValue,
                        warningThreshold: warningThreshold,
                        criticalThreshold: criticalThreshold,
                        lineColor: AppColors.primary,
                        warningColor: AppColors.warning,
                        criticalColor: AppColors.error,
                        gridColor: theme.borderColor,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final List<double> dataPoints;
  final double maxValue;
  final double warningThreshold;
  final double criticalThreshold;
  final Color lineColor;
  final Color warningColor;
  final Color criticalColor;
  final Color gridColor;

  _GraphPainter({
    required this.dataPoints,
    required this.maxValue,
    required this.warningThreshold,
    required this.criticalThreshold,
    required this.lineColor,
    required this.warningColor,
    required this.criticalColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final w = size.width;
    final h = size.height;
    final stepX = w / (dataPoints.length - 1).clamp(1, dataPoints.length - 1);

    // Grid lines
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = (h / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Threshold lines
    final warningY = h - (warningThreshold / maxValue).clamp(0.0, 1.0) * h;
    final criticalY = h - (criticalThreshold / maxValue).clamp(0.0, 1.0) * h;

    canvas.drawLine(
      Offset(0, warningY),
      Offset(w, warningY),
      Paint()
        ..color = warningColor.withValues(alpha: 0.3)
        ..strokeWidth = 0.8,
    );
    canvas.drawLine(
      Offset(0, criticalY),
      Offset(w, criticalY),
      Paint()
        ..color = criticalColor.withValues(alpha: 0.3)
        ..strokeWidth = 0.8,
    );

    // Line path
    final path = Path();
    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * stepX;
      final yVal = (dataPoints[i] / maxValue).clamp(0.0, 1.0);
      final y = h - yVal * h;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Fill area under curve
    final fillPath = Path.from(path);
    fillPath.lineTo(w, h);
    fillPath.lineTo(0, h);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.15),
            lineColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Draw line
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );

    // Draw last point
    if (dataPoints.isNotEmpty) {
      final lastX = (dataPoints.length - 1) * stepX;
      final lastYVal = (dataPoints.last / maxValue).clamp(0.0, 1.0);
      final lastY = h - lastYVal * h;
      canvas.drawCircle(
        Offset(lastX, lastY),
        3,
        Paint()..color = lineColor,
      );
    }
  }

  @override
  bool shouldRepaint(_GraphPainter oldDelegate) =>
      dataPoints != oldDelegate.dataPoints || maxValue != oldDelegate.maxValue;
}
