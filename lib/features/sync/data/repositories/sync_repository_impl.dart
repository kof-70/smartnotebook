import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/sync_repository.dart';
import '../datasources/sync_datasource.dart';

class SyncRepositoryImpl implements SyncRepository {
  final SyncDataSource syncDataSource;
  final NetworkInfo networkInfo;

  SyncRepositoryImpl({
    required this.syncDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, bool>> syncData() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final result = await syncDataSource.syncData();
      return Right(result);
    } on SyncException catch (e) {
      return Left(SyncFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, DateTime?>> getLastSyncTime() async {
    try {
      final lastSync = await syncDataSource.getLastSyncTime();
      return Right(lastSync);
    } on SyncException catch (e) {
      return Left(SyncFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> hasUnsyncedChanges() async {
    try {
      final hasChanges = await syncDataSource.hasUnsyncedChanges();
      return Right(hasChanges);
    } on SyncException catch (e) {
      return Left(SyncFailure(e.message));
    }
  }
}