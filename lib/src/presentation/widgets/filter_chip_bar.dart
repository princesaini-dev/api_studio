import 'package:flutter/material.dart';
import '../../domain/repositories/api_log_repository.dart';
import '../../theme/api_inspector_theme.dart';
import '../../theme/app_text_styles.dart';

class FilterChipBar extends StatelessWidget {
  final MethodFilter selectedMethod;
  final StatusFilter selectedStatus;
  final SortOrder selectedSort;
  final ValueChanged<MethodFilter> onMethodChanged;
  final ValueChanged<StatusFilter> onStatusChanged;
  final ValueChanged<SortOrder> onSortChanged;

  const FilterChipBar({
    super.key,
    required this.selectedMethod,
    required this.selectedStatus,
    required this.selectedSort,
    required this.onMethodChanged,
    required this.onStatusChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ApiInspectorTheme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildDropdown<MethodFilter>(
            context,
            theme,
            label: 'Method',
            value: selectedMethod,
            items: MethodFilter.values,
            labelFor: (v) => v == MethodFilter.all ? 'All Methods' : v.name.toUpperCase(),
            onChanged: onMethodChanged,
          ),
          const SizedBox(width: 8),
          _buildDropdown<StatusFilter>(
            context,
            theme,
            label: 'Status',
            value: selectedStatus,
            items: StatusFilter.values,
            labelFor: (v) => switch (v) {
              StatusFilter.all => 'All Status',
              StatusFilter.success => 'Success',
              StatusFilter.error => 'Error',
            },
            onChanged: onStatusChanged,
          ),
          const SizedBox(width: 8),
          _buildDropdown<SortOrder>(
            context,
            theme,
            label: 'Sort',
            value: selectedSort,
            items: SortOrder.values,
            labelFor: (v) => switch (v) {
              SortOrder.newest => 'Newest',
              SortOrder.oldest => 'Oldest',
              SortOrder.duration => 'Duration',
              SortOrder.statusCode => 'Status Code',
            },
            onChanged: onSortChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>(
    BuildContext context,
    dynamic theme, {
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) labelFor,
    required ValueChanged<T> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.borderColor),
      ),
      child: DropdownButton<T>(
        value: value,
        isDense: true,
        underline: const SizedBox(),
        style: AppTextStyles.labelMedium.copyWith(color: theme.textPrimaryColor),
        dropdownColor: theme.cardColor,
        items: items
            .map((v) => DropdownMenuItem<T>(
                  value: v,
                  child: Text(labelFor(v)),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
