import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/note.dart';
import '../bloc/note_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_utils.dart';

class TextNoteEditorPage extends StatefulWidget {
  final Note? existingNote;

  const TextNoteEditorPage({
    super.key,
    this.existingNote,
  });

  @override
  State<TextNoteEditorPage> createState() => _TextNoteEditorPageState();
}

class _TextNoteEditorPageState extends State<TextNoteEditorPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();
  final List<String> _tags = [];
  final _tagController = TextEditingController();
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingNote != null) {
      _titleController.text = widget.existingNote!.title;
      _contentController.text = widget.existingNote!.content;
      _tags.addAll(widget.existingNote!.tags);
    }
    
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocListener<NoteBloc, NoteState>(
      listener: (context, state) {
        if (state is NoteCreated || state is NoteUpdated) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note saved successfully')),
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
      child: PopScope(
        canPop: !_hasUnsavedChanges,
        onPopInvoked: (didPop) {
          if (!didPop && _hasUnsavedChanges) {
            _showUnsavedChangesDialog();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.existingNote != null ? 'Edit Note' : 'New Text Note'),
            actions: [
              if (_hasUnsavedChanges)
                TextButton(
                  onPressed: _saveNote,
                  child: const Text('Save'),
                ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'tags':
                      _showTagsDialog();
                      break;
                    case 'info':
                      _showNoteInfo();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'tags',
                    child: Row(
                      children: [
                        Icon(Icons.label_outline),
                        SizedBox(width: 8),
                        Text('Manage Tags'),
                      ],
                    ),
                  ),
                  if (widget.existingNote != null)
                    const PopupMenuItem(
                      value: 'info',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline),
                          SizedBox(width: 8),
                          Text('Note Info'),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              if (_tags.isNotEmpty) _buildTagsSection(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacing16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        decoration: const InputDecoration(
                          hintText: 'Note title...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: theme.textTheme.titleLarge,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: AppConstants.spacing16),
                      Expanded(
                        child: TextField(
                          controller: _contentController,
                          focusNode: _contentFocusNode,
                          decoration: const InputDecoration(
                            hintText: 'Start writing...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: theme.textTheme.bodyLarge,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: _hasUnsavedChanges
              ? FloatingActionButton(
                  onPressed: _saveNote,
                  child: const Icon(Icons.save),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Wrap(
        spacing: AppConstants.spacing8,
        runSpacing: AppConstants.spacing4,
        children: _tags.map((tag) => _buildTagChip(tag)).toList(),
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    final theme = Theme.of(context);
    
    return Chip(
      label: Text(tag),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: () {
        setState(() {
          _tags.remove(tag);
          _hasUnsavedChanges = true;
        });
      },
      backgroundColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: theme.colorScheme.onPrimaryContainer,
        fontSize: 12,
      ),
    );
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    
    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a title or content')),
      );
      return;
    }

    if (widget.existingNote != null) {
      // Update existing note
      final updatedNote = widget.existingNote!.copyWith(
        title: title.isEmpty ? 'Untitled' : title,
        content: content,
        tags: _tags,
        updatedAt: AppDateUtils.toIsoString(DateTime.now()),
      );
      
      context.read<NoteBloc>().add(UpdateNoteEvent(updatedNote));
    } else {
      // Create new note
      context.read<NoteBloc>().add(CreateNoteEvent(
        title: title.isEmpty ? 'Untitled' : title,
        content: content,
        type: NoteType.text,
        tags: _tags,
      ));
    }
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to save before leaving?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _saveNote();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showTagsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Tags'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _tagController,
              decoration: const InputDecoration(
                hintText: 'Add a tag...',
                prefixIcon: Icon(Icons.label_outline),
              ),
              onSubmitted: _addTag,
            ),
            const SizedBox(height: AppConstants.spacing16),
            if (_tags.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Current tags:'),
              ),
              const SizedBox(height: AppConstants.spacing8),
              Wrap(
                spacing: AppConstants.spacing8,
                children: _tags.map((tag) => _buildTagChip(tag)).toList(),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
          if (_tagController.text.trim().isNotEmpty)
            ElevatedButton(
              onPressed: () => _addTag(_tagController.text),
              child: const Text('Add'),
            ),
        ],
      ),
    );
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim().toLowerCase();
    if (trimmedTag.isNotEmpty && !_tags.contains(trimmedTag)) {
      setState(() {
        _tags.add(trimmedTag);
        _hasUnsavedChanges = true;
      });
      _tagController.clear();
    }
  }

  void _showNoteInfo() {
    final note = widget.existingNote;
    if (note == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Note Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Created', AppDateUtils.formatForDisplay(
              AppDateUtils.fromIsoString(note.createdAt),
            )),
            _buildInfoRow('Modified', AppDateUtils.formatForDisplay(
              AppDateUtils.fromIsoString(note.updatedAt),
            )),
            _buildInfoRow('Type', note.type.name.toUpperCase()),
            _buildInfoRow('Sync Status', note.syncStatus.toUpperCase()),
            if (note.isEncrypted)
              _buildInfoRow('Security', 'Encrypted'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}