import '../models/note_model.dart';
import '../../domain/entities/note.dart';
import '../../../../shared/data/database/app_database.dart';

abstract class LocalNoteDataSource {
  Future<List<NoteModel>> getNotes();
  Future<NoteModel?> getNoteById(String id);
  Future<void> insertNote(Note note);
  Future<void> updateNote(Note note);
  Future<void> deleteNote(String id);
  Future<List<NoteModel>> searchNotes(String query);
}

class LocalNoteDataSourceImpl implements LocalNoteDataSource {
  final AppDatabase database;

  LocalNoteDataSourceImpl({required this.database});

  @override
  Future<List<NoteModel>> getNotes() async {
    return await database.noteDao.getAllNotes();
  }

  @override
  Future<NoteModel?> getNoteById(String id) async {
    return await database.noteDao.getNoteById(id);
  }

  @override
  Future<void> insertNote(Note note) async {
    final noteModel = NoteModel.fromEntity(note);
    await database.noteDao.insertNote(noteModel);
  }

  @override
  Future<void> updateNote(Note note) async {
    final noteModel = NoteModel.fromEntity(note);
    await database.noteDao.updateNote(noteModel);
  }

  @override
  Future<void> deleteNote(String id) async {
    await database.noteDao.deleteNoteById(id);
  }

  @override
  Future<List<NoteModel>> searchNotes(String query) async {
    return await database.noteDao.searchNotes('%$query%');
  }
}