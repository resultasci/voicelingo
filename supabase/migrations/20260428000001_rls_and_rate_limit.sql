-- ============================================================================
-- Voicelingo — Row-Level Security + per-user rate-limit ledger
-- Idempotent: safe to re-run.
-- Apply via Supabase SQL Editor or:  supabase db push
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. profiles
-- ----------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
CREATE POLICY "profiles_select_own" ON public.profiles
  FOR SELECT TO authenticated
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;
CREATE POLICY "profiles_insert_own" ON public.profiles
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- No DELETE policy: profile deletion only via the (later) account-delete RPC.

-- ----------------------------------------------------------------------------
-- 2. words
-- ----------------------------------------------------------------------------
ALTER TABLE public.words ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.words FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "words_select_own" ON public.words;
CREATE POLICY "words_select_own" ON public.words
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "words_insert_own" ON public.words;
CREATE POLICY "words_insert_own" ON public.words
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "words_update_own" ON public.words;
CREATE POLICY "words_update_own" ON public.words
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "words_delete_own" ON public.words;
CREATE POLICY "words_delete_own" ON public.words
  FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 3. api_usage — rate-limit ledger (user-invisible, service_role-only)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.api_usage (
  user_id          uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  usage_date       date        NOT NULL DEFAULT ((now() AT TIME ZONE 'UTC')::date),
  chat_count       integer     NOT NULL DEFAULT 0,
  evaluate_count   integer     NOT NULL DEFAULT 0,
  transcribe_count integer     NOT NULL DEFAULT 0,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, usage_date)
);

ALTER TABLE public.api_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_usage FORCE ROW LEVEL SECURITY;
-- Deliberately no policies. anon + authenticated have no access.
-- service_role bypasses RLS, so the Edge Function can read/write freely.

-- ----------------------------------------------------------------------------
-- 4. incr_api_usage(user_id, action) -> integer
--    Atomic upsert + increment. Returns the post-increment counter so the
--    Edge Function can compare against its in-memory limit.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.incr_api_usage(
  p_user_id uuid,
  p_action  text
) RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  new_count integer;
  today     date := ((now() AT TIME ZONE 'UTC')::date);
BEGIN
  IF p_action NOT IN ('chat', 'evaluate', 'transcribe') THEN
    RAISE EXCEPTION 'invalid action: %', p_action USING ERRCODE = '22023';
  END IF;

  IF p_action = 'chat' THEN
    INSERT INTO public.api_usage (user_id, usage_date, chat_count)
    VALUES (p_user_id, today, 1)
    ON CONFLICT (user_id, usage_date) DO UPDATE
      SET chat_count = api_usage.chat_count + 1,
          updated_at = now()
    RETURNING chat_count INTO new_count;
  ELSIF p_action = 'evaluate' THEN
    INSERT INTO public.api_usage (user_id, usage_date, evaluate_count)
    VALUES (p_user_id, today, 1)
    ON CONFLICT (user_id, usage_date) DO UPDATE
      SET evaluate_count = api_usage.evaluate_count + 1,
          updated_at = now()
    RETURNING evaluate_count INTO new_count;
  ELSE
    INSERT INTO public.api_usage (user_id, usage_date, transcribe_count)
    VALUES (p_user_id, today, 1)
    ON CONFLICT (user_id, usage_date) DO UPDATE
      SET transcribe_count = api_usage.transcribe_count + 1,
          updated_at = now()
    RETURNING transcribe_count INTO new_count;
  END IF;

  RETURN new_count;
END;
$$;

REVOKE ALL ON FUNCTION public.incr_api_usage(uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.incr_api_usage(uuid, text) FROM anon, authenticated;
GRANT EXECUTE ON FUNCTION public.incr_api_usage(uuid, text) TO service_role;
