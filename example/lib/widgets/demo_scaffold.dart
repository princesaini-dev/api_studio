import 'package:flutter/material.dart';

/// Shared scaffold used by every demo screen.
class DemoScaffold extends StatelessWidget {
  final String title;
  final String description;
  final Widget body;

  const DemoScaffold({
    super.key,
    required this.title,
    required this.description,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// A result card displayed after a request.
class ResultCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isError;

  const ResultCard({
    super.key,
    required this.label,
    required this.value,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? Theme.of(context).colorScheme.errorContainer
        : Theme.of(context).colorScheme.primaryContainer;
    final textColor = isError
        ? Theme.of(context).colorScheme.onErrorContainer
        : Theme.of(context).colorScheme.onPrimaryContainer;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: textColor, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(color: textColor, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}

/// Primary action button used in demo screens.
class DemoButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const DemoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FilledButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.play_arrow_rounded),
        label: Text(label),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
        ),
      ),
    );
  }
}
