import '../domain/repositories/file_explorer_repository.dart';
import 'file_download_service.dart'
    if (dart.library.io) 'file_download_service_io.dart'
    if (dart.library.js_interop) 'file_download_service_web.dart';

class FileActionService {
  final FileExplorerRepository _repository;
  final FileDownloadService _downloadService;

  FileActionService(this._repository, this._downloadService);

  Future<String> getFilePath(String relativePath) {
    return _repository.getFilePath(relativePath);
  }

  Future<String> download(String relativePath, String fileName) async {
    final sourcePath = await _repository.getFilePath(relativePath);
    return _downloadService.download(sourcePath, fileName);
  }
}
