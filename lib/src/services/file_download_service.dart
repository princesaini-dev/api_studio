/// Default stub – throws on unsupported platforms.
class FileDownloadService {
  Future<String> download(String sourcePath, String fileName) {
    throw UnsupportedError('Download not supported on this platform');
  }
}
