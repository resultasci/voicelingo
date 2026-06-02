-- ============================================================================
-- VoiceLingo — Validate the NOT VALID CHECK constraints from
-- 20260602120400_integrity_constraints.sql against existing rows.
--
-- Those constraints were added NOT VALID: enforced on new/updated rows but the
-- existing data was never scanned (so the additive migration could never fail).
-- This migration finishes the job: for each constraint it counts the rows that
-- would violate it and, only when that count is zero, runs
-- `ALTER TABLE ... VALIDATE CONSTRAINT` to mark it fully valid.
--
-- SAFETY / IDEMPOTENCY:
--   * VALIDATE on an already-valid constraint is a harmless no-op → re-runnable.
--   * If a table still has violating rows, the constraint is LEFT NOT VALID and
--     a WARNING is raised (with the count) instead of failing the migration, so
--     `supabase db push` never breaks. Clean the data, then re-run this file.
--   * A missing constraint (e.g. partial prior apply) is skipped with a NOTICE.
-- ============================================================================

DO $$
DECLARE
  r        record;
  v_bad    bigint;
  v_ok     int := 0;
  v_skip   int := 0;
BEGIN
  FOR r IN
    SELECT * FROM (VALUES
      ('profiles',              'profiles_xp_nonneg',        'xp < 0'),
      ('profiles',              'profiles_level_min',        'level < 1'),
      ('profiles',              'profiles_streak_nonneg',    'streak_days < 0 OR streak_freezes < 0'),
      ('messages',              'messages_eval_score_range', 'eval_score IS NOT NULL AND eval_score NOT BETWEEN 0 AND 100'),
      ('user_lesson_progress',  'ulp_stars_range',           'stars NOT BETWEEN 0 AND 3'),
      ('user_lesson_progress',  'ulp_score_range',           'best_score IS NOT NULL AND best_score NOT BETWEEN 0 AND 100'),
      ('user_lesson_progress',  'ulp_status_enum',           $q$status NOT IN ('locked','unlocked','in_progress','completed','mastered')$q$),
      ('user_grammar_progress', 'ugp_score_range',           'quiz_score IS NOT NULL AND quiz_score NOT BETWEEN 0 AND 100'),
      ('user_grammar_progress', 'ugp_status_enum',           $q$status NOT IN ('not_started','in_progress','completed','mastered')$q$),
      ('user_scenario_progress','usp_score_range',           'best_score IS NOT NULL AND best_score NOT BETWEEN 0 AND 100'),
      ('user_scenario_progress','usp_counts_nonneg',         'objectives_met < 0 OR total_objectives < 0 OR attempts < 0'),
      ('daily_quests',          'daily_quests_nonneg',       'target < 0 OR progress < 0 OR xp_reward < 0'),
      ('words',                 'words_srs_nonneg',          'repetitions < 0 OR interval_days < 0 OR ease_factor <= 0')
    ) AS t(tbl, conname, bad_where)
  LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = r.conname) THEN
      RAISE NOTICE 'SKIP % — constraint does not exist', r.conname;
      v_skip := v_skip + 1;
      CONTINUE;
    END IF;

    EXECUTE format('SELECT count(*) FROM public.%I WHERE %s', r.tbl, r.bad_where)
      INTO v_bad;

    IF v_bad = 0 THEN
      EXECUTE format('ALTER TABLE public.%I VALIDATE CONSTRAINT %I', r.tbl, r.conname);
      RAISE NOTICE 'VALIDATED %.%', r.tbl, r.conname;
      v_ok := v_ok + 1;
    ELSE
      RAISE WARNING 'LEFT NOT VALID %.% — % violating row(s); clean data and re-run',
        r.tbl, r.conname, v_bad;
      v_skip := v_skip + 1;
    END IF;
  END LOOP;

  RAISE NOTICE 'integrity constraint validation: % validated, % skipped', v_ok, v_skip;
END
$$;
