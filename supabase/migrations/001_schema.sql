-- Luna Supabase Schema
-- Run this in the Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- Profiles table
-- ============================================
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL DEFAULT 'Default',
  avatar_color TEXT,
  avatar_id INTEGER,
  profile_index INTEGER NOT NULL DEFAULT 0,
  uses_primary_addons BOOLEAN DEFAULT true,
  pin_enabled BOOLEAN DEFAULT false,
  role TEXT DEFAULT 'user',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_profiles_user_id ON profiles(user_id);

-- ============================================
-- Installed Addons table
-- ============================================
CREATE TABLE IF NOT EXISTS installed_addons (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  addon_url TEXT NOT NULL,
  addon_name TEXT,
  enabled BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(profile_id, addon_url)
);

CREATE INDEX idx_addons_profile_id ON installed_addons(profile_id);

-- ============================================
-- Watch Progress table
-- ============================================
CREATE TABLE IF NOT EXISTS watch_progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  media_id TEXT NOT NULL,
  media_type TEXT NOT NULL DEFAULT 'movie',
  position_seconds DOUBLE PRECISION DEFAULT 0,
  duration_seconds DOUBLE PRECISION DEFAULT 0,
  completed BOOLEAN DEFAULT false,
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(profile_id, media_id)
);

CREATE INDEX idx_wp_profile_id ON watch_progress(profile_id);
CREATE INDEX idx_wp_media_id ON watch_progress(media_id);

-- ============================================
-- Watched Items table
-- ============================================
CREATE TABLE IF NOT EXISTS watched_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  media_id TEXT NOT NULL,
  media_type TEXT NOT NULL DEFAULT 'movie',
  name TEXT,
  poster TEXT,
  season INTEGER,
  episode INTEGER,
  marked_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_wi_profile_id ON watched_items(profile_id);

-- ============================================
-- Library Items (Watchlist) table
-- ============================================
CREATE TABLE IF NOT EXISTS library_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  media_id TEXT NOT NULL,
  media_type TEXT NOT NULL DEFAULT 'movie',
  name TEXT,
  poster TEXT,
  banner TEXT,
  saved_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(profile_id, media_id)
);

CREATE INDEX idx_li_profile_id ON library_items(profile_id);

-- ============================================
-- Invite Codes table
-- ============================================
CREATE TABLE IF NOT EXISTS invite_codes (
  code TEXT PRIMARY KEY,
  created_by UUID REFERENCES auth.users(id),
  used_by UUID REFERENCES auth.users(id),
  used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  max_uses INTEGER DEFAULT 1,
  is_active BOOLEAN DEFAULT true
);

-- ============================================
-- App Settings table (per-profile settings)
-- ============================================
CREATE TABLE IF NOT EXISTS app_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  theme TEXT DEFAULT 'dark',
  player_resize_mode TEXT DEFAULT 'fit',
  default_playback_speed REAL DEFAULT 1.0,
  UNIQUE(profile_id)
);

-- ============================================
-- Row Level Security (RLS)
-- ============================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE installed_addons ENABLE ROW LEVEL SECURITY;
ALTER TABLE watch_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE watched_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE library_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE invite_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

-- Profiles: users can only see/update their own profiles
CREATE POLICY "Users can view own profiles"
  ON profiles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profiles"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own profiles"
  ON profiles FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own profiles"
  ON profiles FOR DELETE
  USING (auth.uid() = user_id);

-- Installed Addons: users can manage addons for their own profiles
CREATE POLICY "Users can view own addons"
  ON installed_addons FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = profile_id AND user_id = auth.uid()
  ));

CREATE POLICY "Users can insert own addons"
  ON installed_addons FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM profiles WHERE id = profile_id AND user_id = auth.uid()
  ));

CREATE POLICY "Users can update own addons"
  ON installed_addons FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = profile_id AND user_id = auth.uid()
  ));

CREATE POLICY "Users can delete own addons"
  ON installed_addons FOR DELETE
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = profile_id AND user_id = auth.uid()
  ));

-- Watch Progress: users manage their own progress
CREATE POLICY "Users can view own watch progress"
  ON watch_progress FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = profile_id AND user_id = auth.uid()
  ));

CREATE POLICY "Users can insert own watch progress"
  ON watch_progress FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM profiles WHERE id = profile_id AND user_id = auth.uid()
  ));

CREATE POLICY "Users can update own watch progress"
  ON watch_progress FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = profile_id AND user_id = auth.uid()
  ));

CREATE POLICY "Users can delete own watch progress"
  ON watch_progress FOR DELETE
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = profile_id AND user_id = auth.uid()
  ));

-- Watched Items
CREATE POLICY "Users can view own watched items"
  ON watched_items FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = profile_id AND user_id = auth.uid()
  ));

CREATE POLICY "Users can insert own watched items"
  ON watched_items FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM profiles WHERE id = profile_id AND user_id = auth.uid()
  ));

CREATE POLICY "Users can delete own watched items"
  ON watched_items FOR DELETE
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = profile_id AND user_id = auth.uid()
  ));

-- Library Items
CREATE POLICY "Users can view own library"
  ON library_items FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = profile_id AND user_id = auth.uid()
  ));

CREATE POLICY "Users can insert own library"
  ON library_items FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM profiles WHERE id = profile_id AND user_id = auth.uid()
  ));

CREATE POLICY "Users can update own library"
  ON library_items FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = profile_id AND user_id = auth.uid()
  ));

CREATE POLICY "Users can delete own library"
  ON library_items FOR DELETE
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = profile_id AND user_id = auth.uid()
  ));

-- Invite Codes: only admin can manage
CREATE POLICY "Admins can view invite codes"
  ON invite_codes FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM profiles
    WHERE user_id = auth.uid() AND role = 'admin'
  ));

CREATE POLICY "Admins can insert invite codes"
  ON invite_codes FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM profiles
    WHERE user_id = auth.uid() AND role = 'admin'
  ));

CREATE POLICY "Admins can update invite codes"
  ON invite_codes FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM profiles
    WHERE user_id = auth.uid() AND role = 'admin'
  ));

-- Allow public to validate invite codes (for signup)
CREATE POLICY "Anyone can read invite codes for validation"
  ON invite_codes FOR SELECT
  USING (true);

-- App Settings
CREATE POLICY "Users can view own settings"
  ON app_settings FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = profile_id AND user_id = auth.uid()
  ));

CREATE POLICY "Users can insert own settings"
  ON app_settings FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM profiles WHERE id = profile_id AND user_id = auth.uid()
  ));

CREATE POLICY "Users can update own settings"
  ON app_settings FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = profile_id AND user_id = auth.uid()
  ));

-- ============================================
-- Function: validate invite code
-- ============================================
CREATE OR REPLACE FUNCTION validate_invite_code(p_code TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  v_valid BOOLEAN;
BEGIN
  SELECT is_active AND (used_by IS NULL)
  INTO v_valid
  FROM invite_codes
  WHERE code = p_code;

  RETURN COALESCE(v_valid, FALSE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
