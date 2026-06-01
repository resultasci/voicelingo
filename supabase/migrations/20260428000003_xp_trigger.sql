-- ============================================================================
-- Voicelingo — Linear XP -> level rule + belt-and-suspenders trigger.
--
-- The original `calculate_level` (in supabase_gamification.sql) used an
-- sqrt curve. CLAUDE.md spec calls for floor(xp / 500) + 1, so we replace
-- it here. `log_practice_session` continues to call `calculate_level`,
-- and the trigger guarantees `level` stays consistent even if some other
-- path updates `xp` directly (e.g. an admin SQL edit).
-- Idempotent: safe to re-run.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.calculate_level(total_xp int)
RETURNS int
LANGUAGE plpgsql IMMUTABLE
AS $$
BEGIN
  IF total_xp IS NULL OR total_xp < 0 THEN
    RETURN 1;
  END IF;
  RETURN floor(total_xp / 500.0)::int + 1;
END;
$$;

CREATE OR REPLACE FUNCTION public.recalculate_level()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.level := public.calculate_level(NEW.xp);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_level ON public.profiles;
CREATE TRIGGER trg_level
BEFORE UPDATE OF xp ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.recalculate_level();
