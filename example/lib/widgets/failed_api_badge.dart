import 'package:flutter/material.dart';
import '../constants/app_strings.dart';

class FailedApiBadge extends StatelessWidget {
  final int count;

  const FailedApiBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: count > 0 ? Colors.red : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            '${AppStrings.failedApis}: $count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: count > 0 ? Colors.red : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
