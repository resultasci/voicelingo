-- record_grammar_quiz: gramer quiz sonucunu TEK round-trip'te işler.
--
-- Eski istemci akışı 3 ardışık round-trip'ti: SELECT mevcut progress →
-- UPSERT user_grammar_progress → (ilk completed'da) add_xp RPC. Üstelik
-- best-score/attempts mantığı atomik değildi (çift tap = sapma). Bu RPC
-- üçünü tek transaction'a katlar; FOR UPDATE kilidiyle gerçekten atomik.
--
-- Status rubriği istemcideki deriveGrammarStatus ile birebir aynı tutulmalı:
--   score >= 95 → mastered, >= 70 → completed, aksi → in_progress.
--
-- XP: best score ilk kez 70 eşiğini geçtiğinde verilir (mastered'a doğrudan
-- atlama dahil — eski istemci kodu ≥95 ilk denemede XP'yi atlıyordu, bu
-- bilinçli bir düzeltmedir ve istemci fallback'i de aynı şekilde düzeltildi).
--
-- SECURITY INVOKER: user_grammar_progress RLS'i aynen uygulanır; XP yazımı
-- mevcut hardened add_xp (SECURITY DEFINER) üzerinden akar.

CREATE OR REPLACE FUNCTION public.record_grammar_quiz(
  p_topic_id uuid,
  p_score int,
  p_xp_reward int
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id    uuid := auth.uid();
  v_prev_score int;
  v_new_status text;
  v_row        public.user_grammar_progress;
  v_xp_awarded int := 0;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '28000';
  END IF;
  IF p_score IS NULL OR p_score < 0 OR p_score > 100 THEN
    RAISE EXCEPTION 'p_score must be between 0 and 100' USING ERRCODE = '22023';
  END IF;

  v_new_status := CASE
    WHEN p_score >= 95 THEN 'mastered'
    WHEN p_score >= 70 THEN 'completed'
    ELSE 'in_progress'
  END;

  SELECT quiz_score INTO v_prev_score
    FROM public.user_grammar_progress
   WHERE user_id = v_user_id AND topic_id = p_topic_id
   FOR UPDATE;

  INSERT INTO public.user_grammar_progress
      (user_id, topic_id, status, quiz_score, attempts, completed_at, updated_at)
  VALUES (
    v_user_id,
    p_topic_id,
    v_new_status,
    GREATEST(COALESCE(v_prev_score, 0), p_score),
    1,
    CASE WHEN v_new_status IN ('completed', 'mastered') THEN now() END,
    now()
  )
  ON CONFLICT (user_id, topic_id) DO UPDATE
     SET status       = excluded.status,
         quiz_score   = excluded.quiz_score,
         attempts     = public.user_grammar_progress.attempts + 1,
         completed_at = excluded.completed_at,
         updated_at   = now()
  RETURNING * INTO v_row;

  IF v_new_status IN ('completed', 'mastered')
     AND COALESCE(v_prev_score, 0) < 70
     AND COALESCE(p_xp_reward, 0) > 0 THEN
    PERFORM public.add_xp(p_xp_reward);
    v_xp_awarded := p_xp_reward;
  END IF;

  RETURN jsonb_build_object(
    'progress', to_jsonb(v_row),
    'xp_awarded', v_xp_awarded
  );
END;
$$;

REVOKE ALL ON FUNCTION public.record_grammar_quiz(uuid, int, int) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.record_grammar_quiz(uuid, int, int) FROM anon;
GRANT EXECUTE ON FUNCTION public.record_grammar_quiz(uuid, int, int) TO authenticated;
