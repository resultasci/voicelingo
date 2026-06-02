-- ============================================================================
-- VoiceLingo — Apply FORCE ROW LEVEL SECURITY to remaining user-owned tables.
--
-- WHY: ENABLE ROW LEVEL SECURITY makes RLS apply to ordinary roles, but the
-- TABLE OWNER (and SECURITY DEFINER functions running as that owner) still
-- BYPASS RLS unless FORCE is also set. The base-schema / account tables
-- (profiles, words, practice_sessions, conversations, messages, api_usage)
-- correctly use FORCE; the later feature migrations (gamification, grammar,
-- scenarios, course path) only ENABLE-d it. This is a defense-in-depth gap:
-- the many SECURITY DEFINER RPCs that touch these tables run as the owner and
-- are therefore not constrained by the per-user policies.
--
-- FORCE does not change which rows authenticated users can see (their policies
-- already filter by auth.uid()); it only ensures owner-context code is held to
-- the same policies.
--
-- Scope is limited to USER-OWNED tables (rows keyed by user_id). The read-only
-- catalog tables (badges, grammar_topics, courses, units, lessons, app_config,
-- dictionary_entries) are deliberately left as ENABLE-only so that future seed
-- migrations and the service-role enrichment path keep writing freely; their
-- existing "SELECT to authenticated USING (true)" + absent write policy already
-- locks down end-user writes.
--
-- Idempotent and non-destructive. Guarded by to_regclass so it is safe on
-- databases missing any given table.
-- ============================================================================

DO $$
DECLARE
  tbl text;
  user_owned text[] := ARRAY[
    'public.user_badges',
    'public.daily_quests',
    'public.user_grammar_progress',
    'public.scenarios',
    'public.user_scenario_progress',
    'public.user_lesson_progress'
  ];
BEGIN
  FOREACH tbl IN ARRAY user_owned LOOP
    IF to_regclass(tbl) IS NOT NULL THEN
      EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', tbl);
    END IF;
  END LOOP;
END
$$;
