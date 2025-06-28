import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';

class FileUtils {
  static Future<Directory> getAppDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  static Future<Directory> createDirectory(String directoryName) async {
    final appDir = await getAppDirectory();
    final directory = Directory(path.join(appDir.path, directoryName));
    
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    return directory;
  }

  static Future<String> generateUniqueFileName(String extension) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${timestamp}_${DateTime.now().microsecond}.$extension';
  }

  static String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }

  static String getFileName(String filePath) {
    return path.basename(filePath);
  }

  static String getFileNameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }

  static String? getMimeType(String filePath) {
    return lookupMimeType(filePath);
  }

  static bool isImageFile(String filePath) {
    final mimeType = getMimeType(filePath);
    return mimeType?.startsWith('image/') ?? false;
  }

  static bool isVideoFile(String filePath) {
    final mimeType = getMimeType(filePath);
    return mimeType?.startsWith('video/') ?? false;
  }

  static bool isAudioFile(String filePath) {
    final mimeType = getMimeType(filePath);
    return mimeType?.startsWith('audio/') ?? false;
  }

  static bool isTextFile(String filePath) {
    final mimeType = getMimeType(filePath);
    return mimeType?.startsWith('text/') ?? false;
  }

  static Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> copyFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(destinationPath);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> moveFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.rename(destinationPath);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<List<FileSystemEntity>> listFiles(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (await directory.exists()) {
        return await directory.list().toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}