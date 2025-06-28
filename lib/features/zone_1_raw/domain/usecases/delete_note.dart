import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/note_repository.dart';

class DeleteNote {
  final NoteRepository repository;

  DeleteNote(this.repository);

  Future<Either<Failure, void>> call(DeleteNoteParams params) async {
    return await repository.deleteNote(params.noteId);
  }
}

class DeleteNoteParams {
  final String noteId;

  DeleteNoteParams(this.noteId);
}