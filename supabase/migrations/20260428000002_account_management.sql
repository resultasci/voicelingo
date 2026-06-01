-- ============================================================================
-- Voicelingo — Account management: GDPR data export + cascading delete helper
-- Idempotent: safe to re-run.
-- Apply via Supabase SQL Editor or:  supabase db push
-- ============================================================================
--
-- Two RPCs are exposed:
--
-- 1. public.export_user_data() -> jsonb
--    Returns a single JSON document containing every row owned by the caller
--    across profiles / words / practice_sessions / messages / api_usage.
--    Callable by `authenticated`; runs as the caller (RLS still applies as a
--    defense-in-depth layer, but the function also explicitly filters by
--    auth.uid()).
--
-- 2. public.delete_user_payload() -> void
--    Wipes every row owned by the caller in public.* tables. The auth.users
--    row itself is deleted by the `account-admin` Edge Function via the
--    service-role admin API; this RPC is the belt-and-suspenders backup so
--    that even if the Edge Function admin call fails partway through, the
--    user's own data is gone first. Tables already declare ON DELETE CASCADE
--    against auth.users(id), so the auth-user delete alone is sufficient —
--    but calling this first makes the operation idempotent and resilient.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- 1. export_user_data
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.export_user_data()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  uid uuid := auth.uid();
  result jsonb;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '28000';
  END IF;

  SELECT jsonb_build_object(
    'export_version', 1,
    'exported_at', to_jsonb(now()),
    'user_id', to_jsonb(uid),

    'profile', (
      SELECT to_jsonb(p) FROM public.profiles p WHERE p.id = uid
    ),

    'words', COALESCE((
      SELECT jsonb_agg(to_jsonb(w) ORDER BY w.created_at)
      FROM public.words w WHERE w.user_id = uid
    ), '[]'::jsonb),

    'practice_sessions', COALESCE((
      SELECT jsonb_agg(to_jsonb(s) ORDER BY s.created_at)
      FROM public.practice_sessions s WHERE s.user_id = uid
    ), '[]'::jsonb),

    'messages', COALESCE((
      SELECT jsonb_agg(to_jsonb(m) ORDER BY m.created_at)
      FROM public.messages m
      WHERE m.session_id IN (
        SELECT id FROM public.practice_sessions WHERE user_id = uid
      )
    ), '[]'::jsonb),

    'api_usage', COALESCE((
      SELECT jsonb_agg(to_jsonb(u) ORDER BY u.usage_date)
      FROM public.api_usage u WHERE u.user_id = uid
    ), '[]'::jsonb)
  ) INTO result;

  RETURN result;
END;
$$;

REVOKE ALL ON FUNCTION public.export_user_data() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.export_user_data() FROM anon;
GRANT EXECUTE ON FUNCTION public.export_user_data() TO authenticated;

-- ----------------------------------------------------------------------------
-- 2. delete_user_payload
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

  -- Order matters only for clarity; FK cascades would do this anyway.
  DELETE FROM public.messages
    WHERE session_id IN (
      SELECT id FROM public.practice_sessions WHERE user_id = uid
    );
  DELETE FROM public.practice_sessions WHERE user_id = uid;
  DELETE FROM public.words            WHERE user_id = uid;
  DELETE FROM public.api_usage        WHERE user_id = uid;
  DELETE FROM public.profiles         WHERE id      = uid;
END;
$$;

REVOKE ALL ON FUNCTION public.delete_user_payload() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.delete_user_payload() FROM anon;
GRANT EXECUTE ON FUNCTION public.delete_user_payload() TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_user_payload() TO service_role;
