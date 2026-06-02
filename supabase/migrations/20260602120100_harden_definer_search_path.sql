-- ============================================================================
-- VoiceLingo — Harden SECURITY DEFINER functions against search_path attacks.
--
-- WHY: A SECURITY DEFINER function runs with the OWNER's privileges. If it does
-- not pin `search_path`, a caller can prepend a schema they control (e.g. a
-- temp schema) and shadow unqualified references to tables / functions /
-- operators the body uses, hijacking execution as the (typically superuser)
-- owner. Supabase's own linter flags this as `function_search_path_mutable`.
--
-- Several DEFINER functions in earlier migrations were created WITHOUT
-- `SET search_path`:
--   handle_new_user, touch_profile_activity, try_award_badge,
--   increment_quest_progress, complete_lesson, get_daily_xp_range,
--   get_mastery_summary, get_top_errors.
-- (incr_api_usage / export_user_data / delete_user_payload already set it.)
--
-- We use ALTER FUNCTION ... SET search_path rather than re-declaring the bodies:
-- this is non-destructive, leaves each function's current definition untouched,
-- and is safe to re-run. Every referenced object is in `public`, and `pg_temp`
-- is intentionally LAST so an attacker-created temp object can never take
-- precedence over a real public object.
--
-- Guarded with `to_regprocedure(...) IS NOT NULL` so the migration applies
-- cleanly on databases where a given function may not exist yet.
-- Idempotent.
-- ============================================================================

DO $$
DECLARE
  fn text;
  targets text[] := ARRAY[
    'public.handle_new_user()',
    'public.touch_profile_activity()',
    'public.try_award_badge(text)',
    'public.increment_quest_progress(uuid, int)',
    'public.complete_lesson(uuid, int)',
    'public.get_daily_xp_range(int)',
    'public.get_mastery_summary()',
    'public.get_top_errors(int)'
  ];
BEGIN
  FOREACH fn IN ARRAY targets LOOP
    IF to_regprocedure(fn) IS NOT NULL THEN
      EXECUTE format('ALTER FUNCTION %s SET search_path = public, pg_temp', fn);
    END IF;
  END LOOP;
END
$$;
