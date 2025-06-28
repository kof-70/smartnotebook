import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class SearchNotes {
  final NoteRepository repository;

  SearchNotes(this.repository);

  Future<Either<Failure, List<Note>>> call(SearchNotesParams params) async {
    return await repository.searchNotes(params.query);
  }
}

class SearchNotesParams {
  final String query;

  SearchNotesParams(this.query);
}