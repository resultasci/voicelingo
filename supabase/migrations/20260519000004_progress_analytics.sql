-- VoiceLingo Faz 9: İlerleme Analizi
-- Created: 2026-05-19
-- Daily XP aggregation + word mastery + error pattern view

-- =============================================================================
-- messages.grammar_errors — speech evaluation hata listesi (jsonb array)
-- conversation_screen.dart şu an persist etmiyor; future-ready için ekliyoruz.
-- =============================================================================
ALTER TABLE public.messages
  ADD COLUMN IF NOT EXISTS grammar_errors jsonb;

-- =============================================================================
-- practice_sessions: bireysel pratik etkinliği (log_practice_session RPC'sinin
-- yazdığı tablo zaten varsa skip et — bu migration sadece ek view'lar ekler).
-- log_practice_session zaten Faz 0 öncesi 20260428000003_xp_trigger.sql'de var.
-- =============================================================================

-- =============================================================================
-- VIEW: daily_xp — kullanıcı bazlı günlük toplam XP (heatmap için)
-- =============================================================================
CREATE OR REPLACE VIEW public.daily_xp AS
SELECT
  user_id,
  (created_at AT TIME ZONE 'UTC')::date AS day,
  COALESCE(SUM(xp_earned), 0)::int     AS xp
FROM public.practice_sessions
GROUP BY user_id, (created_at AT TIME ZONE 'UTC')::date;

-- View'lar RLS'i taban tablodan miras alır; practice_sessions zaten kullanıcı bazlı.

-- =============================================================================
-- FUNCTION: get_daily_xp_range — son N günün XP heatmap'i
-- =============================================================================
CREATE OR REPLACE FUNCTION public.get_daily_xp_range(p_days int DEFAULT 90)
RETURNS TABLE (day date, xp int)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT day::date, xp
    FROM public.daily_xp
   WHERE user_id = auth.uid()
     AND day >= (now() AT TIME ZONE 'UTC')::date - p_days
   ORDER BY day;
$$;

GRANT EXECUTE ON FUNCTION public.get_daily_xp_range(int) TO authenticated;

-- =============================================================================
-- FUNCTION: get_mastery_summary — kelime/gramer/lesson mastery sayıları
-- =============================================================================
CREATE OR REPLACE FUNCTION public.get_mastery_summary()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_words_total int;
  v_words_mastered int;
  v_grammar_total int;
  v_grammar_done int;
  v_grammar_mastered int;
  v_lessons_total int;
  v_lessons_done int;
  v_lessons_mastered int;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'unauthorized');
  END IF;

  -- Words: total = user'a ait kelime, mastered = repetitions >= 3
  SELECT COUNT(*),
         COUNT(*) FILTER (WHERE repetitions >= 3)
    INTO v_words_total, v_words_mastered
    FROM public.words WHERE user_id = v_user_id;

  -- Grammar
  SELECT COUNT(*) INTO v_grammar_total FROM public.grammar_topics;
  SELECT COUNT(*) FILTER (WHERE status IN ('completed','mastered')),
         COUNT(*) FILTER (WHERE status = 'mastered')
    INTO v_grammar_done, v_grammar_mastered
    FROM public.user_grammar_progress
   WHERE user_id = v_user_id;

  -- Lessons
  SELECT COUNT(*) INTO v_lessons_total FROM public.lessons;
  SELECT COUNT(*) FILTER (WHERE status IN ('completed','mastered')),
         COUNT(*) FILTER (WHERE status = 'mastered')
    INTO v_lessons_done, v_lessons_mastered
    FROM public.user_lesson_progress
   WHERE user_id = v_user_id;

  RETURN jsonb_build_object(
    'ok', true,
    'words',   jsonb_build_object('total', v_words_total,   'mastered', v_words_mastered),
    'grammar', jsonb_build_object('total', v_grammar_total, 'completed', v_grammar_done, 'mastered', v_grammar_mastered),
    'lessons', jsonb_build_object('total', v_lessons_total, 'completed', v_lessons_done, 'mastered', v_lessons_mastered)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_mastery_summary() TO authenticated;

-- =============================================================================
-- FUNCTION: get_top_errors — son 30 günde en sık hata türleri
-- =============================================================================
CREATE OR REPLACE FUNCTION public.get_top_errors(p_limit int DEFAULT 5)
RETURNS TABLE (error_type text, occurrences int)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT
    jsonb_array_elements_text(grammar_errors) AS error_type,
    COUNT(*)::int                              AS occurrences
  FROM public.messages
  WHERE user_id = auth.uid()
    AND created_at > now() - interval '30 days'
    AND jsonb_typeof(grammar_errors) = 'array'
  GROUP BY error_type
  ORDER BY occurrences DESC
  LIMIT p_limit;
$$;

GRANT EXECUTE ON FUNCTION public.get_top_errors(int) TO authenticated;
