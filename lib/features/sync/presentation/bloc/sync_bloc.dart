import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/usecases/sync_data.dart';
import '../../../zone_1_raw/domain/entities/note.dart';

// Events
abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

class StartSyncEvent extends SyncEvent {}

class CheckSyncStatusEvent extends SyncEvent {}

class RetryFailedSyncEvent extends SyncEvent {}

class EnableRealtimeSyncEvent extends SyncEvent {}

class DisableRealtimeSyncEvent extends SyncEvent {}

class SyncSpecificNoteEvent extends SyncEvent {
  final Note note;

  const SyncSpecificNoteEvent(this.note);

  @override
  List<Object?> get props => [note];
}

// States
abstract class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

class SyncInitial extends SyncState {}

class SyncInProgress extends SyncState {
  final double progress;
  final String? currentOperation;

  const SyncInProgress(this.progress, {this.currentOperation});

  @override
  List<Object?> get props => [progress, currentOperation];
}

class SyncCompleted extends SyncState {
  final DateTime lastSyncTime;
  final int syncedItems;

  const SyncCompleted(this.lastSyncTime, {this.syncedItems = 0});

  @override
  List<Object?> get props => [lastSyncTime, syncedItems];
}

class SyncError extends SyncState {
  final String message;
  final bool isRetryable;

  const SyncError(this.message, {this.isRetryable = true});

  @override
  List<Object?> get props => [message, isRetryable];
}

class SyncIdle extends SyncState {
  final DateTime? lastSyncTime;
  final bool hasChanges;
  final bool isRealtimeEnabled;

  const SyncIdle({
    this.lastSyncTime,
    this.hasChanges = false,
    this.isRealtimeEnabled = false,
  });

  @override
  List<Object?> get props => [lastSyncTime, hasChanges, isRealtimeEnabled];
}

class SyncConflictDetected extends SyncState {
  final List<Note> conflictingNotes;

  const SyncConflictDetected(this.conflictingNotes);

  @override
  List<Object?> get props => [conflictingNotes];
}

// Bloc
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SyncData _syncData;
  bool _isRealtimeEnabled = false;

  SyncBloc({
    required SyncData syncData,
  })  : _syncData = syncData,
        super(SyncInitial()) {
    on<StartSyncEvent>(_onStartSync);
    on<CheckSyncStatusEvent>(_onCheckSyncStatus);
    on<RetryFailedSyncEvent>(_onRetryFailedSync);
    on<EnableRealtimeSyncEvent>(_onEnableRealtimeSync);
    on<DisableRealtimeSyncEvent>(_onDisableRealtimeSync);
    on<SyncSpecificNoteEvent>(_onSyncSpecificNote);
  }

  Future<void> _onStartSync(
    StartSyncEvent event,
    Emitter<SyncState> emit,
  ) async {
    emit(const SyncInProgress(0.0, currentOperation: 'Initializing sync...'));
    
    try {
      emit(const SyncInProgress(0.2, currentOperation: 'Checking authentication...'));
      
      emit(const SyncInProgress(0.4, currentOperation: 'Uploading local changes...'));
      
      emit(const SyncInProgress(0.7, currentOperation: 'Downloading remote changes...'));
      
      final result = await _syncData(const SyncDataParams());
      
      emit(const SyncInProgress(0.9, currentOperation: 'Finalizing sync...'));
      
      result.fold(
        (failure) => emit(SyncError(failure.message)),
        (success) {
          emit(SyncCompleted(DateTime.now()));
          // After successful sync, check status
          add(CheckSyncStatusEvent());
        },
      );
    } catch (e) {
      emit(SyncError('Unexpected sync error: ${e.toString()}'));
    }
  }

  Future<void> _onCheckSyncStatus(
    CheckSyncStatusEvent event,
    Emitter<SyncState> emit,
  ) async {
    try {
      // This would check the actual sync status from the repository
      final lastSyncTime = DateTime.now().subtract(const Duration(hours: 1));
      const hasChanges = false; // This would be checked from the repository
      
      emit(SyncIdle(
        lastSyncTime: lastSyncTime,
        hasChanges: hasChanges,
        isRealtimeEnabled: _isRealtimeEnabled,
      ));
    } catch (e) {
      emit(SyncError('Failed to check sync status: ${e.toString()}'));
    }
  }

  Future<void> _onRetryFailedSync(
    RetryFailedSyncEvent event,
    Emitter<SyncState> emit,
  ) async {
    add(StartSyncEvent());
  }

  void _onEnableRealtimeSync(
    EnableRealtimeSyncEvent event,
    Emitter<SyncState> emit,
  ) {
    _isRealtimeEnabled = true;
    
    // Enable real-time subscriptions in the data source
    // This would be implemented in the repository/data source
    
    if (state is SyncIdle) {
      final currentState = state as SyncIdle;
      emit(SyncIdle(
        lastSyncTime: currentState.lastSyncTime,
        hasChanges: currentState.hasChanges,
        isRealtimeEnabled: true,
      ));
    }
  }

  void _onDisableRealtimeSync(
    DisableRealtimeSyncEvent event,
    Emitter<SyncState> emit,
  ) {
    _isRealtimeEnabled = false;
    
    // Disable real-time subscriptions in the data source
    
    if (state is SyncIdle) {
      final currentState = state as SyncIdle;
      emit(SyncIdle(
        lastSyncTime: currentState.lastSyncTime,
        hasChanges: currentState.hasChanges,
        isRealtimeEnabled: false,
      ));
    }
  }

  Future<void> _onSyncSpecificNote(
    SyncSpecificNoteEvent event,
    Emitter<SyncState> emit,
  ) async {
    try {
      emit(const SyncInProgress(0.5, currentOperation: 'Syncing note...'));
      
      // This would sync a specific note through the repository
      // For now, we'll simulate the operation
      await Future.delayed(const Duration(seconds: 1));
      
      emit(SyncCompleted(DateTime.now(), syncedItems: 1));
      
      // Return to idle state
      add(CheckSyncStatusEvent());
    } catch (e) {
      emit(SyncError('Failed to sync note: ${e.toString()}'));
    }
  }
}