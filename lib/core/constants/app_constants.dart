class AppConstants {
  // App Info
  static const String appName = 'Smart Notebook';
  static const String appVersion = '1.0.0';
  
  // Database
  static const String databaseName = 'smart_notebook.db';
  static const int databaseVersion = 1;
  
  // File Paths
  static const String notesDirectory = 'notes';
  static const String audioDirectory = 'audio';
  static const String videoDirectory = 'video';
  static const String imagesDirectory = 'images';
  static const String syncDirectory = 'sync';
  static const String ttsDirectory = 'tts';
  
  // Sync
  static const int syncPort = 8080;
  static const String syncEndpoint = '/sync';
  static const Duration syncInterval = Duration(minutes: 15);
  
  // AI Processing
  static const Duration aiProcessingInterval = Duration(minutes: 30);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 5);
  
  // Audio
  static const int audioSampleRate = 44100;
  static const int audioBitRate = 128000;
  static const String audioFormat = 'm4a';
  
  // Video
  static const int videoQuality = 720;
  static const int videoBitRate = 2000000;
  
  // UI
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  
  // Spacing (8px system)
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;
}