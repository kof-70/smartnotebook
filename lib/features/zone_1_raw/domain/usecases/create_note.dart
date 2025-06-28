import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/date_utils.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class CreateNote {
  final NoteRepository repository;

  CreateNote(this.repository);

  Future<Either<Failure, Note>> call(CreateNoteParams params) async {
    final note = Note(
      id: const Uuid().v4(),
      title: params.title,
      content: params.content,
      createdAt: AppDateUtils.toIsoString(DateTime.now()),
      updatedAt: AppDateUtils.toIsoString(DateTime.now()),
      tags: params.tags,
      type: params.type,
      mediaFiles: params.mediaFiles,
      syncStatus: 'pending',
      isEncrypted: false,
    );

    return await repository.createNote(note);
  }
}

class CreateNoteParams {
  final String title;
  final String content;
  final NoteType type;
  final List<String> tags;
  final List<String> mediaFiles;

  CreateNoteParams({
    required this.title,
    required this.content,
    required this.type,
    this.tags = const [],
    this.mediaFiles = const [],
  });
}