-- Targeted mojibake fix v2.
-- The previous migration 20260521000004 wrote the 'a1_present_continuous'
-- grammar topic and the matching lesson with cp1252-encoded text (Aimdiki/Au).
-- Set authoritative UTF-8 values for those specific rows.

UPDATE public.grammar_topics SET
  title_tr = 'Şimdiki Zaman (Present Continuous)',
  description_tr = 'Şu anda devam eden eylemler için kullanılır. "be + verb-ing" yapısı. "I am working", "She is sleeping".'
WHERE code = 'a1_present_continuous';

-- The lesson title in course_path migration also had Aimdiki Zaman
UPDATE public.lessons SET
  title_tr = 'Şimdiki Zaman'
WHERE title_en = 'Present Continuous' AND title_tr LIKE 'Å%';
