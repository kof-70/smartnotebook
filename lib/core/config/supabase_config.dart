class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'YOUR_SUPABASE_URL_HERE',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY_HERE',
  );
  
  // OAuth redirect URLs
  static const String authRedirectUrl = 'io.supabase.smartnotebook://login-callback/';
  
  // Storage bucket names
  static const String notesBucket = 'notes-media';
  static const String profilesBucket = 'profiles';
}