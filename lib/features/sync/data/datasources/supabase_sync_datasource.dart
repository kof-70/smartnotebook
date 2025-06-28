import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/data/database/app_database.dart';
import '../../../../shared/data/preferences/app_preferences.dart';
import '../../../zone_1_raw/data/models/note_model.dart';
import '../../../zone_1_raw/data/models/media_model.dart';
import '../../../zone_1_raw/data/models/tag_model.dart';
import '../../../zone_1_raw/domain/entities/note.dart';
import 'sync_datasource.dart';

class SupabaseSyncDataSource implements SyncDataSource {
  final SupabaseClient _supabase;
  final AppDatabase _database;
  final AppPreferences _preferences;

  SupabaseSyncDataSource({
    required SupabaseClient supabase,
    required AppDatabase database,
    required AppPreferences preferences,
  })  : _supabase = supabase,
        _database = database,
        _preferences = preferences;

  @override
  Future<bool> syncData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      print('Starting sync for user: $userId');
      
      // 1. Upload local changes to Supabase
      await _uploadLocalChanges(userId);
      
      // 2. Download remote changes from Supabase
      await _downloadRemoteChanges(userId);
      
      // 3. Update last sync time
      await _preferences.setLastSyncTime(DateTime.now());
      
      print('Sync completed successfully');
      return true;
    } catch (e) {
      print('Sync error: $e');
      return false;
    }
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    return await _preferences.getLastSyncTime();
  }

  @override
  Future<bool> hasUnsyncedChanges() async {
    try {
      // Check local database for pending changes
      final pendingNotes = await _database.noteDao.getNotesBySyncStatus('pending');
      final errorNotes = await _database.noteDao.getNotesBySyncStatus('error');
      
      return pendingNotes.isNotEmpty || errorNotes.isNotEmpty;
    } catch (e) {
      print('Error checking unsynced changes: $e');
      return false;
    }
  }

  Future<void> _uploadLocalChanges(String userId) async {
    try {
      print('Uploading local changes...');
      
      // Get all notes that need syncing
      final pendingNotes = await _database.noteDao.getNotesBySyncStatus('pending');
      final errorNotes = await _database.noteDao.getNotesBySyncStatus('error');
      final notesToSync = [...pendingNotes, ...errorNotes];

      for (final noteModel in notesToSync) {
        try {
          await _syncNoteToRemote(noteModel, userId);
          
          // Update local sync status to 'synced'
          final updatedNote = NoteModel(
            id: noteModel.id,
            title: noteModel.title,
            content: noteModel.content,
            createdAt: noteModel.createdAt,
            updatedAt: DateTime.now().toIso8601String(),
            tags: noteModel.tags,
            type: noteModel.type,
            mediaFiles: noteModel.mediaFiles,
            aiAnalysis: noteModel.aiAnalysis,
            syncStatus: 'synced',
            isEncrypted: noteModel.isEncrypted,
          );
          
          await _database.noteDao.updateNote(updatedNote);
          print('Successfully synced note: ${noteModel.id}');
          
        } catch (e) {
          print('Failed to sync note ${noteModel.id}: $e');
          
          // Mark as error for retry later
          final errorNote = NoteModel(
            id: noteModel.id,
            title: noteModel.title,
            content: noteModel.content,
            createdAt: noteModel.createdAt,
            updatedAt: noteModel.updatedAt,
            tags: noteModel.tags,
            type: noteModel.type,
            mediaFiles: noteModel.mediaFiles,
            aiAnalysis: noteModel.aiAnalysis,
            syncStatus: 'error',
            isEncrypted: noteModel.isEncrypted,
          );
          
          await _database.noteDao.updateNote(errorNote);
        }
      }
    } catch (e) {
      print('Error uploading local changes: $e');
      rethrow;
    }
  }

  Future<void> _downloadRemoteChanges(String userId) async {
    try {
      print('Downloading remote changes...');
      
      final lastSync = await getLastSyncTime();
      
      // Get notes updated since last sync
      var query = _supabase
          .from('notes')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);
      
      if (lastSync != null) {
        query = query.gte('updated_at', lastSync.toIso8601String());
      }
      
      final response = await query;
      
      print('Found ${response.length} remote notes to process');
      
      // Process each remote note
      for (final noteData in response) {
        await _processRemoteNote(noteData);
      }
      
      // Also sync media and tags
      await _downloadRemoteMedia(userId, lastSync);
      await _downloadRemoteTags(userId, lastSync);
      
    } catch (e) {
      print('Error downloading remote changes: $e');
      rethrow;
    }
  }

  Future<void> _downloadRemoteMedia(String userId, DateTime? lastSync) async {
    try {
      var query = _supabase
          .from('media')
          .select()
          .eq('user_id', userId);
      
      if (lastSync != null) {
        query = query.gte('created_at', lastSync.toIso8601String());
      }
      
      final response = await query;
      
      for (final mediaData in response) {
        await _processRemoteMedia(mediaData);
      }
    } catch (e) {
      print('Error downloading remote media: $e');
    }
  }

  Future<void> _downloadRemoteTags(String userId, DateTime? lastSync) async {
    try {
      var query = _supabase
          .from('tags')
          .select()
          .eq('user_id', userId);
      
      if (lastSync != null) {
        query = query.gte('created_at', lastSync.toIso8601String());
      }
      
      final response = await query;
      
      for (final tagData in response) {
        await _processRemoteTag(tagData);
      }
    } catch (e) {
      print('Error downloading remote tags: $e');
    }
  }

  Future<void> _processRemoteNote(Map<String, dynamic> noteData) async {
    try {
      final remoteNote = _convertSupabaseToLocalNote(noteData);
      final existingNote = await _database.noteDao.getNoteById(remoteNote.id);
      
      if (existingNote == null) {
        // Note doesn't exist locally, insert it
        await _database.noteDao.insertNote(remoteNote);
        print('Inserted new note from remote: ${remoteNote.id}');
      } else {
        // Note exists, check if remote is newer
        final remoteUpdated = DateTime.parse(remoteNote.updatedAt);
        final localUpdated = DateTime.parse(existingNote.updatedAt);
        
        if (remoteUpdated.isAfter(localUpdated)) {
          // Remote is newer, update local
          final updatedNote = remoteNote.copyWith(syncStatus: 'synced');
          await _database.noteDao.updateNote(updatedNote);
          print('Updated note from remote: ${remoteNote.id}');
        } else if (localUpdated.isAfter(remoteUpdated) && existingNote.syncStatus == 'pending') {
          // Local is newer and pending sync, upload it
          await _syncNoteToRemote(existingNote, noteData['user_id']);
        }
      }
    } catch (e) {
      print('Error processing remote note: $e');
    }
  }

  Future<void> _processRemoteMedia(Map<String, dynamic> mediaData) async {
    try {
      final remoteMedia = MediaModel(
        id: mediaData['id'],
        noteId: mediaData['note_id'],
        type: mediaData['type'],
        path: mediaData['path'],
        name: mediaData['name'],
        size: mediaData['size'] ?? 0,
        thumbnail: mediaData['thumbnail'],
        duration: mediaData['duration'],
        createdAt: mediaData['created_at'],
        isEncrypted: mediaData['is_encrypted'] ?? false,
      );
      
      final existingMedia = await _database.mediaDao.getMediaById(remoteMedia.id);
      
      if (existingMedia == null) {
        await _database.mediaDao.insertMedia(remoteMedia);
        print('Inserted new media from remote: ${remoteMedia.id}');
      }
    } catch (e) {
      print('Error processing remote media: $e');
    }
  }

  Future<void> _processRemoteTag(Map<String, dynamic> tagData) async {
    try {
      final remoteTag = TagModel(
        id: tagData['id'],
        name: tagData['name'],
        color: tagData['color'] ?? '#3B82F6',
        createdAt: tagData['created_at'],
        usageCount: tagData['usage_count'] ?? 0,
      );
      
      final existingTag = await _database.tagDao.getTagById(remoteTag.id);
      
      if (existingTag == null) {
        await _database.tagDao.insertTag(remoteTag);
        print('Inserted new tag from remote: ${remoteTag.id}');
      } else {
        // Update usage count if remote is higher
        if (remoteTag.usageCount > existingTag.usageCount) {
          await _database.tagDao.updateTag(remoteTag);
          print('Updated tag from remote: ${remoteTag.id}');
        }
      }
    } catch (e) {
      print('Error processing remote tag: $e');
    }
  }

  Future<void> _syncNoteToRemote(NoteModel noteModel, String userId) async {
    final noteData = _convertLocalToSupabaseNote(noteModel, userId);
    
    // Use upsert to handle both insert and update
    await _supabase
        .from('notes')
        .upsert(noteData);
  }

  NoteModel _convertSupabaseToLocalNote(Map<String, dynamic> data) {
    return NoteModel(
      id: data['id'],
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: data['created_at'],
      updatedAt: data['updated_at'],
      tags: _convertJsonToStringList(data['tags']),
      type: data['type'] ?? 'text',
      mediaFiles: _convertJsonToStringList(data['media_files']),
      aiAnalysis: data['ai_analysis'],
      syncStatus: 'synced', // Mark as synced since it came from remote
      isEncrypted: data['is_encrypted'] ?? false,
    );
  }

  Map<String, dynamic> _convertLocalToSupabaseNote(NoteModel note, String userId) {
    return {
      'id': note.id,
      'user_id': userId,
      'title': note.title,
      'content': note.content,
      'type': note.type,
      'tags': _convertStringListToJson(note.tags),
      'media_files': _convertStringListToJson(note.mediaFiles),
      'ai_analysis': note.aiAnalysis,
      'sync_status': 'synced',
      'is_encrypted': note.isEncrypted,
      'created_at': note.createdAt,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  String _convertStringListToJson(String listString) {
    // Convert the JSON string from local database to proper format
    return listString;
  }

  String _convertJsonToStringList(dynamic jsonData) {
    // Convert Supabase JSON to string format for local database
    if (jsonData == null) return '[]';
    if (jsonData is String) return jsonData;
    return jsonData.toString();
  }

  // Public methods for syncing specific items
  Future<void> syncNote(Note note) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final noteModel = NoteModel.fromEntity(note);
      await _syncNoteToRemote(noteModel, userId);
      
      // Update local sync status
      final updatedNote = noteModel.copyWith(syncStatus: 'synced');
      await _database.noteDao.updateNote(updatedNote);
      
      print('Note synced successfully: ${note.id}');
    } catch (e) {
      print('Error syncing note: $e');
      
      // Mark as error for retry
      final noteModel = NoteModel.fromEntity(note.copyWith(syncStatus: 'error'));
      await _database.noteDao.updateNote(noteModel);
      rethrow;
    }
  }

  Future<void> deleteNoteFromRemote(String noteId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Delete from Supabase
      await _supabase
          .from('notes')
          .delete()
          .eq('id', noteId)
          .eq('user_id', userId);

      // Also delete associated media
      await _supabase
          .from('media')
          .delete()
          .eq('note_id', noteId)
          .eq('user_id', userId);

      print('Note deleted from remote: $noteId');
    } catch (e) {
      print('Error deleting note from remote: $e');
      rethrow;
    }
  }

  // Real-time subscriptions
  void subscribeToChanges() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Subscribe to notes changes
    _supabase
        .from('notes')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((data) {
          print('Real-time notes update received: ${data.length} items');
          _handleRealtimeNotesUpdate(data);
        });

    // Subscribe to media changes
    _supabase
        .from('media')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((data) {
          print('Real-time media update received: ${data.length} items');
          _handleRealtimeMediaUpdate(data);
        });

    // Subscribe to tags changes
    _supabase
        .from('tags')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((data) {
          print('Real-time tags update received: ${data.length} items');
          _handleRealtimeTagsUpdate(data);
        });
  }

  void _handleRealtimeNotesUpdate(List<Map<String, dynamic>> data) {
    // Handle real-time updates for notes
    for (final noteData in data) {
      _processRemoteNote(noteData);
    }
  }

  void _handleRealtimeMediaUpdate(List<Map<String, dynamic>> data) {
    // Handle real-time updates for media
    for (final mediaData in data) {
      _processRemoteMedia(mediaData);
    }
  }

  void _handleRealtimeTagsUpdate(List<Map<String, dynamic>> data) {
    // Handle real-time updates for tags
    for (final tagData in data) {
      _processRemoteTag(tagData);
    }
  }
}