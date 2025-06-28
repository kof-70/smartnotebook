import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/note.dart';

abstract class NoteRepository {
  Future<Either<Failure, List<Note>>> getNotes();
  Future<Either<Failure, Note>> getNoteById(String id);
  Future<Either<Failure, Note>> createNote(Note note);
  Future<Either<Failure, Note>> updateNote(Note note);
  Future<Either<Failure, void>> deleteNote(String id);
  Future<Either<Failure, List<Note>>> searchNotes(String query);
}