-- ============================================================================
-- VoiceLingo — Base schema
-- Consolidates legacy supabase_schema.sql + supabase_gamification.sql which
-- were originally applied via SQL Editor before migration-based tracking.
-- Migration 20260428000001+ assume profiles / words / practice_sessions exist.
-- Idempotent: safe to re-run.
-- ============================================================================

-- profiles
CREATE TABLE IF NOT EXISTS public.profiles (
  id                uuid        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username          text,
  level             int         NOT NULL DEFAULT 1,
  xp                int         NOT NULL DEFAULT 0,
  streak_days       int         NOT NULL DEFAULT 0,
  streak_last_date  date,
  target_language   text        NOT NULL DEFAULT 'en',
  created_at        timestamptz NOT NULL DEFAULT now()
);

-- words
CREATE TABLE IF NOT EXISTS public.words (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  word          text        NOT NULL,
  translation   text        NOT NULL DEFAULT '',
  ease_factor   float       NOT NULL DEFAULT 2.5,
  interval_days int         NOT NULL DEFAULT 1,
  repetitions   int         NOT NULL DEFAULT 0,
  next_review   date        NOT NULL DEFAULT current_date,
  created_at    timestamptz NOT NULL DEFAULT now()
);

-- practice_sessions
CREATE TABLE IF NOT EXISTS public.practice_sessions (
  id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  mode            text        NOT NULL DEFAULT 'conversation',
  words_practiced int         NOT NULL DEFAULT 0,
  avg_score       float       NOT NULL DEFAULT 0,
  xp_earned       int         NOT NULL DEFAULT 0,
  ended_at        timestamptz NOT NULL DEFAULT now(),
  created_at      timestamptz NOT NULL DEFAULT now()
);

-- Auto-create profile when a new auth user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, username)
  VALUES (new.id, split_part(new.email, '@', 1))
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- calculate_level (replaced by linear formula in 20260428000003_xp_trigger.sql)
CREATE OR REPLACE FUNCTION public.calculate_level(total_xp int)
RETURNS int
LANGUAGE plpgsql IMMUTABLE
AS $$
BEGIN
  IF total_xp IS NULL OR total_xp < 0 THEN
    RETURN 1;
  END IF;
  RETURN floor(sqrt(total_xp / 100.0))::int + 1;
END;
$$;

-- log_practice_session RPC (called by the Flutter app after each session)
CREATE OR REPLACE FUNCTION public.log_practice_session(
  p_mode            text,
  p_words_practiced int,
  p_avg_score       float,
  p_xp_earned       int,
  p_timezone_offset interval DEFAULT interval '0 hours'
)
RETURNS public.profiles
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  uid                uuid;
  user_profile       public.profiles;
  current_local_date date;
  last_streak_date   date;
BEGIN
  uid := auth.uid();
  IF uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  INSERT INTO public.practice_sessions (user_id, mode, words_practiced, avg_score, xp_earned)
  VALUES (uid, p_mode, p_words_practiced, p_avg_score, p_xp_earned);

  current_local_date := date(timezone('UTC', current_timestamp) + p_timezone_offset);

  SELECT * INTO user_profile FROM public.profiles WHERE id = uid FOR UPDATE;

  last_streak_date := user_profile.streak_last_date;

  IF last_streak_date IS NULL THEN
    user_profile.streak_days := 1;
    user_profile.streak_last_date := current_local_date;
  ELSIF last_streak_date = current_local_date THEN
    NULL;
  ELSIF last_streak_date = current_local_date - interval '1 day' THEN
    user_profile.streak_days := user_profile.streak_days + 1;
    user_profile.streak_last_date := current_local_date;
  ELSE
    user_profile.streak_days := 1;
    user_profile.streak_last_date := current_local_date;
  END IF;

  user_profile.xp    := user_profile.xp + p_xp_earned;
  user_profile.level := public.calculate_level(user_profile.xp);

  UPDATE public.profiles
     SET xp                = user_profile.xp,
         level             = user_profile.level,
         streak_days       = user_profile.streak_days,
         streak_last_date  = user_profile.streak_last_date
   WHERE id = uid;

  RETURN user_profile;
END;
$$;

GRANT EXECUTE ON FUNCTION public.log_practice_session(text, int, float, int, interval) TO authenticated;
