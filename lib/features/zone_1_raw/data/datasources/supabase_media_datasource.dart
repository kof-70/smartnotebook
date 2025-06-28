import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../shared/services/file_service.dart';
import 'media_datasource.dart';

class SupabaseMediaDataSource implements MediaDataSource {
  final SupabaseClient _supabase;
  final FileService _fileService;

  SupabaseMediaDataSource({
    required SupabaseClient supabase,
    required FileService fileService,
  })  : _supabase = supabase,
        _fileService = fileService;

  @override
  Future<String> saveMediaFile(String sourcePath, String fileName, String mediaType) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Generate unique filename if not provided
      final finalFileName = fileName.isNotEmpty 
          ? fileName 
          : await FileUtils.generateUniqueFileName(
              FileUtils.getFileExtension(sourcePath).replaceAll('.', '')
            );

      // Create storage path: userId/mediaType/filename
      final storagePath = '$userId/$mediaType/$finalFileName';
      
      // Read file bytes
      final file = File(sourcePath);
      final fileBytes = await file.readAsBytes();
      
      // Upload to Supabase Storage
      await _supabase.storage
          .from(SupabaseConfig.notesBucket)
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: FileUtils.getMimeType(sourcePath),
              upsert: false,
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from(SupabaseConfig.notesBucket)
          .getPublicUrl(storagePath);

      print('Media file uploaded to Supabase: $storagePath');
      
      // Also save locally for offline access
      final localPath = await _saveLocalCopy(sourcePath, fileName, mediaType);
      
