import 'package:floor/floor.dart';

@Entity(tableName: 'tags')
class TagModel {
  @PrimaryKey()
  final String id;
  
  final String name;
  final String color;
  
  @ColumnInfo(name: 'created_at')
  final String createdAt;
  
  @ColumnInfo(name: 'usage_count')
  final int usageCount;

  const TagModel({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
    required this.usageCount,
  });
}

@Entity(tableName: 'note_tags')
class NoteTagModel {
  @PrimaryKey()
  final String id;
  
  @ColumnInfo(name: 'note_id')
  final String noteId;
  
  @ColumnInfo(name: 'tag_id')
  final String tagId;

  const NoteTagModel({
    required this.id,
    required this.noteId,
    required this.tagId,
  });
}