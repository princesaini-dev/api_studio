import '../../core/usecases/usecase.dart';
import '../entities/file_explorer_entry.dart';
import '../repositories/file_explorer_repository.dart';

class ListDirectoryUseCase implements UseCase<List<FileExplorerEntry>, String> {
  final FileExplorerRepository repository;

  const ListDirectoryUseCase(this.repository);

  @override
  Future<List<FileExplorerEntry>> call(String path) {
    return repository.listDirectory(path);
  }
}
