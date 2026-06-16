import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class NetworkFailure extends Failure {
  final int? statusCode;
  const NetworkFailure(super.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}
