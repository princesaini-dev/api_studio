import 'package:equatable/equatable.dart';

abstract class UseCase<T, Params> {
  Future<T> call(Params params);
}

class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
