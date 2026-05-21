-- =============================================================================
-- Pulso — Feed & Social Migration (Updated Schema)
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor → New query)
-- =============================================================================

-- ─── Tables ──────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.profiles (
  id           uuid        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username     text        NOT NULL UNIQUE,
  display_name text,
  avatar_url   text,
  bio          text,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.posts (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid        NOT NULL,
  image_url  text        NOT NULL,
  caption    text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.posts
  ADD CONSTRAINT fk_posts_profiles
  FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

CREATE TABLE IF NOT EXISTS public.likes (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id    uuid        NOT NULL,
  user_id    uuid        NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT likes_post_user_unique UNIQUE (post_id, user_id)
);

ALTER TABLE public.likes
  ADD CONSTRAINT fk_likes_posts
  FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE;

ALTER TABLE public.likes
  ADD CONSTRAINT fk_likes_profiles
  FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

CREATE TABLE IF NOT EXISTS public.comments (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id    uuid        NOT NULL,
  user_id    uuid        NOT NULL,
  body       text        NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.comments
  ADD CONSTRAINT fk_comments_posts
  FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE;

ALTER TABLE public.comments
  ADD CONSTRAINT fk_comments_profiles
  FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

CREATE TABLE IF NOT EXISTS public.follows (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id  uuid        NOT NULL,
  following_id uuid        NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT follows_follower_following_unique UNIQUE (follower_id, following_id),
  CONSTRAINT no_self_follow CHECK (follower_id <> following_id)
);

ALTER TABLE public.follows
  ADD CONSTRAINT fk_follows_follower
  FOREIGN KEY (follower_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.follows
  ADD CONSTRAINT fk_follows_following
  FOREIGN KEY (following_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

CREATE TABLE IF NOT EXISTS public.comment_likes (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  comment_id uuid        NOT NULL,
  user_id    uuid        NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT comment_likes_comment_user_unique UNIQUE (comment_id, user_id)
);

ALTER TABLE public.comment_likes
  ADD CONSTRAINT fk_comment_likes_comments
  FOREIGN KEY (comment_id) REFERENCES public.comments(id) ON DELETE CASCADE;

ALTER TABLE public.comment_likes
  ADD CONSTRAINT fk_comment_likes_profiles
  FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

DO $$
BEGIN
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

-- ─── Row Level Security ───────────────────────────────────────────────────────

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comment_likes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles_select_policy" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_policy" ON public.profiles;
DROP POLICY IF EXISTS "posts_select_policy" ON public.posts;
DROP POLICY IF EXISTS "posts_insert_policy" ON public.posts;
DROP POLICY IF EXISTS "posts_delete_policy" ON public.posts;
DROP POLICY IF EXISTS "likes_select_policy" ON public.likes;
DROP POLICY IF EXISTS "likes_insert_policy" ON public.likes;
DROP POLICY IF EXISTS "likes_delete_policy" ON public.likes;
DROP POLICY IF EXISTS "comments_select_policy" ON public.comments;
DROP POLICY IF EXISTS "comments_insert_policy" ON public.comments;
DROP POLICY IF EXISTS "comments_delete_policy" ON public.comments;
DROP POLICY IF EXISTS "follows_select_policy" ON public.follows;
DROP POLICY IF EXISTS "follows_insert_policy" ON public.follows;
DROP POLICY IF EXISTS "follows_delete_policy" ON public.follows;
DROP POLICY IF EXISTS "comment_likes_select_policy" ON public.comment_likes;
DROP POLICY IF EXISTS "comment_likes_insert_policy" ON public.comment_likes;
DROP POLICY IF EXISTS "comment_likes_delete_policy" ON public.comment_likes;

CREATE POLICY "profiles_select_policy" ON public.profiles
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "profiles_update_policy" ON public.profiles
  FOR UPDATE TO authenticated USING (auth.uid() = id);

CREATE POLICY "posts_select_policy" ON public.posts
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "posts_insert_policy" ON public.posts
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "posts_delete_policy" ON public.posts
  FOR DELETE TO authenticated USING (auth.uid() = user_id);

CREATE POLICY "likes_select_policy" ON public.likes
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "likes_insert_policy" ON public.likes
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "likes_delete_policy" ON public.likes
  FOR DELETE TO authenticated USING (auth.uid() = user_id);

CREATE POLICY "comments_select_policy" ON public.comments
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "comments_insert_policy" ON public.comments
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "comments_delete_policy" ON public.comments
  FOR DELETE TO authenticated USING (
    auth.uid() = user_id OR
    auth.uid() = (SELECT user_id FROM public.posts WHERE posts.id = comments.post_id)
  );

CREATE POLICY "follows_select_policy" ON public.follows
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "follows_insert_policy" ON public.follows
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "follows_delete_policy" ON public.follows
  FOR DELETE TO authenticated USING (auth.uid() = follower_id);

CREATE POLICY "comment_likes_select_policy" ON public.comment_likes
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "comment_likes_insert_policy" ON public.comment_likes
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "comment_likes_delete_policy" ON public.comment_likes
  FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- ─── Storage Bucket ───────────────────────────────────────────────────────────

INSERT INTO storage.buckets (id, name, public)
VALUES ('posts', 'posts', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "posts_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'posts');

CREATE POLICY "posts_auth_insert"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'posts'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "posts_owner_delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'posts'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- ─── Realtime ────────────────────────────────────────────────────────────────

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'likes' AND schemaname = 'public'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.likes;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'comments' AND schemaname = 'public'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.comments;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'comment_likes' AND schemaname = 'public'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.comment_likes;
  END IF;
END;
$$;

-- ─── Indexes ─────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_posts_user_created ON public.posts (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_likes_post ON public.likes (post_id);
CREATE INDEX IF NOT EXISTS idx_comments_post ON public.comments (post_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_comment_likes_comment ON public.comment_likes (comment_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON public.follows (following_id);
CREATE INDEX IF NOT EXISTS idx_follows_follower ON public.follows (follower_id);
