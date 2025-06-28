import 'package:floor/floor.dart';

import '../../../../features/zone_1_raw/data/models/tag_model.dart';

@dao
abstract class TagDao {
  @Query('SELECT * FROM tags ORDER BY name ASC')
  Future<List<TagModel>> getAllTags();

  @Query('SELECT * FROM tags WHERE id = :id')
  Future<TagModel?> getTagById(String id);

  @Query('SELECT * FROM tags WHERE name = :name')
  Future<TagModel?> getTagByName(String name);

  @Query('SELECT t.* FROM tags t INNER JOIN note_tags nt ON t.id = nt.tag_id WHERE nt.note_id = :noteId')
  Future<List<TagModel>> getTagsByNoteId(String noteId);

  @insert
  Future<void> insertTag(TagModel tag);

  @update
  Future<void> updateTag(TagModel tag);

  @delete
  Future<void> deleteTag(TagModel tag);

  @Query('DELETE FROM tags WHERE id = :id')
  Future<void> deleteTagById(String id);

  @Query('INSERT INTO note_tags (note_id, tag_id) VALUES (:noteId, :tagId)')
  Future<void> addTagToNote(String noteId, String tagId);

  @Query('DELETE FROM note_tags WHERE note_id = :noteId AND tag_id = :tagId')
  Future<void> removeTagFromNote(String noteId, String tagId);

  @Query('DELETE FROM note_tags WHERE note_id = :noteId')
  Future<void> removeAllTagsFromNote(String noteId);
}