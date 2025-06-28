import 'dart:io';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/file_utils.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<String?> startRecording() async {
    try {
      if (!await hasPermission()) {
        throw Exception('Microphone permission not granted');
      }

      const encoder = AudioEncoder.aacLc;
      const config = RecordConfig(
        encoder: encoder,
        bitRate: AppConstants.audioBitRate,
        sampleRate: AppConstants.audioSampleRate,
      );

      final fileName = await FileUtils.generateUniqueFileName(AppConstants.audioFormat);
      final audioDir = await FileUtils.createDirectory(AppConstants.audioDirectory);
      final recordPath = '${audioDir.path}/$fileName';

      await _recorder.start(config, path: recordPath);
      return recordPath;
    } catch (e) {
      print('Error starting recording: $e');
      return null;
    }
  }

  Future<String?> stopRecording() async {
    try {
      return await _recorder.stop();
    } catch (e) {
      print('Error stopping recording: $e');
      return null;
    }
  }

  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  Future<void> playAudio(String filePath) async {
    try {
      await _player.play(DeviceFileSource(filePath));
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<void> pauseAudio() async {
    try {
      await _player.pause();
    } catch (e) {
      print('Error pausing audio: $e');
    }
  }

  Future<void> stopAudio() async {
    try {
      await _player.stop();
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  Stream<PlayerState> get playerStateStream => _player.onPlayerStateChanged;

  Stream<Duration> get positionStream => _player.onPositionChanged;

  Future<Duration?> getAudioDuration(String filePath) async {
    try {
      await _player.setSource(DeviceFileSource(filePath));
      return await _player.getDuration();
    } catch (e) {
      print('Error getting audio duration: $e');
      return null;
    }
  }

  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}