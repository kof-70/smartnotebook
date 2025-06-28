import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/note.dart';
import '../../domain/usecases/create_note.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/update_note.dart';
import '../../domain/usecases/delete_note.dart';

// Events
abstract class NoteEvent extends Equatable {
  const NoteEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotesEvent extends NoteEvent {}

class CreateNoteEvent extends NoteEvent {
  final String title;
  final String content;
  final NoteType type;
  final List<String> tags;
  final List<String> mediaFiles;

  const CreateNoteEvent({
    required this.title,
    required this.content,
    required this.type,
    this.tags = const [],
    this.mediaFiles = const [],
  });

  @override
  List<Object?> get props => [title, content, type, tags, mediaFiles];
}

class UpdateNoteEvent extends NoteEvent {
  final Note note;

  const UpdateNoteEvent(this.note);

  @override
  List<Object?> get props => [note];
}

class DeleteNoteEvent extends NoteEvent {
  final String noteId;

  const DeleteNoteEvent(this.noteId);

  @override
  List<Object?> get props => [noteId];
}

// States
abstract class NoteState extends Equatable {
  const NoteState();

  @override
  List<Object?> get props => [];
}

class NoteInitial extends NoteState {}

class NoteLoading extends NoteState {}

class NotesLoaded extends NoteState {
  final List<Note> notes;

  const NotesLoaded(this.notes);

  @override
  List<Object?> get props => [notes];
}

class NoteCreated extends NoteState {
  final Note note;

  const NoteCreated(this.note);

  @override
  List<Object?> get props => [note];
}

class NoteUpdated extends NoteState {
  final Note note;

  const NoteUpdated(this.note);

  @override
  List<Object?> get props => [note];
}

class NoteDeleted extends NoteState {
  final String noteId;

  const NoteDeleted(this.noteId);

  @override
  List<Object?> get props => [noteId];
}

class NoteError extends NoteState {
  final String message;

  const NoteError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class NoteBloc extends Bloc<NoteEvent, NoteState> {
  final CreateNote _createNote;
  final GetNotes _getNotes;
  final UpdateNote _updateNote;
  final DeleteNote _deleteNote;

  NoteBloc({
    required CreateNote createNote,
    required GetNotes getNotes,
    required UpdateNote updateNote,
    required DeleteNote deleteNote,
  })  : _createNote = createNote,
        _getNotes = getNotes,
        _updateNote = updateNote,
        _deleteNote = deleteNote,
        super(NoteInitial()) {
    on<LoadNotesEvent>(_onLoadNotes);
    on<CreateNoteEvent>(_onCreateNote);
    on<UpdateNoteEvent>(_onUpdateNote);
    on<DeleteNoteEvent>(_onDeleteNote);
  }

  Future<void> _onLoadNotes(
    LoadNotesEvent event,
    Emitter<NoteState> emit,
  ) async {
    emit(NoteLoading());
    
    final result = await _getNotes(const GetNotesParams());
    
    result.fold(
      (failure) => emit(NoteError(failure.message)),
      (notes) => emit(NotesLoaded(notes)),
    );
  }

  Future<void> _onCreateNote(
    CreateNoteEvent event,
    Emitter<NoteState> emit,
  ) async {
    final result = await _createNote(CreateNoteParams(
      title: event.title,
      content: event.content,
      type: event.type,
      tags: event.tags,
      mediaFiles: event.mediaFiles,
    ));
    
    result.fold(
      (failure) => emit(NoteError(failure.message)),
      (note) {
        emit(NoteCreated(note));
        // Reload notes to show the new note
        add(LoadNotesEvent());
      },
    );
  }

  Future<void> _onUpdateNote(
    UpdateNoteEvent event,
    Emitter<NoteState> emit,
  ) async {
    final result = await _updateNote(UpdateNoteParams(event.note));
    
    result.fold(
      (failure) => emit(NoteError(failure.message)),
      (note) {
        emit(NoteUpdated(note));
        // Reload notes to show the updated note
        add(LoadNotesEvent());
      },
    );
  }

  Future<void> _onDeleteNote(
    DeleteNoteEvent event,
    Emitter<NoteState> emit,
  ) async {
    final result = await _deleteNote(DeleteNoteParams(event.noteId));
    
    result.fold(
      (failure) => emit(NoteError(failure.message)),
      (_) {
        emit(NoteDeleted(event.noteId));
        // Reload notes to reflect the deletion
        add(LoadNotesEvent());
      },
    );
  }
}