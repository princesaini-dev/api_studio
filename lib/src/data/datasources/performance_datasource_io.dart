import 'dart:io';

import 'performance_datasource.dart';

class PerformanceDataSourceImpl implements PerformanceDataSource {
  @override
  int? getCurrentMemoryUsageBytes() {
    try {
      return ProcessInfo.currentRss;
    } catch (_) {
      return null;
    }
  }

  @override
  bool get isMemoryAvailable => true;
}
