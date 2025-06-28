import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/sync_repository.dart';

class SyncData {
  final SyncRepository repository;

  SyncData(this.repository);

  Future<Either<Failure, bool>> call(SyncDataParams params) async {
    return await repository.syncData();
  }
}

class SyncDataParams {
  const SyncDataParams();
}