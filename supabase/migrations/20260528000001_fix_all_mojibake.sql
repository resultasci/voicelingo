-- Mojibake encoding fix for content tables.
-- Previous migration 20260521000004 was saved as cp1252 instead of UTF-8,
-- writing tokens like Aimdiki / A0 / aTM in DB. Fix with REPLACE pairs.
-- Idempotent: targets do not overlap valid Turkish text.

CREATE OR REPLACE FUNCTION pg_temp.fixmoji(s text) RETURNS text AS $func$
DECLARE
  o text;
BEGIN
  IF s IS NULL THEN RETURN NULL; END IF;
  o := s;
  o := replace(o, $a$â€™$a$, $a$'$a$);
  o := replace(o, $a$â€˜$a$, $a$'$a$);
  o := replace(o, $a$â€œ$a$, $a$"$a$);
  o := replace(o, $a$â€$a$,  $a$"$a$);
  o := replace(o, $a$ÅŸ$a$, $a$ş$a$);
  o := replace(o, $a$Åž$a$, $a$Ş$a$);
  o := replace(o, $a$ÄŸ$a$, $a$ğ$a$);
  o := replace(o, $a$Äž$a$, $a$Ğ$a$);
  o := replace(o, $a$Ä±$a$, $a$ı$a$);
  o := replace(o, $a$Ä°$a$, $a$İ$a$);
  o := replace(o, $a$Ã§$a$, $a$ç$a$);
  o := replace(o, $a$Ã‡$a$, $a$Ç$a$);
  o := replace(o, $a$Ã¶$a$, $a$ö$a$);
  o := replace(o, $a$Ã–$a$, $a$Ö$a$);
  o := replace(o, $a$Ã¼$a$, $a$ü$a$);
  o := replace(o, $a$Ãœ$a$, $a$Ü$a$);
  o := replace(o, $a$Åimdi$a$, $a$Şimdi$a$);
  o := replace(o, $a$Åu $a$, $a$Şu $a$);
  RETURN o;
END;
$func$ LANGUAGE plpgsql IMMUTABLE;

UPDATE public.grammar_topics SET
  title_tr       = pg_temp.fixmoji(title_tr),
  description_tr = pg_temp.fixmoji(description_tr),
  examples       = pg_temp.fixmoji(examples::text)::jsonb,
  quiz_questions = pg_temp.fixmoji(quiz_questions::text)::jsonb;

UPDATE public.lessons SET
  title_tr = pg_temp.fixmoji(title_tr),
  title_en = pg_temp.fixmoji(title_en),
  content  = pg_temp.fixmoji(content::text)::jsonb;

UPDATE public.units SET
  title_tr = pg_temp.fixmoji(title_tr),
  title_en = pg_temp.fixmoji(title_en);

UPDATE public.scenarios SET
  title_tr     = pg_temp.fixmoji(title_tr),
  title_en     = pg_temp.fixmoji(title_en),
  setting      = pg_temp.fixmoji(setting),
  ai_role      = pg_temp.fixmoji(ai_role),
  user_role    = pg_temp.fixmoji(user_role),
  starter_line = pg_temp.fixmoji(starter_line),
  key_phrases  = (SELECT array_agg(pg_temp.fixmoji(x)) FROM unnest(key_phrases) AS x),
  objectives   = (SELECT array_agg(pg_temp.fixmoji(x)) FROM unnest(objectives) AS x),
  system_prompt = pg_temp.fixmoji(system_prompt);

UPDATE public.badges SET
  name_tr        = pg_temp.fixmoji(name_tr),
  description_tr = pg_temp.fixmoji(description_tr);
