import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/date_utils.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class UpdateNote {
  final NoteRepository repository;

  UpdateNote(this.repository);

  Future<Either<Failure, Note>> call(UpdateNoteParams params) async {
    final updatedNote = params.note.copyWith(
      updatedAt: AppDateUtils.toIsoString(DateTime.now()),
      syncStatus: 'pending', // Mark as pending sync after update
    );

    return await repository.updateNote(updatedNote);
  }
}

class UpdateNoteParams {
  final Note note;

  UpdateNoteParams(this.note);
}