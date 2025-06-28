import 'dart:io';
import 'package:file_picker/file_picker.dart';

import '../../core/security/encryption_service.dart';
import '../../core/utils/file_utils.dart';

class FileService {
  final EncryptionService _encryptionService;

  FileService({required EncryptionService encryptionService})
      : _encryptionService = encryptionService;

  Future<String?> pickFile({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first.path;
      }
      
      return null;
    } catch (e) {
      print('Error picking file: $e');
      return null;
    }
  }

  Future<List<String>> pickMultipleFiles({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
      );

      if (result != null) {
        return result.files
            .where((file) => file.path != null)
            .map((file) => file.path!)
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Error picking multiple files: $e');
      return [];
    }
  }

  Future<String?> saveFile(String content, String fileName) async {
    try {
      final directory = await FileUtils.getAppDirectory();
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(content);
      return file.path;
    } catch (e) {
      print('Error saving file: $e');
      return null;
    }
  }

  Future<String?> readFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      print('Error reading file: $e');
      return null;
    }
  }

  Future<bool> encryptFile(String inputPath, String outputPath) async {
    try {
      await _encryptionService.encryptFile(inputPath, outputPath);
      return true;
    } catch (e) {
      print('Error encrypting file: $e');
      return false;
    }
  }

  Future<bool> decryptFile(String inputPath, String outputPath) async {
    try {
      await _encryptionService.decryptFile(inputPath, outputPath);
      return true;
    } catch (e) {
      print('Error decrypting file: $e');
      return false;
    }
  }

  Future<bool> deleteFile(String filePath) async {
    return await FileUtils.deleteFile(filePath);
  }

  Future<bool> copyFile(String sourcePath, String destinationPath) async {
    return await FileUtils.copyFile(sourcePath, destinationPath);
  }

  Future<bool> moveFile(String sourcePath, String destinationPath) async {
    return await FileUtils.moveFile(sourcePath, destinationPath);
  }

  Future<int> getFileSize(String filePath) async {
    return await FileUtils.getFileSize(filePath);
  }

  String formatFileSize(int bytes) {
    return FileUtils.formatFileSize(bytes);
  }

  bool isImageFile(String filePath) {
    return FileUtils.isImageFile(filePath);
  }

  bool isVideoFile(String filePath) {
    return FileUtils.isVideoFile(filePath);
  }

  bool isAudioFile(String filePath) {
    return FileUtils.isAudioFile(filePath);
  }
}