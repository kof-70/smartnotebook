import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:io';

import '../../domain/entities/note.dart';
import '../bloc/note_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/permission_utils.dart';
import '../../../../shared/services/camera_service.dart';
import '../../../../injection_container.dart' as di;

class VideoNoteRecorderPage extends StatefulWidget {
  const VideoNoteRecorderPage({super.key});

  @override
  State<VideoNoteRecorderPage> createState() => _VideoNoteRecorderPageState();
}

class _VideoNoteRecorderPageState extends State<VideoNoteRecorderPage>
    with TickerProviderStateMixin {
  final CameraService _cameraService = di.sl<CameraService>();
  final _titleController = TextEditingController();
  
  CameraController? _controller;
  bool _isRecording = false;
  bool _hasRecording = false;
  String? _videoPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;
  
  late AnimationController _recordingController;

  @override
  void initState() {
    super.initState();
    _recordingController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _initializeCamera();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recordingController.dispose();
    _titleController.dispose();
    _controller?.dispose();
    _cameraService.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final hasPermission = await PermissionUtils.requestCameraPermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required')),
      );
      return;
    }

    try {
      _controller = await _cameraService.initializeCamera();
      if (_controller != null && mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocListener<NoteBloc, NoteState>(
      listener: (context, state) {
        if (state is NoteCreated) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video note saved successfully')),
          );
        } else if (state is NoteError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving note: ${state.message}'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: const Text('Video Note'),
          actions: [
            if (_hasRecording)
              TextButton(
                onPressed: _saveNote,
                child: const Text('Save', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        body: Column(
          children: [
            // Title input
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacing16),
              child: TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Video note title (optional)...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            
            // Camera preview or video preview
            Expanded(
              child: _buildCameraPreview(),
            ),
            
            // Controls
            Container(
              padding: const EdgeInsets.all(AppConstants.spacing24),
              child: Column(
                children: [
                  // Recording duration
                  if (_isRecording || _hasRecording)
                    Text(
                      _formatDuration(_recordingDuration),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  
                  const SizedBox(height: AppConstants.spacing24),
                  
                  // Control buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (_hasRecording && !_isRecording) ...[
                        // Play button
                        IconButton(
                          onPressed: _playVideo,
                          icon: const Icon(Icons.play_arrow, color: Colors.white),
                          iconSize: 32,
                        ),
                        
                        // Delete button
                        IconButton(
                          onPressed: _deleteVideo,
                          icon: const Icon(Icons.delete_outline, color: Colors.white),
                          iconSize: 32,
                        ),
                      ],
                      
                      // Record/Stop button
                      AnimatedBuilder(
                        animation: _recordingController,
                        builder: (context, child) {
                          return GestureDetector(
                            onTap: _toggleRecording,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isRecording ? Colors.red : Colors.white,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                              ),
                              child: Icon(
                                _isRecording ? Icons.stop : Icons.videocam,
                                size: 32,
                                color: _isRecording ? Colors.white : Colors.black,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      if (!_hasRecording && !_isRecording) ...[
                        // Placeholder buttons for symmetry
                        const SizedBox(width: 48),
                        const SizedBox(width: 48),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: AppConstants.spacing16),
                  
                  Text(
                    _isRecording 
                        ? 'Recording...'
                        : _hasRecording 
                            ? 'Tap to record again'
                            : 'Tap to start recording',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_hasRecording && _videoPath != null) {
      // Show video thumbnail or preview
      return Container(
        margin: const EdgeInsets.all(AppConstants.spacing16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          color: Colors.grey[900],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_library,
                size: 64,
                color: Colors.white.withOpacity(0.7),
              ),
              const SizedBox(height: AppConstants.spacing16),
              Text(
                'Video recorded',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: CameraPreview(_controller!),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      await _cameraService.startVideoRecording();
      
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });
      
      _recordingController.forward();
      
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration = Duration(seconds: timer.tick);
        });
      });
    } catch (e) {
      print('Error starting video recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      final videoPath = await _cameraService.stopVideoRecording();
      
      _timer?.cancel();
      _recordingController.reverse();
      
      setState(() {
        _isRecording = false;
        _hasRecording = videoPath != null;
        _videoPath = videoPath;
      });
    } catch (e) {
      print('Error stopping video recording: $e');
    }
  }

  void _playVideo() {
    if (_videoPath != null) {
      // TODO: Implement video playback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video playback not implemented yet')),
      );
    }
  }

  void _deleteVideo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Video'),
        content: const Text('Are you sure you want to delete this video?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _hasRecording = false;
                _videoPath = null;
                _recordingDuration = Duration.zero;
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _saveNote() {
    if (!_hasRecording || _videoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No video to save')),
      );
      return;
    }

    final title = _titleController.text.trim();
    
    context.read<NoteBloc>().add(CreateNoteEvent(
      title: title.isEmpty ? 'Video Note ${DateTime.now().day}/${DateTime.now().month}' : title,
      content: 'Video recording (${_formatDuration(_recordingDuration)})',
      type: NoteType.video,
      mediaFiles: [_videoPath!],
    ));
  }
}