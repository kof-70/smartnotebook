import 'package:workmanager/workmanager.dart';

import '../../features/sync/domain/repositories/sync_repository.dart';
import '../../features/zone_2_enhanced/domain/repositories/ai_repository.dart';
import '../../features/zone_1_raw/domain/repositories/note_repository.dart';
import '../../features/zone_1_raw/domain/usecases/get_notes.dart';
import '../../features/zone_2_enhanced/domain/usecases/analyze_notes.dart';
import '../../features/zone_2_enhanced/domain/usecases/generate_tags.dart';

class BackgroundService {
  final SyncRepository _syncRepository;
  final AIRepository _aiRepository;
  final NoteRepository _noteRepository;

  BackgroundService({
    required SyncRepository syncRepository,
    required AIRepository aiRepository,
    required NoteRepository noteRepository,
  })  : _syncRepository = syncRepository,
        _aiRepository = aiRepository,
        _noteRepository = noteRepository;

  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    // Schedule periodic sync
    await Workmanager().registerPeriodicTask(
      'sync-data',
      'syncData',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );

    // Schedule AI processing
    await Workmanager().registerPeriodicTask(
      'process-ai-queue',
      'processAIQueue',
      frequency: const Duration(minutes: 30),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  Future<void> performSync() async {
    try {
      print('Background sync started');
      
      final result = await _syncRepository.syncData();
      
      result.fold(
        (failure) {
          print('Background sync failed: ${failure.message}');
        },
        (success) {
          print('Background sync completed successfully');
        },
      );
    } catch (e) {
      print('Background sync failed with exception: $e');
    }
  }

  Future<void> processAIQueue() async {
    try {
      print('AI queue processing started');
      
      // Get all notes that need AI processing
      final notesResult = await _noteRepository.getNotes();
      
      await notesResult.fold(
        (failure) async {
          print('Failed to get notes for AI processing: ${failure.message}');
        },
        (notes) async {
          // Filter notes that need AI analysis (no ai_analysis field)
          final notesNeedingAnalysis = notes.where((note) => 
            note.aiAnalysis == null && note.content.isNotEmpty
          ).toList();
          
          print('Found ${notesNeedingAnalysis.length} notes needing AI analysis');
          
          // Process each note (limit to avoid API rate limits)
          final notesToProcess = notesNeedingAnalysis.take(5).toList();
          
          for (final note in notesToProcess) {
            try {
              // Generate AI analysis for the note
              final analysisResult = await _aiRepository.analyzeNotes(
                [note.id],
                '${note.title}\n${note.content}',
              );
              
              await analysisResult.fold(
                (failure) async {
                  print('Failed to analyze note ${note.id}: ${failure.message}');
                },
                (analysis) async {
                  // Update the note with AI analysis
                  final updatedNote = note.copyWith(
                    aiAnalysis: analysis.summary,
                    syncStatus: 'pending', // Mark for sync
                  );
                  
                  await _noteRepository.updateNote(updatedNote);
                  print('AI analysis completed for note: ${note.id}');
                },
              );
              
              // Add delay to respect API rate limits
              await Future.delayed(const Duration(seconds: 2));
              
            } catch (e) {
              print('Error processing note ${note.id}: $e');
            }
          }
          
          // Generate tags for notes that don't have any
          final notesNeedingTags = notes.where((note) => 
            note.tags.isEmpty && note.content.isNotEmpty
          ).take(3).toList();
          
          for (final note in notesNeedingTags) {
            try {
              final tagsResult = await _aiRepository.generateTags(
                '${note.title}\n${note.content}',
              );
              
              await tagsResult.fold(
                (failure) async {
                  print('Failed to generate tags for note ${note.id}: ${failure.message}');
                },
                (tags) async {
                  // Update the note with generated tags
                  final updatedNote = note.copyWith(
                    tags: tags,
                    syncStatus: 'pending', // Mark for sync
                  );
                  
                  await _noteRepository.updateNote(updatedNote);
                  print('Tags generated for note: ${note.id}');
                },
              );
              
              // Add delay to respect API rate limits
              await Future.delayed(const Duration(seconds: 2));
              
            } catch (e) {
              print('Error generating tags for note ${note.id}: $e');
            }
          }
        },
      );
      
      print('AI queue processing completed');
    } catch (e) {
      print('AI queue processing failed with exception: $e');
    }
  }

  Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('Background task executed: $task');
    return Future.value(true);
  });
}