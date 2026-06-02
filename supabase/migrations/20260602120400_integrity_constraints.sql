-- ============================================================================
-- VoiceLingo — Integrity CHECK constraints (added NOT VALID).
--
-- WHY: Nothing currently stops corrupt values from being written:
--   * negative xp / level / streak / score columns,
--   * out-of-range scores (expected 0..100) and stars (expected 0..3),
--   * status columns holding values the app never expects.
-- The RPCs are careful, but direct PostgREST writes (the app updates profiles,
-- words, *_progress tables directly) and any future code path are unguarded.
--
-- SAFETY: every constraint is added NOT VALID. This enforces the rule on all
-- NEW and UPDATED rows immediately, but does NOT scan existing rows, so the
-- migration cannot fail on pre-existing dirty data and takes no heavy lock.
-- A human can run `ALTER TABLE ... VALIDATE CONSTRAINT ...` later, after the
-- pre-check queries below come back empty. Pre-checks (run manually first):
--
--   SELECT id FROM public.profiles
--     WHERE xp < 0 OR level < 1 OR streak_days < 0 OR streak_freezes < 0;
--   SELECT id FROM public.messages
--     WHERE eval_score IS NOT NULL AND eval_score NOT BETWEEN 0 AND 100;
--   SELECT user_id, lesson_id FROM public.user_lesson_progress
--     WHERE stars NOT BETWEEN 0 AND 3
--        OR (best_score IS NOT NULL AND best_score NOT BETWEEN 0 AND 100)
--        OR status NOT IN ('locked','unlocked','in_progress','completed','mastered');
--   SELECT user_id, topic_id FROM public.user_grammar_progress
--     WHERE (quiz_score IS NOT NULL AND quiz_score NOT BETWEEN 0 AND 100)
--        OR status NOT IN ('not_started','in_progress','completed','mastered');
--   SELECT id FROM public.daily_quests
--     WHERE target < 0 OR progress < 0 OR xp_reward < 0;
--
-- Each constraint is added inside a guard so re-running is a no-op.
-- ============================================================================

-- Helper: add a CHECK constraint only if it does not already exist.
-- (No DROP — purely additive.)

DO $$
BEGIN
  -- profiles: non-negative gamification counters, level floor of 1.
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_xp_nonneg') THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_xp_nonneg CHECK (xp >= 0) NOT VALID;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_level_min') THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_level_min CHECK (level >= 1) NOT VALID;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_streak_nonneg') THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_streak_nonneg
      CHECK (streak_days >= 0 AND streak_freezes >= 0) NOT VALID;
  END IF;

  -- messages: eval_score is a 0..100 rubric score when present.
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'messages_eval_score_range') THEN
    ALTER TABLE public.messages
      ADD CONSTRAINT messages_eval_score_range
      CHECK (eval_score IS NULL OR eval_score BETWEEN 0 AND 100) NOT VALID;
  END IF;

  -- user_lesson_progress: stars 0..3, score 0..100, known status set.
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ulp_stars_range') THEN
    ALTER TABLE public.user_lesson_progress
      ADD CONSTRAINT ulp_stars_range CHECK (stars BETWEEN 0 AND 3) NOT VALID;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ulp_score_range') THEN
    ALTER TABLE public.user_lesson_progress
      ADD CONSTRAINT ulp_score_range
      CHECK (best_score IS NULL OR best_score BETWEEN 0 AND 100) NOT VALID;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ulp_status_enum') THEN
    ALTER TABLE public.user_lesson_progress
      ADD CONSTRAINT ulp_status_enum
      CHECK (status IN ('locked','unlocked','in_progress','completed','mastered')) NOT VALID;
  END IF;

  -- user_grammar_progress: score 0..100, known status set.
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugp_score_range') THEN
    ALTER TABLE public.user_grammar_progress
      ADD CONSTRAINT ugp_score_range
      CHECK (quiz_score IS NULL OR quiz_score BETWEEN 0 AND 100) NOT VALID;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugp_status_enum') THEN
    ALTER TABLE public.user_grammar_progress
      ADD CONSTRAINT ugp_status_enum
      CHECK (status IN ('not_started','in_progress','completed','mastered')) NOT VALID;
  END IF;

  -- user_scenario_progress: best_score 0..100, counters non-negative.
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'usp_score_range') THEN
    ALTER TABLE public.user_scenario_progress
      ADD CONSTRAINT usp_score_range
      CHECK (best_score IS NULL OR best_score BETWEEN 0 AND 100) NOT VALID;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'usp_counts_nonneg') THEN
    ALTER TABLE public.user_scenario_progress
      ADD CONSTRAINT usp_counts_nonneg
      CHECK (objectives_met >= 0 AND total_objectives >= 0 AND attempts >= 0) NOT VALID;
  END IF;

  -- daily_quests: non-negative target / progress / reward.
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'daily_quests_nonneg') THEN
    ALTER TABLE public.daily_quests
      ADD CONSTRAINT daily_quests_nonneg
      CHECK (target >= 0 AND progress >= 0 AND xp_reward >= 0) NOT VALID;
  END IF;

  -- words: spaced-repetition fields must stay sane.
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'words_srs_nonneg') THEN
    ALTER TABLE public.words
      ADD CONSTRAINT words_srs_nonneg
      CHECK (repetitions >= 0 AND interval_days >= 0 AND ease_factor > 0) NOT VALID;
  END IF;
END
$$;
