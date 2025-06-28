import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class GetNotes {
  final NoteRepository repository;

  GetNotes(this.repository);

  Future<Either<Failure, List<Note>>> call(GetNotesParams params) async {
    return await repository.getNotes();
  }
}

class GetNotesParams {
  const GetNotesParams();
}