import 'package:floor/floor.dart';

@Entity(tableName: 'media')
class MediaModel {
  @PrimaryKey()
  final String id;
  
  @ColumnInfo(name: 'note_id')
  final String noteId;
  
  final String type; // audio, video, image
  final String path;
  final String name;
  final int size;
  final String? thumbnail;
  final int? duration; // for audio/video in seconds
  
  @ColumnInfo(name: 'created_at')
  final String createdAt;
  
  @ColumnInfo(name: 'is_encrypted')
  final bool isEncrypted;

  const MediaModel({
    required this.id,
    required this.noteId,
    required this.type,
    required this.path,
    required this.name,
    required this.size,
    this.thumbnail,
    this.duration,
    required this.createdAt,
    required this.isEncrypted,
  });
}