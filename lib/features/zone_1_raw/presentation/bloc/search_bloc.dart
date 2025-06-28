import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/note.dart';
import '../../domain/usecases/search_notes.dart';

// Events
abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchNotesEvent extends SearchEvent {
  final String query;

  const SearchNotesEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class ClearSearchEvent extends SearchEvent {}

// States
abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<Note> notes;
  final String query;

  const SearchLoaded(this.notes, this.query);

  @override
  List<Object?> get props => [notes, query];
}

class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchNotes _searchNotes;

  SearchBloc({
    required SearchNotes searchNotes,
  })  : _searchNotes = searchNotes,
        super(SearchInitial()) {
    on<SearchNotesEvent>(_onSearchNotes);
    on<ClearSearchEvent>(_onClearSearch);
  }

  Future<void> _onSearchNotes(
    SearchNotesEvent event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading());
    
    final result = await _searchNotes(SearchNotesParams(event.query));
    
    result.fold(
      (failure) => emit(SearchError(failure.message)),
      (notes) => emit(SearchLoaded(notes, event.query)),
    );
  }

  void _onClearSearch(
    ClearSearchEvent event,
    Emitter<SearchState> emit,
  ) {
    emit(SearchInitial());
  }
}