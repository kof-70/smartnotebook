# Smart Notebook - Supabase Setup Guide

## Configuration Required

### 1. Supabase Project Setup

1. Create a new project at [supabase.com](https://supabase.com)
2. Go to Settings > API to get your project URL and anon key
3. Update `lib/core/config/supabase_config.dart` with your credentials:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 2. Database Setup

Run the migration file `supabase/migrations/20250628094455_rough_art.sql` in your Supabase SQL editor to create the required tables and policies.

### 3. Storage Setup

1. Go to Storage in your Supabase dashboard
2. Create two buckets:
   - `notes-media` (for user media files)
   - `profiles` (for profile pictures)
3. Make both buckets public
4. The storage policies are automatically created by the migration

### 4. Authentication Setup

#### Google Sign-In
1. Go to Authentication > Providers in your Supabase dashboard
2. Enable Google provider
3. Get your Google OAuth credentials from [Google Cloud Console](https://console.cloud.google.com)
4. Add the credentials to Supabase

#### Apple Sign-In (iOS)
1. Enable Apple provider in Supabase
2. Configure your Apple Developer account
3. Update the bundle ID in the Apple Sign-In configuration

### 5. Environment Variables

Create a `.env` file in your project root:

```
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

### 6. Platform Configuration

#### Android
Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<activity
    android:name="com.linusu.flutter_web_auth_2.CallbackActivity"
    android:exported="true">
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="io.supabase.smartnotebook" />
    </intent-filter>
</activity>
```

#### iOS
Add to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>io.supabase.smartnotebook</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>io.supabase.smartnotebook</string>
        </array>
    </dict>
</array>
```

## Features Implemented

✅ **Authentication**
- Google Sign-In
- Apple Sign-In (iOS)
- Automatic profile creation
- Session management

✅ **Database Schema**
- User profiles
- Notes with full metadata
- Media files tracking
- Tags system
- Row Level Security (RLS)

✅ **Synchronization**
- Real-time sync with Supabase
- Conflict resolution
- Offline support

✅ **Media Storage**
- Supabase Storage integration
- Automatic file upload/download
- Local caching for offline access
- Thumbnail generation support
- Media metadata tracking

## Media Storage Features

### 🎯 **Smart Media Handling**

1. **Hybrid Storage Strategy**
   - Files stored both locally and in Supabase Storage
   - Local files for offline access
   - Cloud files for cross-device sync

2. **Automatic Upload/Download**
   - Media files automatically uploaded when online
   - Downloaded to local storage when accessed
   - Background sync for seamless experience

3. **Storage Organization**
   - Files organized by user ID and media type
   - Path structure: `userId/mediaType/filename`
   - Automatic cleanup of orphaned files

4. **Media Types Supported**
   - Images (JPG, PNG, etc.)
   - Audio files (M4A, MP3, etc.)
   - Video files (MP4, MOV, etc.)
   - Generic file attachments

### 🔧 **Storage Configuration**

The app uses two Supabase Storage buckets:

1. **`notes-media`**: For all note attachments
   - Images, audio, video files
   - Organized by user and media type
   - Public access with RLS policies

2. **`profiles`**: For user profile pictures
   - Avatar images
   - Profile-related media

### 📱 **User Experience**

- **Seamless Sync**: Media files sync automatically between devices
- **Offline Access**: Files cached locally for offline viewing
- **Smart Previews**: Rich media previews with playback controls
- **Storage Management**: Automatic cleanup and optimization

## Next Steps

1. Configure your Supabase project with the provided schema
2. Create the storage buckets (`notes-media` and `profiles`)
3. Set up OAuth providers (Google, Apple)
4. Update configuration files with your credentials
5. Test authentication and media upload flows

## Data Synchronization

When a user signs in on a new device, their data will automatically sync from Supabase. The app handles:

- **Cross-device sync**: Notes and media created on one device appear on all devices
- **Offline support**: Local database and file storage with sync when online
- **Conflict resolution**: Last-write-wins strategy with version tracking
- **Real-time updates**: Changes sync immediately when online
- **Media optimization**: Automatic thumbnail generation and file compression

Users can safely switch devices and their complete data (including media files) will be preserved and synchronized across all their devices.

## Storage Costs

Supabase Storage pricing:
- 1GB free storage included
- Additional storage at competitive rates
- Bandwidth charges for file transfers
- Consider implementing file compression for cost optimization