import '../api_client/client/api_studio_client.dart';
import '../api_client/core/inspector_logger.dart';
import '../core/constants/app_constants.dart';
import '../core/pipeline/log_pipeline.dart';
import '../data/datasources/file_explorer_datasource.dart'
    if (dart.library.io) '../data/datasources/file_explorer_datasource_io.dart'
    if (dart.library.js_interop) '../data/datasources/file_explorer_datasource_web.dart';
import '../data/datasources/hive_datasource.dart';
import '../data/datasources/hive_storage.dart';
import '../data/repositories/api_log_repository_impl.dart';
import '../data/repositories/file_explorer_repository_impl.dart';
import '../data/repositories/performance_repository_impl.dart';
import '../domain/repositories/api_log_repository.dart';
import '../domain/repositories/file_explorer_repository.dart';
import '../domain/repositories/performance_repository.dart';
import '../domain/usecases/clear_logs_usecase.dart';
import '../domain/usecases/delete_log_usecase.dart';
import '../domain/usecases/get_logs_usecase.dart';
import '../domain/usecases/list_directory_usecase.dart';
import '../domain/usecases/run_request_usecase.dart';
import '../domain/usecases/save_log_usecase.dart';
import '../notification/config/notification_config.dart';
import '../notification/services/notification_service.dart';
import '../presentation/controllers/edit_run_controller.dart';
import '../presentation/controllers/export_controller.dart';
import '../presentation/controllers/file_explorer_controller.dart';
import '../presentation/controllers/inspector_detail_controller.dart';
import '../presentation/controllers/inspector_list_controller.dart';
import '../presentation/controllers/performance_controller.dart';
import '../services/file_action_service.dart';
import '../services/file_download_service.dart'
    if (dart.library.io) '../services/file_download_service_io.dart'
    if (dart.library.js_interop) '../services/file_download_service_web.dart';
import 'connectivity_checker_native.dart'
    if (dart.library.js_interop) 'connectivity_checker_web.dart';
import 'connectivity_service.dart';
import 'export_service.dart';
import 'failed_api_count_service.dart';
import 'performance_monitor.dart';

class DiService {
  DiService._();

  static late ApiLogRepository _repository;
  static late FileExplorerRepository _fileExplorerRepository;
  static late PerformanceRepository _performanceRepository;
  static late FileActionService _fileActionService;
  static NotificationService? _notificationService;
  static bool _initialized = false;
  static int _maxStoredLogs = AppConstants.maxStoredLogs;
  static Duration _logRetention = AppConstants.logRetention;
  static Duration _requestTimeout = AppConstants.requestTimeout;

  /// Whether local storage and controllers have been initialized.
  static bool get isInitialized => _initialized;

  static int get maxStoredLogs => _maxStoredLogs;
  static Duration get logRetention => _logRetention;
  static Duration get requestTimeout => _requestTimeout;
  static NotificationService? get notificationService => _notificationService;

  static Future<void> init({
    int? maxStoredLogs,
    Duration? logRetention,
    Duration? requestTimeout,
    bool enableConnectivityStream = false,
    bool enableFailedApiStream = false,
    NotificationConfig? notificationConfig,
    bool enableApiClient = true,
  }) async {
    if (_initialized) return;
    if (maxStoredLogs != null) _maxStoredLogs = maxStoredLogs;
    if (logRetention != null) _logRetention = logRetention;
    if (requestTimeout != null) _requestTimeout = requestTimeout;

    // Initialize notification service if configured
    if (notificationConfig != null && notificationConfig.hasAnyNotification) {
      _notificationService = NotificationService(config: notificationConfig);
      await _notificationService!.initialize();
    }

    ApiStudioHive.registerAdapters();
    final box = await HiveApiLogDataSource.openBox();
    final dataSource = HiveApiLogDataSource(
      box,
      maxStoredLogs: _maxStoredLogs,
      retention: _logRetention,
    );
    await dataSource.prune();
    _repository = ApiLogRepositoryImpl(dataSource);
    LogPipeline.repository = _repository;
    LogPipeline.notificationService = _notificationService;
    _fileExplorerRepository =
        FileExplorerRepositoryImpl(FileExplorerDataSource());
    _fileActionService =
        FileActionService(_fileExplorerRepository, FileDownloadService());
    _performanceRepository =
        PerformanceRepositoryImpl(PerformanceMonitor.instance);
    _initialized = true;
    if (enableConnectivityStream) ConnectivityService.instance.start();
    if (enableFailedApiStream) {
      FailedApiCountService.instance.start(_repository);
    }

    // Wire ApiStudioClient logger so every client request appears in
    // Inspector. Skipped entirely when the API Client is disabled, avoiding
    // unnecessary object creation for a feature the host app opted out of.
    if (enableApiClient) {
      final logger = InspectorLogger(
        repository: _repository,
        maxStoredLogs: _maxStoredLogs,
        notificationService: _notificationService,
      );
      ApiStudioClient.attachLogger(logger);
    }
  }

  static bool get isConnected => ConnectivityService.instance.isConnected;

  static Stream<bool> get internetConnectivityStream =>
      ConnectivityService.instance.stream;

  static int get failedApiCount =>
      FailedApiCountService.instance.failedApiCount;

  static Stream<int> get failedApiCountStream =>
      FailedApiCountService.instance.stream;

  static Future<bool> get isInternetAvailable => checkConnectivity();

  static ApiLogRepository get repository {
    assert(_initialized, 'DiService.init() must be called before use');
    return _repository;
  }

  static InspectorListController createListController() =>
      InspectorListController(
        getLogsUseCase: GetLogsUseCase(_repository),
        deleteLogUseCase: DeleteLogUseCase(_repository),
        clearLogsUseCase: ClearLogsUseCase(_repository),
        repository: _repository,
      );

  static InspectorDetailController createDetailController() =>
      InspectorDetailController(
        repository: _repository,
        deleteLogUseCase: DeleteLogUseCase(_repository),
      );

  static EditRunController createEditRunController() => EditRunController(
        runRequestUseCase: RunRequestUseCase(_repository),
      );

  static ExportController createExportController() => ExportController(
        exportService: ExportService(repository: _repository),
      );

  static SaveLogUseCase get saveLogUseCase => SaveLogUseCase(_repository);

  static FileExplorerController createFileExplorerController() =>
      FileExplorerController(
        listDirectoryUseCase: ListDirectoryUseCase(_fileExplorerRepository),
      );

  static FileActionService get fileActionService {
    assert(_initialized, 'DiService.init() must be called before use');
    return _fileActionService;
  }

  static PerformanceRepository get performanceRepository {
    assert(_initialized, 'DiService.init() must be called before use');
    return _performanceRepository;
  }

  static PerformanceController createPerformanceController() =>
      PerformanceController(repository: _performanceRepository);
}
