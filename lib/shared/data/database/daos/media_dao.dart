import 'package:floor/floor.dart';

import '../../../../features/zone_1_raw/data/models/media_model.dart';

@dao
abstract class MediaDao {
  @Query('SELECT * FROM media ORDER BY created_at DESC')
  Future<List<MediaModel>> getAllMedia();

  @Query('SELECT * FROM media WHERE id = :id')
  Future<MediaModel?> getMediaById(String id);

  @Query('SELECT * FROM media WHERE note_id = :noteId ORDER BY created_at ASC')
  Future<List<MediaModel>> getMediaByNoteId(String noteId);

  @Query('SELECT * FROM media WHERE type = :type ORDER BY created_at DESC')
  Future<List<MediaModel>> getMediaByType(String type);

  @insert
  Future<void> insertMedia(MediaModel media);

  @update
  Future<void> updateMedia(MediaModel media);

  @delete
  Future<void> deleteMedia(MediaModel media);

  @Query('DELETE FROM media WHERE id = :id')
  Future<void> deleteMediaById(String id);

  @Query('DELETE FROM media WHERE note_id = :noteId')
  Future<void> deleteMediaByNoteId(String noteId);
}