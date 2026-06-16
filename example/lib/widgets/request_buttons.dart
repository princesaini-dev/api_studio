import 'package:flutter/material.dart';
import '../constants/app_strings.dart';

class RequestButtons extends StatelessWidget {
  final VoidCallback onGet;
  final VoidCallback onPost;
  final VoidCallback onFail;

  const RequestButtons({
    super.key,
    required this.onGet,
    required this.onPost,
    required this.onFail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          icon: const Icon(Icons.download_rounded),
          label: const Text(AppStrings.labelGet),
          onPressed: onGet,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          icon: const Icon(Icons.upload_rounded),
          label: const Text(AppStrings.labelPost),
          onPressed: onPost,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.error_outline_rounded),
          label: const Text(AppStrings.labelTrigger404),
          onPressed: onFail,
        ),
      ],
    );
  }
}
