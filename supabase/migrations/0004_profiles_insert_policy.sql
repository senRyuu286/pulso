-- =============================================================================
-- Pulso — Add missing INSERT policy on profiles
-- Without this, RLS blocks every profile row created at registration.
-- Run in Supabase Dashboard → SQL Editor.
-- =============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'profiles' AND policyname = 'profiles_insert_policy'
  ) THEN
    CREATE POLICY "profiles_insert_policy" ON public.profiles
      FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);
  END IF;
END;
$$;