      // Return the storage path (we'll use this to reference the file)
      return storagePath;
      
    } catch (e) {
      print('Error uploading media file to Supabase: $e');
      
      // Fallback to local storage only
      return await _saveLocalCopy(sourcePath, fileName, mediaType);
    }
  }

  @override
  Future<bool> deleteMediaFile(String filePath) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Delete from Supabase Storage if it's a storage path
      if (filePath.startsWith(userId)) {
        await _supabase.storage
            .from(SupabaseConfig.notesBucket)
            .remove([filePath]);
        
        print('Media file deleted from Supabase: $filePath');
      }
      
      // Also delete local copy
      return await _fileService.deleteFile(filePath);
      
    } catch (e) {
      print('Error deleting media file: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getMediaFiles(String noteId) async {
    try {
      // This would typically query the media table in Supabase
      final response = await _supabase
          .from('media')
          .select('path')
          .eq('note_id', noteId);
      
      return response.map<String>((item) => item['path'] as String).toList();
    } catch (e) {
      print('Error getting media files: $e');
      return [];
    }
  }

  Future<String> _saveLocalCopy(String sourcePath, String fileName, String mediaType) async {
    // Determine the appropriate directory based on media type
    String directoryName;
    switch (mediaType.toLowerCase()) {
      case 'audio':
        directoryName = AppConstants.audioDirectory;
        break;
      case 'video':
        directoryName = AppConstants.videoDirectory;
        break;
      case 'image':
        directoryName = AppConstants.imagesDirectory;
        break;
      default:
        directoryName = AppConstants.notesDirectory;
    }

    // Create the media directory if it doesn't exist
    final mediaDirectory = await FileUtils.createDirectory(directoryName);
    
    // Generate a unique filename if not provided
    final finalFileName = fileName.isNotEmpty 
        ? fileName 
        : await FileUtils.generateUniqueFileName(
            FileUtils.getFileExtension(sourcePath).replaceAll('.', '')
          );
    
    // Create the destination path
    final destinationPath = path.join(mediaDirectory.path, finalFileName);
    
    // Copy the file from source to destination
    final success = await FileUtils.copyFile(sourcePath, destinationPath);
    
    if (success) {
      // Delete the temporary source file if it's different from destination
      if (sourcePath != destinationPath) {
        await FileUtils.deleteFile(sourcePath);
      }
      return destinationPath;
    } else {
      throw Exception('Failed to copy media file');
    }
  }

  // Download media file from Supabase to local storage
  Future<String?> downloadMediaFile(String storagePath, String localFileName) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Download file bytes from Supabase Storage
      final fileBytes = await _supabase.storage
          .from(SupabaseConfig.notesBucket)
          .download(storagePath);

      // Determine media type from storage path
      final pathParts = storagePath.split('/');
      final mediaType = pathParts.length > 1 ? pathParts[1] : 'unknown';
      
      // Save to local storage
      String directoryName;
      switch (mediaType.toLowerCase()) {
        case 'audio':
          directoryName = AppConstants.audioDirectory;
          break;
        case 'video':
          directoryName = AppConstants.videoDirectory;
          break;
        case 'image':
          directoryName = AppConstants.imagesDirectory;
          break;
        default:
          directoryName = AppConstants.notesDirectory;
      }

      final mediaDirectory = await FileUtils.createDirectory(directoryName);
      final localPath = path.join(mediaDirectory.path, localFileName);
      
      // Write bytes to local file
      final localFile = File(localPath);
      await localFile.writeAsBytes(fileBytes);
      
      print('Media file downloaded from Supabase: $storagePath -> $localPath');
      return localPath;
      
    } catch (e) {
      print('Error downloading media file: $e');
      return null;
    }
  }

  // Get public URL for media file
  String getPublicUrl(String storagePath) {
    return _supabase.storage
        .from(SupabaseConfig.notesBucket)
        .getPublicUrl(storagePath);
  }

  // Upload thumbnail for video/image files
  Future<String?> uploadThumbnail(String thumbnailPath, String originalStoragePath) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Create thumbnail storage path
      final originalFileName = path.basenameWithoutExtension(originalStoragePath);
      final thumbnailStoragePath = '$userId/thumbnails/${originalFileName}_thumb.jpg';
      
      // Read thumbnail bytes
      final thumbnailFile = File(thumbnailPath);
      final thumbnailBytes = await thumbnailFile.readAsBytes();
      
      // Upload thumbnail to Supabase Storage
      await _supabase.storage
          .from(SupabaseConfig.notesBucket)
          .uploadBinary(
            thumbnailStoragePath,
            thumbnailBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      print('Thumbnail uploaded to Supabase: $thumbnailStoragePath');
      return thumbnailStoragePath;
      
    } catch (e) {
      print('Error uploading thumbnail: $e');
      return null;
    }
  }

  // Sync media metadata to Supabase database
  Future<void> syncMediaMetadata({
    required String id,
    required String noteId,
    required String type,
    required String storagePath,
    required String name,
    required int size,
    String? thumbnail,
    int? duration,
    bool isEncrypted = false,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final mediaData = {
        'id': id,
        'note_id': noteId,
        'user_id': userId,
        'type': type,
        'path': storagePath,
        'name': name,
        'size': size,
        'thumbnail': thumbnail,
        'duration': duration,
        'is_encrypted': isEncrypted,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Upsert media metadata
      await _supabase
          .from('media')
          .upsert(mediaData);

      print('Media metadata synced to Supabase: $id');
      
    } catch (e) {
      print('Error syncing media metadata: $e');
      rethrow;
    }
  }

  // Get media metadata from Supabase
  Future<Map<String, dynamic>?> getMediaMetadata(String mediaId) async {
    try {
      final response = await _supabase
          .from('media')
          .select()
          .eq('id', mediaId)
          .single();
      
      return response;
    } catch (e) {
      print('Error getting media metadata: $e');
      return null;
    }
  }

  // List all media files for a user
  Future<List<Map<String, dynamic>>> listUserMedia() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('media')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error listing user media: $e');
      return [];
    }
  }

  // Clean up orphaned media files (files without associated notes)
  Future<void> cleanupOrphanedMedia() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get media files that don't have associated notes
      final orphanedMedia = await _supabase
          .from('media')
          .select('id, path')
          .eq('user_id', userId)
          .not('note_id', 'in', '(SELECT id FROM notes WHERE user_id = $userId)');

      for (final media in orphanedMedia) {
        // Delete from storage
        await _supabase.storage
            .from(SupabaseConfig.notesBucket)
            .remove([media['path']]);

        // Delete metadata
        await _supabase
            .from('media')
            .delete()
            .eq('id', media['id']);

        print('Cleaned up orphaned media: ${media['id']}');
      }
      
    } catch (e) {
      print('Error cleaning up orphaned media: $e');
    }
  }
}