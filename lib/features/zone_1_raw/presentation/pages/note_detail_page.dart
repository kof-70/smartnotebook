import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

import '../../domain/entities/note.dart';
import '../bloc/note_bloc.dart';
import 'text_note_editor_page.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../shared/services/audio_service.dart';
import '../../../../injection_container.dart' as di;

class NoteDetailPage extends StatefulWidget {
  final Note note;

  const NoteDetailPage({
    super.key,
    required this.note,
  });

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  final AudioService _audioService = di.sl<AudioService>();
  bool _isPlaying = false;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void dispose() {
    _audioService.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note.title.isNotEmpty ? widget.note.title : 'Untitled'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editNote,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'share':
                  _shareNote();
                  break;
                case 'delete':
                  _deleteNote();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Share'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Note metadata
            _buildMetadataSection(theme),
            
            const SizedBox(height: AppConstants.spacing24),
            
            // Note content
            if (widget.note.content.isNotEmpty) ...[
              Text(
                widget.note.content,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: AppConstants.spacing24),
            ],
            
            // Media files
            if (widget.note.mediaFiles.isNotEmpty) ...[
              Text(
                'Attachments',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppConstants.spacing12),
              _buildMediaSection(),
            ],
            
            // AI Analysis
            if (widget.note.aiAnalysis != null) ...[
              const SizedBox(height: AppConstants.spacing24),
              _buildAIAnalysisSection(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildNoteTypeIcon(theme),
                const SizedBox(width: AppConstants.spacing8),
                Text(
                  widget.note.type.name.toUpperCase(),
                  style: theme.textTheme.labelMedium,
                ),
                const Spacer(),
                _buildSyncStatusIcon(theme),
              ],
            ),
            
            const SizedBox(height: AppConstants.spacing12),
            
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppConstants.spacing4),
                Text(
                  'Created ${AppDateUtils.formatForDisplay(
                    AppDateUtils.fromIsoString(widget.note.createdAt),
                  )}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            
            if (widget.note.createdAt != widget.note.updatedAt) ...[
              const SizedBox(height: AppConstants.spacing4),
              Row(
                children: [
                  Icon(
                    Icons.edit,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppConstants.spacing4),
                  Text(
                    'Modified ${AppDateUtils.formatForDisplay(
                      AppDateUtils.fromIsoString(widget.note.updatedAt),
                    )}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            
            // Tags
            if (widget.note.tags.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacing12),
              Wrap(
                spacing: AppConstants.spacing8,
                runSpacing: AppConstants.spacing4,
                children: widget.note.tags.map((tag) => _buildTag(theme, tag)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    return Column(
      children: widget.note.mediaFiles.map((mediaPath) {
        return _buildMediaItem(mediaPath);
      }).toList(),
    );
  }

  Widget _buildMediaItem(String mediaPath) {
    final theme = Theme.of(context);
    final file = File(mediaPath);
    final fileName = FileUtils.getFileName(mediaPath);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacing8),
      child: ListTile(
        leading: _buildMediaIcon(mediaPath),
        title: Text(fileName),
        subtitle: FutureBuilder<bool>(
          future: file.exists(),
          builder: (context, snapshot) {
            if (snapshot.data == true) {
              return FutureBuilder<int>(
                future: FileUtils.getFileSize(mediaPath),
                builder: (context, sizeSnapshot) {
                  if (sizeSnapshot.hasData) {
                    return Text(FileUtils.formatFileSize(sizeSnapshot.data!));
                  }
                  return const Text('Loading...');
                },
              );
            }
            return Text(
              'File not found',
              style: TextStyle(color: theme.colorScheme.error),
            );
          },
        ),
        trailing: _buildMediaActions(mediaPath),
        onTap: () => _openMedia(mediaPath),
      ),
    );
  }

  Widget _buildMediaIcon(String mediaPath) {
    final theme = Theme.of(context);
    
    if (FileUtils.isAudioFile(mediaPath)) {
      return Icon(Icons.audiotrack, color: theme.colorScheme.primary);
    } else if (FileUtils.isVideoFile(mediaPath)) {
      return Icon(Icons.videocam, color: theme.colorScheme.primary);
    } else if (FileUtils.isImageFile(mediaPath)) {
      return Icon(Icons.image, color: theme.colorScheme.primary);
    }
    
    return Icon(Icons.attachment, color: theme.colorScheme.primary);
  }

  Widget _buildMediaActions(String mediaPath) {
    if (FileUtils.isAudioFile(mediaPath)) {
      return IconButton(
        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
        onPressed: () => _toggleAudioPlayback(mediaPath),
      );
    }
    
    return const Icon(Icons.chevron_right);
  }

  Widget _buildAIAnalysisSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppConstants.spacing8),
                Text(
                  'AI Analysis',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacing12),
            Text(
              widget.note.aiAnalysis!,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteTypeIcon(ThemeData theme) {
    IconData icon;
    switch (widget.note.type) {
      case NoteType.audio:
        icon = Icons.mic;
        break;
      case NoteType.video:
        icon = Icons.videocam;
        break;
      case NoteType.image:
        icon = Icons.image;
        break;
      case NoteType.mixed:
        icon = Icons.collections;
        break;
      default:
        icon = Icons.text_snippet;
    }
    
    return Icon(
      icon,
      size: 20,
      color: theme.colorScheme.primary,
    );
  }

  Widget _buildSyncStatusIcon(ThemeData theme) {
    IconData icon;
    Color color;
    
    switch (widget.note.syncStatus) {
      case 'synced':
        icon = Icons.cloud_done;
        color = theme.colorScheme.primary;
        break;
      case 'syncing':
        icon = Icons.cloud_sync;
        color = theme.colorScheme.secondary;
        break;
      case 'error':
        icon = Icons.cloud_off;
        color = theme.colorScheme.error;
        break;
      default:
        icon = Icons.cloud_queue;
        color = theme.colorScheme.onSurfaceVariant;
    }
    
    return Icon(
      icon,
      size: 20,
      color: color,
    );
  }

  Widget _buildTag(ThemeData theme, String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacing8,
        vertical: AppConstants.spacing4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppConstants.spacing8),
      ),
      child: Text(
        tag,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _toggleAudioPlayback(String audioPath) async {
    if (_isPlaying) {
      await _audioService.pauseAudio();
      setState(() {
        _isPlaying = false;
      });
    } else {
      await _audioService.playAudio(audioPath);
      setState(() {
        _isPlaying = true;
      });
    }
  }

  void _openMedia(String mediaPath) {
    final file = File(mediaPath);
    
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File not found')),
      );
      return;
    }

    if (FileUtils.isImageFile(mediaPath)) {
      _showImageViewer(mediaPath);
    } else if (FileUtils.isAudioFile(mediaPath)) {
      _toggleAudioPlayback(mediaPath);
    } else if (FileUtils.isVideoFile(mediaPath)) {
      _showVideoPlayer(mediaPath);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot preview this file type')),
      );
    }
  }

  void _showImageViewer(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 30,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoPlayer(String videoPath) {
    showDialog(
      context: context,
      builder: (context) => VideoPlayerDialog(videoPath: videoPath),
    );
  }

  void _editNote() {
    if (widget.note.type == NoteType.text) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TextNoteEditorPage(existingNote: widget.note),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Editing this note type is not supported yet')),
      );
    }
  }

  void _shareNote() {
    String shareText = '';
    
    if (widget.note.title.isNotEmpty) {
      shareText += '${widget.note.title}\n\n';
    }
    
    if (widget.note.content.isNotEmpty) {
      shareText += widget.note.content;
    }
    
    if (widget.note.tags.isNotEmpty) {
      shareText += '\n\nTags: ${widget.note.tags.join(', ')}';
    }
    
    if (shareText.trim().isEmpty) {
      shareText = 'Shared from Smart Notebook';
    }
    
    Share.share(
      shareText,
      subject: widget.note.title.isNotEmpty ? widget.note.title : 'Note from Smart Notebook',
    );
  }

  void _deleteNote() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              context.read<NoteBloc>().add(DeleteNoteEvent(widget.note.id));
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
}

class VideoPlayerDialog extends StatefulWidget {
  final String videoPath;

  const VideoPlayerDialog({super.key, required this.videoPath});

  @override
  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.file(File(widget.videoPath));
    
    try {
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Video Player',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Video player
            Expanded(
              child: _isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
            ),
            
            // Controls
            if (_isInitialized) ...[
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (_isPlaying) {
                            _controller.pause();
                            _isPlaying = false;
                          } else {
                            _controller.play();
                            _isPlaying = true;
                          }
                        });
                      },
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    
                    Expanded(
                      child: VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Colors.white,
                          bufferedColor: Colors.grey,
                          backgroundColor: Colors.black26,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    ValueListenableBuilder(
                      valueListenable: _controller,
                      builder: (context, VideoPlayerValue value, child) {
                        final position = value.position;
                        final duration = value.duration;
                        
                        return Text(
                          '${_formatDuration(position)} / ${_formatDuration(duration)}',
                          style: const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
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
}