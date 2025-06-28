import 'package:flutter/material.dart';
import 'dart:io';

import '../../../../core/utils/file_utils.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/audio_service.dart';
import '../../../../injection_container.dart' as di;

class MediaPreviewWidget extends StatefulWidget {
  final String mediaPath;
  final VoidCallback? onDelete;
  final bool showControls;

  const MediaPreviewWidget({
    super.key,
    required this.mediaPath,
    this.onDelete,
    this.showControls = true,
  });

  @override
  State<MediaPreviewWidget> createState() => _MediaPreviewWidgetState();
}

class _MediaPreviewWidgetState extends State<MediaPreviewWidget> {
  final AudioService _audioService = di.sl<AudioService>();
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(AppConstants.spacing8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: _buildMediaContent(theme),
      ),
    );
  }

  Widget _buildMediaContent(ThemeData theme) {
    if (FileUtils.isImageFile(widget.mediaPath)) {
      return _buildImagePreview(theme);
    } else if (FileUtils.isAudioFile(widget.mediaPath)) {
      return _buildAudioPreview(theme);
    } else if (FileUtils.isVideoFile(widget.mediaPath)) {
      return _buildVideoPreview(theme);
    } else {
      return _buildGenericFilePreview(theme);
    }
  }

  Widget _buildImagePreview(ThemeData theme) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: _isRemoteUrl(widget.mediaPath)
              ? Image.network(
                  widget.mediaPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildErrorPlaceholder(theme, Icons.image);
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _buildLoadingPlaceholder(theme);
                  },
                )
              : Image.file(
                  File(widget.mediaPath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildErrorPlaceholder(theme, Icons.image);
                  },
                ),
        ),
        if (widget.showControls) _buildControlsOverlay(theme),
      ],
    );
  }

  Widget _buildAudioPreview(ThemeData theme) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(AppConstants.spacing16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.audiotrack,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          
          const SizedBox(width: AppConstants.spacing12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  FileUtils.getFileName(widget.mediaPath),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                FutureBuilder<int>(
                  future: FileUtils.getFileSize(widget.mediaPath),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        FileUtils.formatFileSize(snapshot.data!),
                        style: theme.textTheme.bodySmall,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          
          if (widget.showControls) ...[
            if (_isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                onPressed: _toggleAudioPlayback,
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              ),
            
            if (widget.onDelete != null)
              IconButton(
                onPressed: widget.onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoPreview(ThemeData theme) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: theme.colorScheme.surfaceVariant,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: AppConstants.spacing8),
                Text(
                  FileUtils.getFileName(widget.mediaPath),
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        if (widget.showControls) _buildControlsOverlay(theme),
      ],
    );
  }

  Widget _buildGenericFilePreview(ThemeData theme) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(AppConstants.spacing16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.attachment,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          
          const SizedBox(width: AppConstants.spacing12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  FileUtils.getFileName(widget.mediaPath),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                FutureBuilder<int>(
                  future: FileUtils.getFileSize(widget.mediaPath),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        FileUtils.formatFileSize(snapshot.data!),
                        style: theme.textTheme.bodySmall,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          
          if (widget.showControls && widget.onDelete != null)
            IconButton(
              onPressed: widget.onDelete,
              icon: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay(ThemeData theme) {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (FileUtils.isImageFile(widget.mediaPath))
              IconButton(
                onPressed: _showFullScreenImage,
                icon: const Icon(
                  Icons.fullscreen,
                  color: Colors.white,
                ),
              ),
            
            if (widget.onDelete != null)
              IconButton(
                onPressed: widget.onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(ThemeData theme, IconData icon) {
    return Container(
      color: theme.colorScheme.errorContainer,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceVariant,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  bool _isRemoteUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  Future<void> _toggleAudioPlayback() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isPlaying) {
        await _audioService.pauseAudio();
        setState(() {
          _isPlaying = false;
        });
      } else {
        await _audioService.playAudio(widget.mediaPath);
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      print('Error toggling audio playback: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showFullScreenImage() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: _isRemoteUrl(widget.mediaPath)
                    ? Image.network(
                        widget.mediaPath,
                        fit: BoxFit.contain,
                      )
                    : Image.file(
                        File(widget.mediaPath),
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
}