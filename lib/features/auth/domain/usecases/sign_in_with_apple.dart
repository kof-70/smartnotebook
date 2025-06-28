import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/data/models/profile_model.dart';
import '../repositories/auth_repository.dart';

class SignInWithApple {
  final AuthRepository repository;

  SignInWithApple(this.repository);

  Future<Either<Failure, ProfileModel>> call() async {
    return await repository.signInWithApple();
  }
}