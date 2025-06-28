import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/ai_repository.dart';

class AnalyzeNotes {
  final AIRepository repository;

  AnalyzeNotes(this.repository);

  Future<Either<Failure, AIAnalysis>> call(AnalyzeNotesParams params) async {
    return await repository.analyzeNotes(params.noteIds, params.notesContent);
  }
}

class AnalyzeNotesParams {
  final List<String> noteIds;
  final String notesContent;

  AnalyzeNotesParams(this.noteIds, this.notesContent);
}

class AIAnalysis {
  final String summary;
  final List<String> keywords;
  final List<String> suggestions;

  AIAnalysis({
    required this.summary,
    required this.keywords,
    required this.suggestions,
  });
}