import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/ai_repository.dart';

class ChatWithAI {
  final AIRepository repository;

  ChatWithAI(this.repository);

  Future<Either<Failure, String>> call(ChatWithAIParams params) async {
    return await repository.chatWithAI(params.message, params.conversationHistory);
  }
}

class ChatWithAIParams {
  final String message;
  final List<Map<String, String>> conversationHistory;

  ChatWithAIParams({
    required this.message,
    this.conversationHistory = const [],
  });
}