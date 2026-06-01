-- Performance indexes: hot-path WHERE/ORDER columns that previously triggered seq scans.
-- Idempotent (IF NOT EXISTS). messages(conversation_id, created_at) and
-- lessons(unit_id, order_index) already exist (created in 20260428000004 / 20260519000003),
-- so they are not re-created here.

-- words: filtered constantly by user_id (read-all, seeding count, due review).
CREATE INDEX IF NOT EXISTS idx_words_user_id
  ON public.words(user_id);

-- words: due-review hot path. Partial index keeps it small.
CREATE INDEX IF NOT EXISTS idx_words_user_due
  ON public.words(user_id, next_review);

-- practice_sessions: daily_xp VIEW + heatmap RPC scan this constantly.
CREATE INDEX IF NOT EXISTS idx_practice_sessions_user_created
  ON public.practice_sessions(user_id, created_at DESC);
