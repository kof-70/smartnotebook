import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../pages/text_note_editor_page.dart';
import '../pages/voice_note_recorder_page.dart';
import '../pages/photo_note_capture_page.dart';
import '../pages/video_note_recorder_page.dart';

class CreateNoteFab extends StatelessWidget {
  const CreateNoteFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showCreateNoteOptions(context),
      child: const Icon(Icons.add),
    );
  }

  void _showCreateNoteOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.borderRadius),
        ),
      ),
      builder: (context) => const CreateNoteBottomSheet(),
    );
  }
}

class CreateNoteBottomSheet extends StatelessWidget {
  const CreateNoteBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppConstants.spacing24),
          
          Text(
            'Create New Note',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppConstants.spacing24),
          
          _buildOption(
            context,
            icon: Icons.text_snippet,
            title: 'Text Note',
            subtitle: 'Write your thoughts',
            onTap: () => _createTextNote(context),
          ),
          
          _buildOption(
            context,
            icon: Icons.mic,
            title: 'Voice Note',
            subtitle: 'Record audio',
            onTap: () => _createVoiceNote(context),
          ),
          
          _buildOption(
            context,
            icon: Icons.camera_alt,
            title: 'Photo Note',
            subtitle: 'Capture or select image',
            onTap: () => _createPhotoNote(context),
          ),
          
          _buildOption(
            context,
            icon: Icons.videocam,
            title: 'Video Note',
            subtitle: 'Record video',
            onTap: () => _createVideoNote(context),
          ),
          
          const SizedBox(height: AppConstants.spacing16),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppConstants.spacing12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppConstants.spacing12),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.spacing12),
      ),
    );
  }

  void _createTextNote(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TextNoteEditorPage(),
      ),
    );
  }

  void _createVoiceNote(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const VoiceNoteRecorderPage(),
      ),
    );
  }

  void _createPhotoNote(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PhotoNotCapturePage(),
      ),
    );
  }

  void _createVideoNote(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const VideoNoteRecorderPage(),
      ),
    );
  }
}