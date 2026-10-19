import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/api_inspector_theme.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/dimensions.dart';

class SearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String hintText;
  final TextEditingController? controller;

  const SearchBarWidget({
    super.key,
    required this.onChanged,
    this.hintText = 'Search by URL or endpoint…',
    this.controller,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late final TextEditingController _controller;
  bool _hasText = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(() {
      final has = _controller.text.isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  void _onChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      widget.onChanged(text);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ApiInspectorTheme.of(context);
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      style: AppTextStyles.bodyMedium.copyWith(color: theme.textPrimaryColor),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle:
            AppTextStyles.bodyMedium.copyWith(color: theme.textSecondaryColor),
        prefixIcon: Icon(Icons.search_rounded,
            color: theme.textSecondaryColor, size: 20),
        suffixIcon: _hasText
            ? IconButton(
                icon: Icon(Icons.close_rounded,
                    color: theme.textSecondaryColor, size: 18),
                onPressed: () {
                  _debounceTimer?.cancel();
                  _controller.clear();
                  widget.onChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: theme.surfaceColor,
        isDense: false,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusMd),
          borderSide: BorderSide(color: theme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusMd),
          borderSide: BorderSide(color: theme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusMd),
          borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
        ),
      ),
    );
  }
}
