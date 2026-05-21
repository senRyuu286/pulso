-- =============================================================================
-- Pulso — Profiles Migration (Compatibility)
-- Keeps local migrations in sync with the latest profiles schema.
-- =============================================================================

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS username text,
  ADD COLUMN IF NOT EXISTS display_name text,
  ADD COLUMN IF NOT EXISTS avatar_url text,
  ADD COLUMN IF NOT EXISTS bio text,
  ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'profiles_username_key'
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_username_key UNIQUE (username);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'fk_profiles_auth_user'
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT fk_profiles_auth_user
      FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END;
$$;

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'profiles_select_policy'
  ) THEN
    CREATE POLICY "profiles_select_policy" ON public.profiles
      FOR SELECT TO authenticated USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'profiles_update_policy'
  ) THEN
    CREATE POLICY "profiles_update_policy" ON public.profiles
      FOR UPDATE TO authenticated
      USING (auth.uid() = id);
  END IF;
END;
$$;

CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles (username);
