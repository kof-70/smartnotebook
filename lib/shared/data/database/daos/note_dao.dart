import 'package:floor/floor.dart';

import '../../../../features/zone_1_raw/data/models/note_model.dart';

@dao
abstract class NoteDao {
  @Query('SELECT * FROM notes ORDER BY updated_at DESC')
  Future<List<NoteModel>> getAllNotes();

  @Query('SELECT * FROM notes WHERE id = :id')
  Future<NoteModel?> getNoteById(String id);

  @Query('SELECT * FROM notes WHERE title LIKE :query OR content LIKE :query ORDER BY updated_at DESC')
  Future<List<NoteModel>> searchNotes(String query);

  @Query('SELECT * FROM notes WHERE type = :type ORDER BY updated_at DESC')
  Future<List<NoteModel>> getNotesByType(String type);

  @Query('SELECT * FROM notes WHERE created_at >= :startDate AND created_at <= :endDate ORDER BY updated_at DESC')
  Future<List<NoteModel>> getNotesByDateRange(String startDate, String endDate);

  @insert
  Future<void> insertNote(NoteModel note);

  @update
  Future<void> updateNote(NoteModel note);

  @delete
  Future<void> deleteNote(NoteModel note);

  @Query('DELETE FROM notes WHERE id = :id')
  Future<void> deleteNoteById(String id);

  @Query('SELECT COUNT(*) FROM notes')
  Future<int?> getNotesCount();

  @Query('SELECT * FROM notes WHERE sync_status = :status')
  Future<List<NoteModel>> getNotesBySyncStatus(String status);
}