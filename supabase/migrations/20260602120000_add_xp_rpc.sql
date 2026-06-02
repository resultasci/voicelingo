-- ============================================================================
-- VoiceLingo — Missing `add_xp` RPC.
--
-- WHY: lib/features/grammar/services/grammar_service.dart calls
--   _db.rpc('add_xp', params: {'p_amount': xpReward})
-- to award XP when a grammar topic is first completed. No migration ever
-- defined this function, so the call always throws and is swallowed by the
-- surrounding try/catch ("Eski schema'da add_xp olmayabilir — best effort").
-- Net effect: grammar lessons silently award ZERO XP today.
--
-- This adds a small, hardened RPC that mirrors the inline
-- `UPDATE profiles SET xp = xp + N` pattern already used by complete_lesson,
-- try_award_badge and increment_quest_progress. The BEFORE UPDATE OF xp trigger
-- (trg_level) recalculates `level` automatically, so we only touch `xp`.
--
-- Idempotent: CREATE OR REPLACE.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.add_xp(p_amount int)
RETURNS public.profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_profile public.profiles;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '28000';
  END IF;

  -- Reject negative / null amounts: this RPC only grants XP, never deducts it,
  -- so a caller cannot use it to corrupt another path's accounting.
  IF p_amount IS NULL OR p_amount < 0 THEN
    RAISE EXCEPTION 'p_amount must be a non-negative integer' USING ERRCODE = '22023';
  END IF;

  UPDATE public.profiles
     SET xp             = xp + p_amount,
         last_active_at = now()
   WHERE id = v_user_id
  RETURNING * INTO v_profile;

  RETURN v_profile;
END;
$$;

REVOKE ALL ON FUNCTION public.add_xp(int) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.add_xp(int) FROM anon;
GRANT EXECUTE ON FUNCTION public.add_xp(int) TO authenticated;
