-- =============================================================================
-- Pulso — Feed & Social Migration
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor → New query)
-- =============================================================================

-- ─── Tables ──────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.posts (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  image_url   text        NOT NULL,
  caption     text,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.likes (
  post_id    uuid        NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id    uuid        NOT NULL REFERENCES auth.users(id)  ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (post_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.follows (
  follower_id  uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  following_id uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at   timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (follower_id, following_id),
  CONSTRAINT no_self_follow CHECK (follower_id <> following_id)
);

-- ─── Row Level Security ───────────────────────────────────────────────────────

ALTER TABLE public.posts   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

-- posts: anyone authenticated can read; only owner can write
CREATE POLICY "posts_select" ON public.posts
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "posts_insert" ON public.posts
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "posts_update" ON public.posts
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "posts_delete" ON public.posts
  FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- likes: authenticated read; only own row for insert/delete
CREATE POLICY "likes_select" ON public.likes
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "likes_insert" ON public.likes
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "likes_delete" ON public.likes
  FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- follows: authenticated read; only own row for insert/delete
CREATE POLICY "follows_select" ON public.follows
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "follows_insert" ON public.follows
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "follows_delete" ON public.follows
  FOR DELETE TO authenticated
  USING (auth.uid() = follower_id);

-- ─── Storage Bucket ───────────────────────────────────────────────────────────

INSERT INTO storage.buckets (id, name, public)
VALUES ('posts', 'posts', true)
ON CONFLICT (id) DO NOTHING;

-- Public read: anyone can view post images
CREATE POLICY "posts_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'posts');

-- Authenticated write: path must start with the user's own UID
CREATE POLICY "posts_auth_insert"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'posts'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Owner delete: can only delete their own images
CREATE POLICY "posts_owner_delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'posts'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- ─── Indexes ─────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_posts_user_created  ON public.posts   (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_likes_post          ON public.likes   (post_id);
CREATE INDEX IF NOT EXISTS idx_follows_following   ON public.follows (following_id);
CREATE INDEX IF NOT EXISTS idx_follows_follower    ON public.follows (follower_id);
