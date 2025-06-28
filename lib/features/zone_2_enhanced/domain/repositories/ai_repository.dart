import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../usecases/analyze_notes.dart';

abstract class AIRepository {
  Future<Either<Failure, AIAnalysis>> analyzeNotes(List<String> noteIds, String notesContent);
  Future<Either<Failure, String>> generateSpeech(String text);
  Future<Either<Failure, List<String>>> generateTags(String content);
  Future<Either<Failure, String>> chatWithAI(String message, List<Map<String, String>> conversationHistory);
}