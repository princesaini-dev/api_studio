import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../theme/dimensions.dart';

class FileExplorerLoadingState extends StatelessWidget {
  const FileExplorerLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(strokeWidth: 2),
          SizedBox(height: Dimensions.lg),
          Text(AppStrings.loading),
        ],
      ),
    );
  }
}
