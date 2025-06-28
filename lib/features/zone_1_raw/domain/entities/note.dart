import 'package:equatable/equatable.dart';

enum NoteType { text, audio, video, image, mixed }

class Note extends Equatable {
  final String id;
  final String title;
  final String content;
  final String createdAt;
  final String updatedAt;
  final List<String> tags;
  final NoteType type;
  final List<String> mediaFiles;
  final String? aiAnalysis;
  final String syncStatus;
  final bool isEncrypted;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.tags,
    required this.type,
    this.mediaFiles = const [],
    this.aiAnalysis,
    this.syncStatus = 'pending',
    this.isEncrypted = false,
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? createdAt,
    String? updatedAt,
    List<String>? tags,
    NoteType? type,
    List<String>? mediaFiles,
    String? aiAnalysis,
    String? syncStatus,
    bool? isEncrypted,
  }) {
    return Note(
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

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        createdAt,
        updatedAt,
        tags,
        type,
        mediaFiles,
        aiAnalysis,
        syncStatus,
        isEncrypted,
      ];
}