import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../shared/data/models/profile_model.dart';
import '../datasources/auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource authDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.authDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, ProfileModel>> signInWithGoogle() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final profile = await authDataSource.signInWithGoogle();
      if (profile != null) {
        return Right(profile);
      } else {
        return const Left(AuthenticationFailure('Google sign in cancelled'));
      }
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(AuthenticationFailure('Failed to sign in with Google: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ProfileModel>> signInWithApple() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final profile = await authDataSource.signInWithApple();
      if (profile != null) {
        return Right(profile);
      } else {
        return const Left(AuthenticationFailure('Apple sign in cancelled'));
      }
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(AuthenticationFailure('Failed to sign in with Apple: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await authDataSource.signOut();
      return const Right(null);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(AuthenticationFailure('Failed to sign out: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ProfileModel?>> getCurrentUser() async {
    try {
      final profile = await authDataSource.getCurrentUser();
      return Right(profile);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(AuthenticationFailure('Failed to get current user: ${e.toString()}'));
    }
  }

  @override
  Stream<AuthState> get authStateChanges => authDataSource.authStateChanges;
}