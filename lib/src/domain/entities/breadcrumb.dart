import 'package:equatable/equatable.dart';

class Breadcrumb extends Equatable {
  final String label;
  final String path;
  final bool isCurrent;

  const Breadcrumb({
    required this.label,
    required this.path,
    required this.isCurrent,
  });

  static List<Breadcrumb> fromPath(String currentPath, String rootLabel) {
    final crumbs = <Breadcrumb>[];

    crumbs.add(Breadcrumb(
      label: rootLabel,
      path: '',
      isCurrent: currentPath.isEmpty,
    ));

    if (currentPath.isEmpty) return crumbs;

    final parts = currentPath.split('/');
    for (int i = 0; i < parts.length; i++) {
      final isLast = i == parts.length - 1;
      crumbs.add(Breadcrumb(
        label: parts[i],
        path: parts.sublist(0, i + 1).join('/'),
        isCurrent: isLast,
      ));
    }

    return crumbs;
  }

  @override
  List<Object?> get props => [label, path, isCurrent];
}
