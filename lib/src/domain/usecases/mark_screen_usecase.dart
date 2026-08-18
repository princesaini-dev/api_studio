import '../repositories/performance_repository.dart';

class MarkScreenStartUseCase {
  final PerformanceRepository repository;

  const MarkScreenStartUseCase(this.repository);

  void call(String name) => repository.markScreenStart(name);
}

class MarkScreenEndUseCase {
  final PerformanceRepository repository;

  const MarkScreenEndUseCase(this.repository);

  void call(String name) => repository.markScreenEnd(name);
}
