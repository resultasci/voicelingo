-- ============================================================================
-- Voicelingo — Words: case-insensitive uniqueness, enrichment columns,
-- and a `seeded_at` flag on profiles to suppress re-seeding starter words.
-- Idempotent: safe to re-run.
-- ============================================================================

-- 1. Per-user uniqueness for words (case-insensitive).
--    target_language column exists on words (added by an earlier ad-hoc migration);
--    fall back to a 2-column index if the column is absent so this migration
--    still applies on older databases.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'words'
      AND column_name = 'target_language'
  ) THEN
    CREATE UNIQUE INDEX IF NOT EXISTS unique_word_per_user
      ON public.words (user_id, lower(word), target_language);
  ELSE
    CREATE UNIQUE INDEX IF NOT EXISTS unique_word_per_user
      ON public.words (user_id, lower(word));
  END IF;
END
$$;

-- 2. Enrichment columns for word detail view (IPA, example, audio cache flag).
ALTER TABLE public.words
  ADD COLUMN IF NOT EXISTS example_sentence text,
  ADD COLUMN IF NOT EXISTS ipa              text,
  ADD COLUMN IF NOT EXISTS audio_cached     boolean NOT NULL DEFAULT false;

-- 3. seeded_at on profiles — only seed starter words on the very first launch.
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS seeded_at  timestamptz,
  ADD COLUMN IF NOT EXISTS cefr_level text;
