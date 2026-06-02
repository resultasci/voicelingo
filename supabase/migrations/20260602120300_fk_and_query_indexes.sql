-- ============================================================================
-- VoiceLingo — Foreign-key & hot-query indexes (complements 20260601100000).
--
-- WHY: Postgres does NOT auto-create an index for a foreign key. Unindexed FK
-- columns make two things slow:
--   (a) the referenced-side DELETE (e.g. account deletion / ON DELETE CASCADE),
--       which must seq-scan the child table to find referencing rows;
--   (b) the joins the app actually runs.
-- The columns below are FK or frequent filter/order columns that had no index.
-- 20260601100000_perf_indexes.sql already covered words(user_id),
-- words(user_id,next_review) and practice_sessions(user_id,created_at) — those
-- are intentionally NOT duplicated here.
--
-- All CREATE INDEX IF NOT EXISTS; idempotent and non-destructive.
-- (Not CONCURRENTLY: migrations run in a transaction, and these tables are
--  small. If a table is later found to be large/hot in prod, build the index
--  CONCURRENTLY out-of-band instead.)
-- ============================================================================

-- messages.user_id: per-user filter in export/delete + get_top_errors RPC scans
-- messages WHERE user_id = auth.uid(). Existing index is (conversation_id,
-- created_at) which does not serve user_id lookups.
CREATE INDEX IF NOT EXISTS idx_messages_user_created
  ON public.messages (user_id, created_at);

-- user_badges.badge_id: FK to badges; only the (user_id, earned_at) index exists,
-- which cannot serve the badge_id side (e.g. deleting/altering a badge).
CREATE INDEX IF NOT EXISTS idx_user_badges_badge_id
  ON public.user_badges (badge_id);

-- units.prerequisite_unit_id: self-referencing FK, fully unindexed.
CREATE INDEX IF NOT EXISTS idx_units_prerequisite
  ON public.units (prerequisite_unit_id)
  WHERE prerequisite_unit_id IS NOT NULL;

-- user_grammar_progress.topic_id: FK to grammar_topics. PK is (user_id, topic_id)
-- so user_id lookups are served, but topic_id-side lookups (and grammar_topics
-- deletes) are not.
CREATE INDEX IF NOT EXISTS idx_user_grammar_progress_topic
  ON public.user_grammar_progress (topic_id);

-- user_lesson_progress.lesson_id: FK to lessons. PK is (user_id, lesson_id);
-- lesson_id-side lookups / lesson deletes are unindexed.
CREATE INDEX IF NOT EXISTS idx_user_lesson_progress_lesson
  ON public.user_lesson_progress (lesson_id);

-- user_scenario_progress: PK (user_id, scenario_id) covers user_id + scenario_id
-- prefix, but the two other FKs are unindexed.
CREATE INDEX IF NOT EXISTS idx_user_scenario_progress_scenario
  ON public.user_scenario_progress (scenario_id);
CREATE INDEX IF NOT EXISTS idx_user_scenario_progress_conversation
  ON public.user_scenario_progress (conversation_id)
  WHERE conversation_id IS NOT NULL;
