import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/note_bloc.dart';
import '../widgets/note_card_widget.dart';
import '../widgets/create_note_fab.dart';
import '../pages/note_detail_page.dart';
import '../../../../core/constants/app_constants.dart';

class RawZonePage extends StatefulWidget {
  const RawZonePage({super.key});

  @override
  State<RawZonePage> createState() => _RawZonePageState();
}

class _RawZonePageState extends State<RawZonePage> {
  @override
  void initState() {
    super.initState();
    context.read<NoteBloc>().add(LoadNotesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<NoteBloc, NoteState>(
        builder: (context, state) {
          if (state is NoteLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (state is NoteError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: AppConstants.spacing16),
                  Text(
                    'Error loading notes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppConstants.spacing8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.spacing24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<NoteBloc>().add(LoadNotesEvent());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (state is NotesLoaded) {
            if (state.notes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.note_add_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppConstants.spacing16),
                    Text(
                      'No notes yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppConstants.spacing8),
                    Text(
                      'Tap the + button to create your first note',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            
            return RefreshIndicator(
              onRefresh: () async {
                context.read<NoteBloc>().add(LoadNotesEvent());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(AppConstants.spacing16),
                itemCount: state.notes.length,
                itemBuilder: (context, index) {
                  final note = state.notes[index];
                  return NoteCardWidget(
                    note: note,
                    onTap: () => _openNote(context, note),
                    onDelete: () => _deleteNote(context, note.id),
                  );
                },
              ),
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: const CreateNoteFab(),
    );
  }

  void _openNote(BuildContext context, note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteDetailPage(note: note),
      ),
    );
  }

  void _deleteNote(BuildContext context, String noteId) {
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
              context.read<NoteBloc>().add(DeleteNoteEvent(noteId));
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