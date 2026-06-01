-- ============================================================================
-- VoiceLingo — Hotfix:
--   1) practice_sessions RLS was missing in base_schema (security gap)
--   2) export_user_data / delete_user_payload were written against the legacy
--      messages.session_id schema; migration 20260428000004 redefined messages
--      with conversation_id + user_id. Functions were created (PL/pgSQL bodies
--      are not validated at CREATE time) but would crash at runtime.
-- Idempotent: safe to re-run.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. practice_sessions RLS
-- ----------------------------------------------------------------------------
ALTER TABLE public.practice_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.practice_sessions FORCE  ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "sessions_select_own" ON public.practice_sessions;
CREATE POLICY "sessions_select_own" ON public.practice_sessions
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "sessions_insert_own" ON public.practice_sessions;
CREATE POLICY "sessions_insert_own" ON public.practice_sessions
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "sessions_update_own" ON public.practice_sessions;
CREATE POLICY "sessions_update_own" ON public.practice_sessions
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "sessions_delete_own" ON public.practice_sessions;
CREATE POLICY "sessions_delete_own" ON public.practice_sessions
  FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 2. export_user_data — rewritten against new messages schema
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.export_user_data()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  uid    uuid := auth.uid();
  result jsonb;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '28000';
  END IF;

  SELECT jsonb_build_object(
    'export_version', 2,
    'exported_at',    to_jsonb(now()),
    'user_id',        to_jsonb(uid),

    'profile', (SELECT to_jsonb(p) FROM public.profiles p WHERE p.id = uid),

    'words', COALESCE((
      SELECT jsonb_agg(to_jsonb(w) ORDER BY w.created_at)
      FROM public.words w WHERE w.user_id = uid
    ), '[]'::jsonb),

    'practice_sessions', COALESCE((
      SELECT jsonb_agg(to_jsonb(s) ORDER BY s.created_at)
      FROM public.practice_sessions s WHERE s.user_id = uid
    ), '[]'::jsonb),

    'conversations', COALESCE((
      SELECT jsonb_agg(to_jsonb(c) ORDER BY c.created_at)
      FROM public.conversations c WHERE c.user_id = uid
    ), '[]'::jsonb),

    'messages', COALESCE((
      SELECT jsonb_agg(to_jsonb(m) ORDER BY m.created_at)
      FROM public.messages m WHERE m.user_id = uid
    ), '[]'::jsonb),

    'api_usage', COALESCE((
      SELECT jsonb_agg(to_jsonb(u) ORDER BY u.usage_date)
      FROM public.api_usage u WHERE u.user_id = uid
    ), '[]'::jsonb)
  ) INTO result;

  RETURN result;
END;
$$;

-- ----------------------------------------------------------------------------
-- 3. delete_user_payload — rewritten against new messages schema
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.delete_user_payload()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  uid uuid := auth.uid();
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '28000';
  END IF;

  -- Order respects FKs; cascades would handle most of this anyway when the
  -- auth.users row is finally deleted by the account-admin Edge Function.
  DELETE FROM public.messages          WHERE user_id = uid;
  DELETE FROM public.conversations     WHERE user_id = uid;
  DELETE FROM public.practice_sessions WHERE user_id = uid;
  DELETE FROM public.words             WHERE user_id = uid;
  DELETE FROM public.api_usage         WHERE user_id = uid;
  DELETE FROM public.profiles          WHERE id      = uid;
END;
$$;
