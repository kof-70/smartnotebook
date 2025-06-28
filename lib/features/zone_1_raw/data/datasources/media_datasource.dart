import 'dart:io';
import 'package:path/path.dart' as path;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../shared/services/file_service.dart';

abstract class MediaDataSource {
  Future<String> saveMediaFile(String sourcePath, String fileName, String mediaType);
  Future<bool> deleteMediaFile(String filePath);
  Future<List<String>> getMediaFiles(String noteId);
}

class MediaDataSourceImpl implements MediaDataSource {
  final FileService fileService;

  MediaDataSourceImpl({required this.fileService});

  @override
  Future<String> saveMediaFile(String sourcePath, String fileName, String mediaType) async {
    try {
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
    } catch (e) {
      print('Error saving media file: $e');
      rethrow;
    }
  }

  @override
  Future<bool> deleteMediaFile(String filePath) async {
    try {
      return await fileService.deleteFile(filePath);
    } catch (e) {
      print('Error deleting media file: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getMediaFiles(String noteId) async {
    try {
      // This would typically query a database table that maps note IDs to media files
      // For now, we'll return an empty list as this functionality would be handled
      // by the note entity's mediaFiles property
      return [];
    } catch (e) {
      print('Error getting media files: $e');
      return [];
    }
  }
}