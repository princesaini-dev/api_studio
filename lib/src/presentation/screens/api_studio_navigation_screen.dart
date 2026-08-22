import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../theme/api_inspector_theme.dart';
import '../../theme/api_inspector_theme_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/dimensions.dart';
import 'file_explorer_screen.dart';
import 'inspector_list_screen.dart';
import 'performance_inspector_screen.dart';

/// Unified API Studio container screen.
///
/// Hosts the existing [InspectorListScreen] (API Logs), [PerformanceInspectorScreen]
/// and [FileExplorerScreen] behind a single floating bottom navigation bar,
/// so that host applications only need a single entry point —
/// `ApiStudio.showNavigation(context)` — instead of pushing each feature
/// screen separately.
///
/// The three feature screens are kept alive via [IndexedStack] so switching
/// tabs never rebuilds or reinitializes their blocs/state.
class ApiStudioNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const ApiStudioNavigationScreen({super.key, this.initialIndex = 0});

  static Route<void> route({int initialIndex = 0}) {
    return PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) =>
          ApiStudioNavigationScreen(initialIndex: initialIndex),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  @override
  State<ApiStudioNavigationScreen> createState() =>
      _ApiStudioNavigationScreenState();
}

class _ApiStudioNavigationScreenState extends State<ApiStudioNavigationScreen> {
  late int _selectedIndex = widget.initialIndex;

  // Each feature screen is created once and kept alive by IndexedStack —
  // opening the navigation never rebuilds or re-fetches a tab the user
  // hasn't visited yet (lazy bloc creation happens inside each screen).
  static const List<Widget> _screens = [
    RepaintBoundary(child: InspectorListScreen()),
    RepaintBoundary(child: PerformanceInspectorScreen()),
    RepaintBoundary(child: FileExplorerScreen()),
  ];

  void _onTabSelected(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ApiInspectorTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: RepaintBoundary(
        child: _FloatingBottomNav(
          theme: theme,
          selectedIndex: _selectedIndex,
          onTabSelected: _onTabSelected,
        ),
      ),
    );
  }
}

class _NavTab {
  final IconData icon;
  final String label;

  const _NavTab({required this.icon, required this.label});
}

const List<_NavTab> _kNavTabs = [
  _NavTab(icon: Icons.radar_rounded, label: AppStrings.navLogs),
  _NavTab(icon: Icons.speed_rounded, label: AppStrings.navPerformance),
  _NavTab(icon: Icons.folder_rounded, label: AppStrings.navFiles),
];

/// A floating, rounded bottom navigation bar.
///
/// Only the selection indicator/icon/label animate on tab change (subtle,
/// fast, GPU-cheap) — the bar container itself never moves, and the active
/// feature screen swaps instantly via [IndexedStack] with no expensive
/// content transition.
class _FloatingBottomNav extends StatelessWidget {
  final ApiInspectorThemeData theme;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _FloatingBottomNav({
    required this.theme,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  double _indicatorAlignmentX(int index, int count) {
    if (count <= 1) return 0;
    return -1 + (2 * index) / (count - 1);
  }

  @override
  Widget build(BuildContext context) {
    final shadowColor = theme.primaryColor.withValues(alpha: 0.8);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.xl),
        child: Material(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusFull),
          ),
          color: Colors.transparent,
          child: Container(
            height: Dimensions.tabBarHeight,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusFull),
              border: Border.all(color: theme.borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / _kNavTabs.length;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment(
                        _indicatorAlignmentX(selectedIndex, _kNavTabs.length),
                        0,
                      ),
                      child: Container(
                        width: itemWidth,
                        height: double.infinity,
                        padding: const EdgeInsets.all(4),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(Dimensions.radiusFull),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(_kNavTabs.length, (index) {
                        final tab = _kNavTabs[index];
                        final selected = index == selectedIndex;
                        final color = selected
                            ? theme.primaryColor
                            : theme.textSecondaryColor;
                        return Expanded(
                          child: InkWell(
                            borderRadius:
                                BorderRadius.circular(Dimensions.radiusFull),
                            onTap: () => onTabSelected(index),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedScale(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  scale: selected ? 1.0 : 0.9,
                                  child: Icon(
                                    tab.icon,
                                    size: Dimensions.iconMd,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: color,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                  child: Text(tab.label),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
