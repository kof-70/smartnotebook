import 'package:floor/floor.dart';
import 'dart:convert';

import '../../domain/entities/note.dart';

@Entity(tableName: 'notes')
class NoteModel {
  @PrimaryKey()
  final String id;
  
  final String title;
  final String content;
  
  @ColumnInfo(name: 'created_at')
  final String createdAt;
  
  @ColumnInfo(name: 'updated_at')
  final String updatedAt;
  
  final String tags; // JSON string
  final String type;
  
  @ColumnInfo(name: 'media_files')
  final String mediaFiles; // JSON string
  
  @ColumnInfo(name: 'ai_analysis')
  final String? aiAnalysis;
  
  @ColumnInfo(name: 'sync_status')
  final String syncStatus;
  
  @ColumnInfo(name: 'is_encrypted')
  final bool isEncrypted;

  const NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.tags,
    required this.type,
    required this.mediaFiles,
    this.aiAnalysis,
    required this.syncStatus,
    required this.isEncrypted,
  });

  factory NoteModel.fromEntity(Note note) {
    return NoteModel(
      id: note.id,
      title: note.title,
      content: note.content,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      tags: jsonEncode(note.tags),
      type: note.type.name,
      mediaFiles: jsonEncode(note.mediaFiles),
      aiAnalysis: note.aiAnalysis,
      syncStatus: note.syncStatus,
      isEncrypted: note.isEncrypted,
    );
  }

  Note toEntity() {
    return Note(
      id: id,
      title: title,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      tags: List<String>.from(jsonDecode(tags)),
      type: NoteType.values.firstWhere((e) => e.name == type),
      mediaFiles: List<String>.from(jsonDecode(mediaFiles)),
      aiAnalysis: aiAnalysis,
      syncStatus: syncStatus,
      isEncrypted: isEncrypted,
    );
  }

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    String? createdAt,
    String? updatedAt,
    String? tags,
    String? type,
    String? mediaFiles,
    String? aiAnalysis,
    String? syncStatus,
    bool? isEncrypted,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      type: type ?? this.type,
      mediaFiles: mediaFiles ?? this.mediaFiles,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      syncStatus: syncStatus ?? this.syncStatus,
      isEncrypted: isEncrypted ?? this.isEncrypted,
    );
  }
}