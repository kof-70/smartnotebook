import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Core
import 'core/network/network_info.dart';
import 'core/security/encryption_service.dart';
import 'core/security/biometric_service.dart';
import 'core/config/supabase_config.dart';

// Shared
import 'shared/data/database/app_database.dart';
import 'shared/data/preferences/app_preferences.dart';
import 'shared/services/audio_service.dart';
import 'shared/services/camera_service.dart';
import 'shared/services/file_service.dart';
import 'shared/services/background_service.dart';

// Auth
import 'features/auth/data/datasources/auth_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/sign_in_with_google.dart';
import 'features/auth/domain/usecases/sign_in_with_apple.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/domain/usecases/get_current_user.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

// Zone 1 - Raw Me
import 'features/zone_1_raw/data/datasources/local_note_datasource.dart';
import 'features/zone_1_raw/data/datasources/supabase_media_datasource.dart';
import 'features/zone_1_raw/data/repositories/note_repository_impl.dart';
import 'features/zone_1_raw/domain/repositories/note_repository.dart';
import 'features/zone_1_raw/domain/usecases/create_note.dart';
import 'features/zone_1_raw/domain/usecases/get_notes.dart';
import 'features/zone_1_raw/domain/usecases/update_note.dart';
import 'features/zone_1_raw/domain/usecases/delete_note.dart';
import 'features/zone_1_raw/domain/usecases/search_notes.dart';
import 'features/zone_1_raw/domain/usecases/record_audio.dart';
import 'features/zone_1_raw/presentation/bloc/note_bloc.dart';
import 'features/zone_1_raw/presentation/bloc/search_bloc.dart';

// Zone 2 - Enhanced Me
import 'features/zone_2_enhanced/data/datasources/ai_api_datasource.dart';
import 'features/zone_2_enhanced/data/repositories/ai_repository_impl.dart';
import 'features/zone_2_enhanced/domain/repositories/ai_repository.dart';
import 'features/zone_2_enhanced/domain/usecases/analyze_notes.dart';
import 'features/zone_2_enhanced/domain/usecases/text_to_speech.dart';
import 'features/zone_2_enhanced/domain/usecases/chat_with_ai.dart';
import 'features/zone_2_enhanced/domain/usecases/generate_tags.dart';
import 'features/zone_2_enhanced/presentation/bloc/ai_chat_bloc.dart';

// Sync
import 'features/sync/data/datasources/sync_datasource.dart';
import 'features/sync/data/datasources/supabase_sync_datasource.dart';
import 'features/sync/data/repositories/sync_repository_impl.dart';
import 'features/sync/domain/repositories/sync_repository.dart';
import 'features/sync/domain/usecases/sync_data.dart';
import 'features/sync/presentation/bloc/sync_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // External dependencies
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton(() => Supabase.instance.client);
  sl.registerLazySingleton(() => GoogleSignIn(
    scopes: ['email', 'profile'],
  ));

  // Core
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl()),
  );
  sl.registerLazySingleton<EncryptionService>(
    () => EncryptionService(secureStorage: sl()),
  );
  sl.registerLazySingleton<BiometricService>(
    () => BiometricService(),
  );

  // Database
  final database = await $FloorAppDatabase.databaseBuilder('app_database.db').build();
  sl.registerSingleton<AppDatabase>(database);

  // Shared services
  sl.registerLazySingleton<AppPreferences>(
    () => AppPreferences(),
  );
  sl.registerLazySingleton<AudioService>(
    () => AudioService(),
  );
  sl.registerLazySingleton<CameraService>(
    () => CameraService(),
  );
  sl.registerLazySingleton<FileService>(
    () => FileService(encryptionService: sl()),
  );

  // Auth
  sl.registerLazySingleton<AuthDataSource>(
    () => SupabaseAuthDataSource(
      supabase: sl(),
      googleSignIn: sl(),
    ),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      authDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Auth Use cases
  sl.registerLazySingleton(() => SignInWithGoogle(sl()));
  sl.registerLazySingleton(() => SignInWithApple(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));

  // Auth Bloc
  sl.registerFactory(
    () => AuthBloc(
      signInWithGoogle: sl(),
      signInWithApple: sl(),
      signOut: sl(),
      getCurrentUser: sl(),
    ),
  );

  // Zone 1 - Raw Me
  sl.registerLazySingleton<LocalNoteDataSource>(
    () => LocalNoteDataSourceImpl(database: sl()),
  );
  sl.registerLazySingleton<SupabaseMediaDataSource>(
    () => SupabaseMediaDataSource(
      supabase: sl(),
      fileService: sl(),
    ),
  );
  sl.registerLazySingleton<NoteRepository>(
    () => NoteRepositoryImpl(
      localDataSource: sl(),
      mediaDataSource: sl(),
      networkInfo: sl(),
      syncDataSource: sl(),
    ),
  );

  // Zone 1 Use cases
  sl.registerLazySingleton(() => CreateNote(sl()));
  sl.registerLazySingleton(() => GetNotes(sl()));
  sl.registerLazySingleton(() => UpdateNote(sl()));
  sl.registerLazySingleton(() => DeleteNote(sl()));
  sl.registerLazySingleton(() => SearchNotes(sl()));
  sl.registerLazySingleton(() => RecordAudio(sl(), sl()));

  // Zone 1 Blocs
  sl.registerFactory(
    () => NoteBloc(
      createNote: sl(),
      getNotes: sl(),
      updateNote: sl(),
      deleteNote: sl(),
    ),
  );
  sl.registerFactory(
    () => SearchBloc(
      searchNotes: sl(),
    ),
  );

  // Zone 2 - Enhanced Me
  sl.registerLazySingleton<AIApiDataSource>(
    () => GPTDataSource(
      dio: sl(),
      secureStorage: sl(),
    ),
  );
  sl.registerLazySingleton<AIRepository>(
    () => AIRepositoryImpl(
      apiDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Zone 2 Use cases
  sl.registerLazySingleton(() => AnalyzeNotes(sl()));
  sl.registerLazySingleton(() => TextToSpeech(sl()));
  sl.registerLazySingleton(() => ChatWithAI(sl()));
  sl.registerLazySingleton(() => GenerateTags(sl()));

  // Zone 2 Blocs
  sl.registerFactory(
    () => AIChatBloc(
      analyzeNotes: sl(),
      textToSpeech: sl(),
      chatWithAI: sl(),
      generateTags: sl(),
      audioService: sl(),
    ),
  );

  // Sync
  sl.registerLazySingleton<SupabaseSyncDataSource>(
    () => SupabaseSyncDataSource(
      supabase: sl(),
      database: sl(),
      preferences: sl(),
    ),
  );
  sl.registerLazySingleton<SyncRepository>(
    () => SyncRepositoryImpl(
      syncDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Sync Use cases
  sl.registerLazySingleton(() => SyncData(sl()));

  // Sync Blocs
  sl.registerFactory(
    () => SyncBloc(
      syncData: sl(),
    ),
  );

  // Background Service
  sl.registerLazySingleton<BackgroundService>(
    () => BackgroundService(
      syncRepository: sl(),
      aiRepository: sl(),
      noteRepository: sl(),
    ),
  );

  // Initialize encryption service
  await sl<EncryptionService>().initialize();
}