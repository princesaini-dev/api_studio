import '../entities/file_explorer_entry.dart';
import '../repositories/file_explorer_repository.dart';
import '../../core/usecases/usecase.dart';

class ListDirectoryUseCase implements UseCase<List<FileExplorerEntry>, String> {
  final FileExplorerRepository repository;

  const ListDirectoryUseCase(this.repository);

  @override
  Future<List<FileExplorerEntry>> call(String path) {
    return repository.listDirectory(path);
  }
}
