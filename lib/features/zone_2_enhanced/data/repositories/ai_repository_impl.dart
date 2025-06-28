import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/usecases/analyze_notes.dart';
import '../datasources/ai_api_datasource.dart';

class AIRepositoryImpl implements AIRepository {
  final AIApiDataSource apiDataSource;
  final NetworkInfo networkInfo;

  AIRepositoryImpl({
    required this.apiDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, AIAnalysis>> analyzeNotes(List<String> noteIds, String notesContent) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final analysis = await apiDataSource.analyzeNotes(noteIds, notesContent);
      return Right(analysis);
    } on AIServiceException catch (e) {
      return Left(AIServiceFailure(e.message));
    } catch (e) {
      return Left(AIServiceFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> generateSpeech(String text) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final audioPath = await apiDataSource.generateSpeech(text);
      return Right(audioPath);
    } on AIServiceException catch (e) {
      return Left(AIServiceFailure(e.message));
    } catch (e) {
      return Left(AIServiceFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> generateTags(String content) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final tags = await apiDataSource.generateTags(content);
      return Right(tags);
    } on AIServiceException catch (e) {
      return Left(AIServiceFailure(e.message));
    } catch (e) {
      return Left(AIServiceFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> chatWithAI(String message, List<Map<String, String>> conversationHistory) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final response = await apiDataSource.chatWithAI(message, conversationHistory);
      return Right(response);
    } on AIServiceException catch (e) {
      return Left(AIServiceFailure(e.message));
    } catch (e) {
      return Left(AIServiceFailure('Unexpected error: ${e.toString()}'));
    }
  }
}