import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../domain/entities/note.dart';
import '../bloc/note_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/permission_utils.dart';
import '../../../../shared/services/camera_service.dart';
import '../../../../injection_container.dart' as di;

class PhotoNotCapturePage extends StatefulWidget {
  const PhotoNotCapturePage({super.key});

  @override
  State<PhotoNotCapturePage> createState() => _PhotoNotCapturePageState();
}

class _PhotoNotCapturePageState extends State<PhotoNotCapturePage> {
  final CameraService _cameraService = di.sl<CameraService>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  final List<String> _imagePaths = [];
  bool _isCapturing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cameraService.dispose();
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
            const SnackBar(content: Text('Photo note saved successfully')),
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
          title: const Text('Photo Note'),
          actions: [
            if (_imagePaths.isNotEmpty)
              TextButton(
                onPressed: _saveNote,
                child: const Text('Save'),
              ),
          ],
        ),
        body: Column(
          children: [
            // Form section
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacing16),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'Photo note title (optional)...',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: AppConstants.spacing12),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      hintText: 'Add a description...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
            ),
            
            // Images section
            if (_imagePaths.isNotEmpty) ...[
              Container(
                height: 200,
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacing16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imagePaths.length,
                  itemBuilder: (context, index) {
                    return _buildImageCard(_imagePaths[index], index);
                  },
                ),
              ),
              const SizedBox(height: AppConstants.spacing16),
            ],
            
            // Action buttons
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_imagePaths.isEmpty) ...[
                      Icon(
                        Icons.photo_camera,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: AppConstants.spacing16),
                      Text(
                        'Add photos to your note',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppConstants.spacing32),
                    ],
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          context,
                          icon: Icons.camera_alt,
                          label: 'Camera',
                          onPressed: () => _captureImage(ImageSource.camera),
                        ),
                        _buildActionButton(
                          context,
                          icon: Icons.photo_library,
                          label: 'Gallery',
                          onPressed: () => _captureImage(ImageSource.gallery),
                        ),
                      ],
                    ),
                    
                    if (_imagePaths.isNotEmpty) ...[
                      const SizedBox(height: AppConstants.spacing24),
                      OutlinedButton.icon(
                        onPressed: _pickMultipleImages,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Add More Photos'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(String imagePath, int index) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: AppConstants.spacing12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(imagePath),
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        ElevatedButton(
          onPressed: _isCapturing ? null : onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(24),
          ),
          child: Icon(icon, size: 32),
        ),
        const SizedBox(height: AppConstants.spacing8),
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Future<void> _captureImage(ImageSource source) async {
    setState(() {
      _isCapturing = true;
    });

    try {
      bool hasPermission = true;
      if (source == ImageSource.camera) {
        hasPermission = await PermissionUtils.requestCameraPermission();
      }

      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required')),
        );
        return;
      }

      final imagePath = await _cameraService.captureImage(source: source);
      if (imagePath != null) {
        setState(() {
          _imagePaths.add(imagePath);
        });
      }
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  Future<void> _pickMultipleImages() async {
    setState(() {
      _isCapturing = true;
    });

    try {
      final imagePaths = await _cameraService.pickMultipleImages();
      if (imagePaths.isNotEmpty) {
        setState(() {
          _imagePaths.addAll(imagePaths);
        });
      }
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  void _saveNote() {
    if (_imagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one photo')),
      );
      return;
    }

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    
    context.read<NoteBloc>().add(CreateNoteEvent(
      title: title.isEmpty ? 'Photo Note ${DateTime.now().day}/${DateTime.now().month}' : title,
      content: description.isEmpty ? '${_imagePaths.length} photo${_imagePaths.length > 1 ? 's' : ''}' : description,
      type: NoteType.image,
      mediaFiles: _imagePaths,
    ));
  }
}