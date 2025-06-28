import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../datasources/local_note_datasource.dart';
import '../datasources/supabase_media_datasource.dart';
import '../../../sync/data/datasources/supabase_sync_datasource.dart';

class NoteRepositoryImpl implements NoteRepository {
  final LocalNoteDataSource localDataSource;
  final SupabaseMediaDataSource mediaDataSource;
  final NetworkInfo networkInfo;
  final SupabaseSyncDataSource syncDataSource;

  NoteRepositoryImpl({
    required this.localDataSource,
    required this.mediaDataSource,
    required this.networkInfo,
    required this.syncDataSource,
  });

  @override
  Future<Either<Failure, List<Note>>> getNotes() async {
    try {
      final notes = await localDataSource.getNotes();
      return Right(notes.map((model) => model.toEntity()).toList());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Note>> getNoteById(String id) async {
    try {
      final noteModel = await localDataSource.getNoteById(id);
      if (noteModel != null) {
        return Right(noteModel.toEntity());
      } else {
        return const Left(DatabaseFailure('Note not found'));
      }
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Note>> createNote(Note note) async {
    try {
      // Create note locally first
      await localDataSource.insertNote(note);
      
      // Process media files if any
      if (note.mediaFiles.isNotEmpty) {
        await _processMediaFiles(note);
      }
      
      // Try to sync to remote if online
      if (await networkInfo.isConnected) {
        try {
          await syncDataSource.syncNote(note);
        } catch (e) {
          print('Failed to sync note immediately, will retry later: $e');
          // Note is already saved locally with pending status
        }
      }
      
      return Right(note);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Note>> updateNote(Note note) async {
    try {
      // Update note locally first
      final updatedNote = note.copyWith(syncStatus: 'pending');
      await localDataSource.updateNote(updatedNote);
      
      // Process any new media files
      if (note.mediaFiles.isNotEmpty) {
        await _processMediaFiles(note);
      }
      
      // Try to sync to remote if online
      if (await networkInfo.isConnected) {
        try {
          await syncDataSource.syncNote(updatedNote);
        } catch (e) {
          print('Failed to sync note immediately, will retry later: $e');
          // Note is already saved locally with pending status
        }
      }
      
      return Right(updatedNote);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNote(String id) async {
    try {
      // Get note to find associated media files
      final noteModel = await localDataSource.getNoteById(id);
      
      // Delete associated media files
      if (noteModel != null && noteModel.mediaFiles.isNotEmpty) {
        await _deleteMediaFiles(noteModel.mediaFiles);
      }
      
      // Delete from local database
      await localDataSource.deleteNote(id);
      
      // Try to delete from remote if online
      if (await networkInfo.isConnected) {
        try {
          await syncDataSource.deleteNoteFromRemote(id);
        } catch (e) {
          print('Failed to delete note from remote immediately: $e');
          // Note is already deleted locally, remote deletion will be handled in next sync
        }
      }
      
      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Note>>> searchNotes(String query) async {
    try {
      final notes = await localDataSource.searchNotes(query);
      return Right(notes.map((model) => model.toEntity()).toList());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  Future<void> _processMediaFiles(Note note) async {
    try {
      for (final mediaPath in note.mediaFiles) {
        // Determine media type from file extension
        String mediaType = 'unknown';
        if (mediaPath.contains('audio') || mediaPath.endsWith('.m4a') || mediaPath.endsWith('.mp3')) {
          mediaType = 'audio';
        } else if (mediaPath.contains('video') || mediaPath.endsWith('.mp4') || mediaPath.endsWith('.mov')) {
          mediaType = 'video';
        } else if (mediaPath.contains('image') || mediaPath.endsWith('.jpg') || mediaPath.endsWith('.png')) {
          mediaType = 'image';
        }

        // Upload to Supabase Storage if online
        if (await networkInfo.isConnected) {
          try {
            final fileName = mediaPath.split('/').last;
            final storagePath = await mediaDataSource.saveMediaFile(mediaPath, fileName, mediaType);
            
            // Sync media metadata to Supabase
            await mediaDataSource.syncMediaMetadata(
              id: '${note.id}_${fileName}',
              noteId: note.id,
              type: mediaType,
              storagePath: storagePath,
              name: fileName,
              size: await _getFileSize(mediaPath),
            );
            
            print('Media file processed and uploaded: $fileName');
          } catch (e) {
            print('Failed to upload media file: $e');
            // File is still saved locally, will retry on next sync
          }
        }
      }
    } catch (e) {
      print('Error processing media files: $e');
    }
  }

  Future<void> _deleteMediaFiles(String mediaFilesJson) async {
    try {
      // Parse media files JSON and delete each file
      // This is a simplified implementation
      final mediaFiles = mediaFilesJson.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').split(',');
      
      for (final mediaPath in mediaFiles) {
        if (mediaPath.trim().isNotEmpty) {
          await mediaDataSource.deleteMediaFile(mediaPath.trim());
        }
      }
    } catch (e) {
      print('Error deleting media files: $e');
    }
  }

  Future<int> _getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}