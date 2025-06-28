import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

import '../../domain/entities/note.dart';
import '../bloc/note_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/permission_utils.dart';
import '../../../../shared/services/audio_service.dart';
import '../../../../injection_container.dart' as di;

class VoiceNoteRecorderPage extends StatefulWidget {
  const VoiceNoteRecorderPage({super.key});

  @override
  State<VoiceNoteRecorderPage> createState() => _VoiceNoteRecorderPageState();
}

class _VoiceNoteRecorderPageState extends State<VoiceNoteRecorderPage>
    with TickerProviderStateMixin {
  final AudioService _audioService = di.sl<AudioService>();
  final _titleController = TextEditingController();
  
  bool _isRecording = false;
  bool _hasRecording = false;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _titleController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocListener<NoteBloc, NoteState>(
      listener: (context, state) {
        if (state is NoteCreated) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Voice note saved successfully')),
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
        appBar: AppBar(
          title: const Text('Voice Note'),
          actions: [
            if (_hasRecording)
              TextButton(
                onPressed: _saveNote,
                child: const Text('Save'),
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppConstants.spacing24),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Voice note title (optional)...',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              
              const SizedBox(height: AppConstants.spacing48),
              
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Recording duration
                    Text(
                      _formatDuration(_recordingDuration),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w300,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                    
                    const SizedBox(height: AppConstants.spacing48),
                    
                    // Recording button
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isRecording ? _pulseAnimation.value : 1.0,
                          child: GestureDetector(
                            onTap: _toggleRecording,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isRecording 
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.primary,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isRecording 
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.primary).withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isRecording ? Icons.stop : Icons.mic,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: AppConstants.spacing24),
                    
                    Text(
                      _isRecording 
                          ? 'Tap to stop recording'
                          : _hasRecording 
                              ? 'Tap to record again'
                              : 'Tap to start recording',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    
                    if (_hasRecording && !_isRecording) ...[
                      const SizedBox(height: AppConstants.spacing32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _playRecording,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _deleteRecording,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Delete'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
    final hasPermission = await PermissionUtils.requestMicrophonePermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required')),
      );
      return;
    }

    final recordingPath = await _audioService.startRecording();
    if (recordingPath != null) {
      setState(() {
        _isRecording = true;
        _recordingPath = recordingPath;
        _recordingDuration = Duration.zero;
      });
      
      _pulseController.repeat(reverse: true);
      
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration = Duration(seconds: timer.tick);
        });
      });
    }
  }

  Future<void> _stopRecording() async {
    final recordingPath = await _audioService.stopRecording();
    
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    
    setState(() {
      _isRecording = false;
      _hasRecording = recordingPath != null;
      _recordingPath = recordingPath;
    });
  }

  Future<void> _playRecording() async {
    if (_recordingPath != null) {
      await _audioService.playAudio(_recordingPath!);
    }
  }

  void _deleteRecording() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording'),
        content: const Text('Are you sure you want to delete this recording?'),
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
                _recordingPath = null;
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
    if (!_hasRecording || _recordingPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recording to save')),
      );
      return;
    }

    final title = _titleController.text.trim();
    
    context.read<NoteBloc>().add(CreateNoteEvent(
      title: title.isEmpty ? 'Voice Note ${DateTime.now().day}/${DateTime.now().month}' : title,
      content: 'Voice recording (${_formatDuration(_recordingDuration)})',
      type: NoteType.audio,
      mediaFiles: [_recordingPath!],
    ));
  }
}