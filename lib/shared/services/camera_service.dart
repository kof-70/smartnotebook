import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/file_utils.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();
  List<CameraDescription>? _cameras;
  CameraController? _controller;

  Future<void> initialize() async {
    _cameras = await availableCameras();
  }

  Future<String?> captureImage({ImageSource source = ImageSource.camera}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final imagesDir = await FileUtils.createDirectory(AppConstants.imagesDirectory);
        final fileName = await FileUtils.generateUniqueFileName('jpg');
        final newPath = '${imagesDir.path}/$fileName';
        
        await File(image.path).copy(newPath);
        return newPath;
      }
      
      return null;
    } catch (e) {
      print('Error capturing image: $e');
      return null;
    }
  }

  Future<String?> captureVideo({ImageSource source = ImageSource.camera}) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 10),
      );

      if (video != null) {
        final videoDir = await FileUtils.createDirectory(AppConstants.videoDirectory);
        final fileName = await FileUtils.generateUniqueFileName('mp4');
        final newPath = '${videoDir.path}/$fileName';
        
        await File(video.path).copy(newPath);
        return newPath;
      }
      
      return null;
    } catch (e) {
      print('Error capturing video: $e');
      return null;
    }
  }

  Future<List<String>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultipleImages(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      final List<String> paths = [];
      final imagesDir = await FileUtils.createDirectory(AppConstants.imagesDirectory);

      for (final image in images) {
        final fileName = await FileUtils.generateUniqueFileName('jpg');
        final newPath = '${imagesDir.path}/$fileName';
        await File(image.path).copy(newPath);
        paths.add(newPath);
      }

      return paths;
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }

  Future<CameraController?> initializeCamera({
    CameraLensDirection direction = CameraLensDirection.back,
  }) async {
    if (_cameras == null || _cameras!.isEmpty) {
      await initialize();
    }

    if (_cameras == null || _cameras!.isEmpty) {
      return null;
    }

    final camera = _cameras!.firstWhere(
      (camera) => camera.lensDirection == direction,
      orElse: () => _cameras!.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
    );

    await _controller!.initialize();
    return _controller;
  }

  Future<String?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }

    try {
      final XFile image = await _controller!.takePicture();
      
      final imagesDir = await FileUtils.createDirectory(AppConstants.imagesDirectory);
      final fileName = await FileUtils.generateUniqueFileName('jpg');
      final newPath = '${imagesDir.path}/$fileName';
      
      await File(image.path).copy(newPath);
      return newPath;
    } catch (e) {
      print('Error taking picture: $e');
      return null;
    }
  }

  Future<String?> startVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }

    try {
      await _controller!.startVideoRecording();
      return 'recording_started';
    } catch (e) {
      print('Error starting video recording: $e');
      return null;
    }
  }

  Future<String?> stopVideoRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) {
      return null;
    }

    try {
      final XFile video = await _controller!.stopVideoRecording();
      
      final videoDir = await FileUtils.createDirectory(AppConstants.videoDirectory);
      final fileName = await FileUtils.generateUniqueFileName('mp4');
      final newPath = '${videoDir.path}/$fileName';
      
      await File(video.path).copy(newPath);
      return newPath;
    } catch (e) {
      print('Error stopping video recording: $e');
      return null;
    }
  }

  void dispose() {
    _controller?.dispose();
  }
}