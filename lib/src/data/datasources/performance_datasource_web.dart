import 'performance_datasource.dart';

class PerformanceDataSourceImpl implements PerformanceDataSource {
  @override
  int? getCurrentMemoryUsageBytes() => null;

  @override
  bool get isMemoryAvailable => false;
}
