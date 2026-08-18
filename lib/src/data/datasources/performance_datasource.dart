import 'performance_datasource_io.dart'
    if (dart.library.html) 'performance_datasource_web.dart';

abstract class PerformanceDataSource {
  int? getCurrentMemoryUsageBytes();
  bool get isMemoryAvailable;
}

PerformanceDataSource createPerformanceDataSource() {
  return PerformanceDataSourceImpl();
}
