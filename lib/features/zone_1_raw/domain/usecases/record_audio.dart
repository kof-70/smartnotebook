import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/services/audio_service.dart';
import '../repositories/note_repository.dart';

class RecordAudio {
  final AudioService audioService;
  final NoteRepository noteRepository;

  RecordAudio(this.audioService, this.noteRepository);

  Future<Either<Failure, String>> startRecording() async {
    try {
      final recordingPath = await audioService.startRecording();
      if (recordingPath != null) {
        return Right(recordingPath);
      } else {
        return const Left(FileSystemFailure('Failed to start recording'));
      }
    } catch (e) {
      return Left(FileSystemFailure(e.toString()));
    }
  }

  Future<Either<Failure, String>> stopRecording() async {
    try {
      final recordingPath = await audioService.stopRecording();
      if (recordingPath != null) {
        return Right(recordingPath);
      } else {
        return const Left(FileSystemFailure('Failed to stop recording'));
      }
    } catch (e) {
      return Left(FileSystemFailure(e.toString()));
    }
  }
}