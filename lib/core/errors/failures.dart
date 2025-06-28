import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;
  
  const Failure(this.message, [this.code]);
  
  @override
  List<Object?> get props => [message, code];
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, [super.code]);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.code]);
}

class FileSystemFailure extends Failure {
  const FileSystemFailure(super.message, [super.code]);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message, [super.code]);
}

class EncryptionFailure extends Failure {
  const EncryptionFailure(super.message, [super.code]);
}

class AIServiceFailure extends Failure {
  const AIServiceFailure(super.message, [super.code]);
}

class SyncFailure extends Failure {
  const SyncFailure(super.message, [super.code]);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message, [super.code]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.code]);
}