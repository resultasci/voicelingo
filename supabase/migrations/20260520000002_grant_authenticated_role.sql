-- ============================================================================
-- VoiceLingo — Restore table-level GRANTs for authenticated/anon roles.
--
-- Background: The earlier `DROP SCHEMA public CASCADE` reset stripped the
-- default privileges that Supabase normally seeds on `public`. As a result,
-- newly created tables (profiles, words, etc.) have no GRANT on them for the
-- `authenticated` role, so every PostgREST call fails with
--   42501 "permission denied for table <name>"
-- BEFORE RLS even gets a chance to evaluate the row.
--
-- This migration re-applies the Supabase default privilege set and is fully
-- idempotent. RLS continues to gate row-level access; this only restores the
-- table-level handshake the auth role needs to attempt the operation.
-- ============================================================================

-- Schema usage (covers future tables / functions)
GRANT USAGE ON SCHEMA public TO authenticated, anon;

-- Existing tables
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES    IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT                  ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE                        ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Anon role gets read-only on public tables (RLS still restricts which rows)
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;

-- Default privileges for tables/sequences/functions created AFTER this point
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT EXECUTE ON FUNCTIONS TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT ON TABLES TO anon;
