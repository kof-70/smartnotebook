import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/data/models/profile_model.dart';

abstract class AuthRepository {
  Future<Either<Failure, ProfileModel>> signInWithGoogle();
  Future<Either<Failure, ProfileModel>> signInWithApple();
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, ProfileModel?>> getCurrentUser();
  Stream<AuthState> get authStateChanges;
}