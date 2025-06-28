import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/ai_repository.dart';

class GenerateTags {
  final AIRepository repository;

  GenerateTags(this.repository);

  Future<Either<Failure, List<String>>> call(GenerateTagsParams params) async {
    return await repository.generateTags(params.content);
  }
}

class GenerateTagsParams {
  final String content;

  GenerateTagsParams(this.content);
}