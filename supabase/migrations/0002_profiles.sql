-- =============================================================================
-- Pulso — Profiles Migration
-- Run in Supabase SQL Editor if the profiles table does not yet exist.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.profiles (
  id         uuid        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username   text        NOT NULL UNIQUE,
  avatar_url text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'profiles_select'
  ) THEN
    CREATE POLICY "profiles_select" ON public.profiles
      FOR SELECT TO authenticated USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'profiles_insert'
  ) THEN
    CREATE POLICY "profiles_insert" ON public.profiles
      FOR INSERT TO authenticated
      WITH CHECK (auth.uid() = id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'profiles_update'
  ) THEN
    CREATE POLICY "profiles_update" ON public.profiles
      FOR UPDATE TO authenticated
      USING (auth.uid() = id);
  END IF;
END;
$$;

CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles (username);
