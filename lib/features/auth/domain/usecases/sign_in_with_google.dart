import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/data/models/profile_model.dart';
import '../repositories/auth_repository.dart';

class SignInWithGoogle {
  final AuthRepository repository;

  SignInWithGoogle(this.repository);

  Future<Either<Failure, ProfileModel>> call() async {
    return await repository.signInWithGoogle();
  }
}