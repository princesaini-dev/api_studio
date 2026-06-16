import '../entities/api_log_entity.dart';

enum SortOrder { newest, oldest, duration, statusCode }

enum MethodFilter { all, get, post, put, patch, delete }

enum StatusFilter { all, success, error }

class GetLogsParams {
  final int page;
  final int pageSize;
  final String? searchQuery;
  final MethodFilter methodFilter;
  final StatusFilter statusFilter;
  final SortOrder sortOrder;

  const GetLogsParams({
    this.page = 0,
    this.pageSize = 20,
    this.searchQuery,
    this.methodFilter = MethodFilter.all,
    this.statusFilter = StatusFilter.all,
    this.sortOrder = SortOrder.newest,
  });
}

abstract class ApiLogRepository {
  Future<List<ApiLogEntity>> getLogs(GetLogsParams params);
  Future<ApiLogEntity?> getLogById(String id);
  Future<void> saveLog(ApiLogEntity log);
  Future<void> updateLog(ApiLogEntity log);
  Future<void> deleteLog(String id);
  Future<void> clearAllLogs();
  Future<int> getTotalCount();
  Stream<List<ApiLogEntity>> watchLogs();
}
