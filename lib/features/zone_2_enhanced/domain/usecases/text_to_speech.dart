import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/ai_repository.dart';

class TextToSpeech {
  final AIRepository repository;

  TextToSpeech(this.repository);

  Future<Either<Failure, String>> call(TextToSpeechParams params) async {
    return await repository.generateSpeech(params.text);
  }
}

class TextToSpeechParams {
  final String text;

  TextToSpeechParams(this.text);
}