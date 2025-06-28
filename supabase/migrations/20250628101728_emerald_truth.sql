/*
  # Smart Notebook Database Schema

  1. New Tables
    - `profiles`
      - `id` (uuid, primary key, references auth.users)
      - `email` (text)
      - `full_name` (text)
      - `avatar_url` (text)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
    - `notes`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references profiles)
      - `title` (text)
      - `content` (text)
      - `type` (text)
      - `tags` (jsonb)
      - `media_files` (jsonb)
      - `ai_analysis` (text)
      - `sync_status` (text)
      - `is_encrypted` (boolean)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
      - `version` (integer)
    - `media`
      - `id` (uuid, primary key)
      - `note_id` (uuid, references notes)
      - `user_id` (uuid, references profiles)
      - `type` (text)
      - `path` (text)
      - `name` (text)
      - `size` (integer)
      - `thumbnail` (text)
      - `duration` (integer)
      - `is_encrypted` (boolean)
      - `created_at` (timestamp)
    - `tags`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references profiles)
      - `name` (text)
      - `color` (text)
      - `usage_count` (integer)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users to manage their own data
    - Add storage policies for media files

  3. Functions and Triggers
    - Auto-create profile on user signup
    - Auto-update timestamps
*/

-- Drop existing policies if they exist to avoid conflicts
DO $$ 
BEGIN
  -- Drop profiles policies
  DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
  DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
  DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
  
  -- Drop notes policies
  DROP POLICY IF EXISTS "Users can view own notes" ON notes;
  DROP POLICY IF EXISTS "Users can insert own notes" ON notes;
  DROP POLICY IF EXISTS "Users can update own notes" ON notes;
  DROP POLICY IF EXISTS "Users can delete own notes" ON notes;
  
  -- Drop media policies
  DROP POLICY IF EXISTS "Users can view own media" ON media;
  DROP POLICY IF EXISTS "Users can insert own media" ON media;
  DROP POLICY IF EXISTS "Users can update own media" ON media;
  DROP POLICY IF EXISTS "Users can delete own media" ON media;
  
  -- Drop tags policies
  DROP POLICY IF EXISTS "Users can view own tags" ON tags;
  DROP POLICY IF EXISTS "Users can insert own tags" ON tags;
  DROP POLICY IF EXISTS "Users can update own tags" ON tags;
  DROP POLICY IF EXISTS "Users can delete own tags" ON tags;
  
  -- Drop storage policies
  DROP POLICY IF EXISTS "Users can upload their own media files" ON storage.objects;
  DROP POLICY IF EXISTS "Users can view their own media files" ON storage.objects;
  DROP POLICY IF EXISTS "Users can update their own media files" ON storage.objects;
  DROP POLICY IF EXISTS "Users can delete their own media files" ON storage.objects;
  DROP POLICY IF EXISTS "Users can upload their own profile files" ON storage.objects;
  DROP POLICY IF EXISTS "Users can view their own profile files" ON storage.objects;
  DROP POLICY IF EXISTS "Users can update their own profile files" ON storage.objects;
  DROP POLICY IF EXISTS "Users can delete their own profile files" ON storage.objects;
EXCEPTION
  WHEN undefined_object THEN
    NULL; -- Ignore if policies don't exist
END $$;

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  email text,
  full_name text,
  avatar_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create notes table
CREATE TABLE IF NOT EXISTS notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  title text NOT NULL DEFAULT '',
  content text NOT NULL DEFAULT '',
  type text NOT NULL DEFAULT 'text',
  tags jsonb DEFAULT '[]'::jsonb,
  media_files jsonb DEFAULT '[]'::jsonb,
  ai_analysis text,
  sync_status text DEFAULT 'pending',
  is_encrypted boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  version integer DEFAULT 1
);

-- Create media table
CREATE TABLE IF NOT EXISTS media (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  note_id uuid REFERENCES notes(id) ON DELETE CASCADE NOT NULL,
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  type text NOT NULL,
  path text NOT NULL,
  name text NOT NULL,
  size integer DEFAULT 0,
  thumbnail text,
  duration integer,
  is_encrypted boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Create tags table
CREATE TABLE IF NOT EXISTS tags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  name text NOT NULL,
  color text DEFAULT '#3B82F6',
  usage_count integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, name)
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE media ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;

-- Create policies for profiles
CREATE POLICY "profiles_select_own" ON profiles
  FOR SELECT TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "profiles_update_own" ON profiles
  FOR UPDATE TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "profiles_insert_own" ON profiles
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id);

-- Create policies for notes
CREATE POLICY "notes_select_own" ON notes
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "notes_insert_own" ON notes
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "notes_update_own" ON notes
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "notes_delete_own" ON notes
  FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- Create policies for media
CREATE POLICY "media_select_own" ON media
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "media_insert_own" ON media
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "media_update_own" ON media
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "media_delete_own" ON media
  FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- Create policies for tags
CREATE POLICY "tags_select_own" ON tags
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "tags_insert_own" ON tags
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "tags_update_own" ON tags
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "tags_delete_own" ON tags
  FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS notes_user_id_idx ON notes(user_id);
CREATE INDEX IF NOT EXISTS notes_created_at_idx ON notes(created_at DESC);
CREATE INDEX IF NOT EXISTS notes_updated_at_idx ON notes(updated_at DESC);
CREATE INDEX IF NOT EXISTS notes_type_idx ON notes(type);
CREATE INDEX IF NOT EXISTS notes_sync_status_idx ON notes(sync_status);

CREATE INDEX IF NOT EXISTS media_note_id_idx ON media(note_id);
CREATE INDEX IF NOT EXISTS media_user_id_idx ON media(user_id);
CREATE INDEX IF NOT EXISTS media_type_idx ON media(type);

CREATE INDEX IF NOT EXISTS tags_user_id_idx ON tags(user_id);
CREATE INDEX IF NOT EXISTS tags_name_idx ON tags(name);

-- Function to automatically create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, avatar_url)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name'),
    new.raw_user_meta_data->>'avatar_url'
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at on profiles
DROP TRIGGER IF EXISTS handle_profiles_updated_at ON profiles;
CREATE TRIGGER handle_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Trigger to update updated_at on notes
DROP TRIGGER IF EXISTS handle_notes_updated_at ON notes;
CREATE TRIGGER handle_notes_updated_at
  BEFORE UPDATE ON notes
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Create storage buckets if they don't exist
INSERT INTO storage.buckets (id, name, public) 
VALUES ('notes-media', 'notes-media', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('profiles', 'profiles', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for notes-media bucket
CREATE POLICY "storage_notes_media_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'notes-media' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "storage_notes_media_select" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'notes-media' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "storage_notes_media_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'notes-media' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "storage_notes_media_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'notes-media' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Storage policies for profiles bucket
CREATE POLICY "storage_profiles_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'profiles' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "storage_profiles_select" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'profiles' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "storage_profiles_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'profiles' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "storage_profiles_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'profiles' AND auth.uid()::text = (storage.foldername(name))[1]);