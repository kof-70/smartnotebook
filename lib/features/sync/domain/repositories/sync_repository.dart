import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';

abstract class SyncRepository {
  Future<Either<Failure, bool>> syncData();
  Future<Either<Failure, DateTime?>> getLastSyncTime();
  Future<Either<Failure, bool>> hasUnsyncedChanges();
}