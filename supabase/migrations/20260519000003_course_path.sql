-- VoiceLingo Faz 8: Course Path A1-C2
-- Created: 2026-05-19

-- =============================================================================
-- courses: dil + CEFR seviyesi
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.courses (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  language    text NOT NULL,           -- 'en' (gelecekte: 'de','es' ...)
  level       text NOT NULL,           -- A1..C2
  order_index int  NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (language, level)
);

ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "courses_read_all"
  ON public.courses FOR SELECT TO authenticated USING (true);

-- =============================================================================
-- units: bir kursun haftalık/temalı bölümleri
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.units (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id            uuid NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
  order_index          int  NOT NULL,
  title_tr             text NOT NULL,
  title_en             text NOT NULL,
  theme                text,            -- 'greetings','food','travel'...
  prerequisite_unit_id uuid REFERENCES public.units(id) ON DELETE SET NULL,
  created_at           timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS units_course_order_idx
  ON public.units (course_id, order_index);

ALTER TABLE public.units ENABLE ROW LEVEL SECURITY;
CREATE POLICY "units_read_all"
  ON public.units FOR SELECT TO authenticated USING (true);

-- =============================================================================
-- lessons: bir unit'in dersleri, type'a göre farklı içerik
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.lessons (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  unit_id     uuid NOT NULL REFERENCES public.units(id) ON DELETE CASCADE,
  order_index int  NOT NULL,
  type        text NOT NULL,           -- vocab | grammar | conversation | listening | quiz
  title_tr    text NOT NULL,
  title_en    text NOT NULL,
  content     jsonb NOT NULL DEFAULT '{}'::jsonb,
  xp_reward   int  NOT NULL DEFAULT 20,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS lessons_unit_order_idx
  ON public.lessons (unit_id, order_index);

ALTER TABLE public.lessons ENABLE ROW LEVEL SECURITY;
CREATE POLICY "lessons_read_all"
  ON public.lessons FOR SELECT TO authenticated USING (true);

-- =============================================================================
-- user_lesson_progress: kullanıcı bazlı ders ilerlemesi
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.user_lesson_progress (
  user_id         uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  lesson_id       uuid REFERENCES public.lessons(id) ON DELETE CASCADE,
  status          text NOT NULL DEFAULT 'unlocked', -- locked | unlocked | in_progress | completed | mastered
  stars           int  NOT NULL DEFAULT 0,           -- 0-3
  best_score      int,                                -- 0-100
  attempts        int  NOT NULL DEFAULT 0,
  last_attempt_at timestamptz,
  next_review_at  timestamptz,                        -- spaced repetition (mastered olmayanlar 7 gün)
  updated_at      timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, lesson_id)
);

CREATE INDEX IF NOT EXISTS user_lesson_progress_user_status_idx
  ON public.user_lesson_progress (user_id, status);

ALTER TABLE public.user_lesson_progress ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_lesson_progress_all_self"
  ON public.user_lesson_progress FOR ALL TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- =============================================================================
-- RPC: ders tamamlama (atomic, XP + status + next_review_at + best_score)
-- =============================================================================
CREATE OR REPLACE FUNCTION public.complete_lesson(
  p_lesson_id uuid,
  p_score     int
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id    uuid;
  v_lesson     public.lessons%ROWTYPE;
  v_existing   public.user_lesson_progress%ROWTYPE;
  v_status     text;
  v_stars      int;
  v_xp_award   int := 0;
  v_first_pass boolean;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'unauthorized');
  END IF;

  SELECT * INTO v_lesson FROM public.lessons WHERE id = p_lesson_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'lesson_not_found');
  END IF;

  SELECT * INTO v_existing
    FROM public.user_lesson_progress
   WHERE user_id = v_user_id AND lesson_id = p_lesson_id;

  -- Status hesabı
  IF p_score >= 95 THEN
    v_status := 'mastered'; v_stars := 3;
  ELSIF p_score >= 85 THEN
    v_status := 'completed'; v_stars := 2;
  ELSIF p_score >= 70 THEN
    v_status := 'completed'; v_stars := 1;
  ELSE
    v_status := 'in_progress'; v_stars := 0;
  END IF;

  -- XP sadece ilk completed/mastered geçişinde verilir
  v_first_pass := (v_existing.user_id IS NULL)
                  OR (v_existing.status NOT IN ('completed','mastered')
                      AND v_status IN ('completed','mastered'));

  IF v_first_pass THEN
    v_xp_award := v_lesson.xp_reward;
  END IF;

  -- best_score korunur
  IF v_existing.best_score IS NOT NULL AND v_existing.best_score > p_score THEN
    p_score := v_existing.best_score;
  END IF;

  INSERT INTO public.user_lesson_progress (
    user_id, lesson_id, status, stars, best_score, attempts,
    last_attempt_at, next_review_at, updated_at
  ) VALUES (
    v_user_id, p_lesson_id, v_status,
    GREATEST(COALESCE(v_existing.stars, 0), v_stars),
    p_score,
    COALESCE(v_existing.attempts, 0) + 1,
    now(),
    CASE WHEN v_status IN ('completed','mastered')
         THEN now() + interval '7 days'
         ELSE NULL END,
    now()
  )
  ON CONFLICT (user_id, lesson_id) DO UPDATE
    SET status          = EXCLUDED.status,
        stars           = GREATEST(public.user_lesson_progress.stars, EXCLUDED.stars),
        best_score      = EXCLUDED.best_score,
        attempts        = public.user_lesson_progress.attempts + 1,
        last_attempt_at = now(),
        next_review_at  = EXCLUDED.next_review_at,
        updated_at      = now();

  IF v_xp_award > 0 THEN
    UPDATE public.profiles SET xp = xp + v_xp_award WHERE id = v_user_id;
  END IF;

  RETURN jsonb_build_object(
    'ok', true,
    'status', v_status,
    'stars', v_stars,
    'xp_awarded', v_xp_award,
    'first_completion', v_first_pass
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.complete_lesson(uuid, int) TO authenticated;

-- =============================================================================
-- A1 seed: 1 course + 3 units + 13 lessons toplam (MVP doğrulama)
-- =============================================================================
DO $$
DECLARE
  c_id  uuid;
  u1_id uuid;
  u2_id uuid;
  u3_id uuid;
BEGIN
  -- Course (idempotent: ON CONFLICT yapamayız çünkü UPDATE ile ID alıyoruz)
  SELECT id INTO c_id FROM public.courses WHERE language = 'en' AND level = 'A1';
  IF c_id IS NULL THEN
    INSERT INTO public.courses (language, level, order_index)
    VALUES ('en', 'A1', 1) RETURNING id INTO c_id;
  END IF;

  -- Unit 1: Greetings & Introductions
  SELECT id INTO u1_id FROM public.units
   WHERE course_id = c_id AND order_index = 1;
  IF u1_id IS NULL THEN
    INSERT INTO public.units (course_id, order_index, title_tr, title_en, theme)
    VALUES (c_id, 1, 'Selamlaşma ve Tanışma', 'Greetings & Introductions', 'greetings')
    RETURNING id INTO u1_id;
  END IF;

  -- Unit 2: Daily Routines
  SELECT id INTO u2_id FROM public.units
   WHERE course_id = c_id AND order_index = 2;
  IF u2_id IS NULL THEN
    INSERT INTO public.units (course_id, order_index, title_tr, title_en, theme,
                              prerequisite_unit_id)
    VALUES (c_id, 2, 'Günlük Rutinler', 'Daily Routines', 'daily_life', u1_id)
    RETURNING id INTO u2_id;
  END IF;

  -- Unit 3: Food & Drinks
  SELECT id INTO u3_id FROM public.units
   WHERE course_id = c_id AND order_index = 3;
  IF u3_id IS NULL THEN
    INSERT INTO public.units (course_id, order_index, title_tr, title_en, theme,
                              prerequisite_unit_id)
    VALUES (c_id, 3, 'Yiyecek ve İçecekler', 'Food & Drinks', 'food', u2_id)
    RETURNING id INTO u3_id;
  END IF;

  -- Lessons for Unit 1 (4 lesson)
  INSERT INTO public.lessons (unit_id, order_index, type, title_tr, title_en, content, xp_reward) VALUES
    (u1_id, 1, 'vocab', 'Selamlaşma Kelimeleri', 'Greeting Words',
     '{"words":[{"en":"hello","tr":"merhaba"},{"en":"goodbye","tr":"hoşçakal"},{"en":"please","tr":"lütfen"},{"en":"thank you","tr":"teşekkür ederim"},{"en":"yes","tr":"evet"},{"en":"no","tr":"hayır"},{"en":"sorry","tr":"özür dilerim"},{"en":"good morning","tr":"günaydın"}]}'::jsonb, 20),
    (u1_id, 2, 'grammar', 'Verb To Be', 'Verb To Be',
     '{"topic_code":"a1_verb_to_be"}'::jsonb, 30),
    (u1_id, 3, 'conversation', 'Tanışma Pratiği', 'Small Talk Practice',
     '{"scenario_code":"small_talk","min_turns":4}'::jsonb, 30),
    (u1_id, 4, 'quiz', 'Unit 1 Quiz', 'Unit 1 Quiz',
     '{"questions":[{"type":"mc","prompt_en":"How do you greet someone in the morning?","options":["Goodbye","Good morning","Thank you","Sorry"],"answer":"Good morning"},{"type":"fill","prompt_en":"___ you for your help!","answer":"Thank"},{"type":"mc","prompt_en":"To say goodbye:","options":["Hello","Goodbye","Sorry","Please"],"answer":"Goodbye"}]}'::jsonb, 30)
  ON CONFLICT DO NOTHING;

  -- Lessons for Unit 2 (5 lesson)
  INSERT INTO public.lessons (unit_id, order_index, type, title_tr, title_en, content, xp_reward) VALUES
    (u2_id, 1, 'vocab', 'Günlük Aktivite Fiilleri', 'Daily Activity Verbs',
     '{"words":[{"en":"wake up","tr":"uyanmak"},{"en":"eat","tr":"yemek"},{"en":"drink","tr":"içmek"},{"en":"work","tr":"çalışmak"},{"en":"sleep","tr":"uyumak"},{"en":"study","tr":"çalışmak (ders)"},{"en":"read","tr":"okumak"},{"en":"watch","tr":"izlemek"}]}'::jsonb, 20),
    (u2_id, 2, 'grammar', 'Geniş Zaman', 'Simple Present',
     '{"topic_code":"a1_simple_present"}'::jsonb, 30),
    (u2_id, 3, 'grammar', 'Åimdiki Zaman', 'Present Continuous',
     '{"topic_code":"a1_present_continuous"}'::jsonb, 30),
    (u2_id, 4, 'conversation', 'Kafe Sohbeti', 'Coffee Shop Talk',
     '{"scenario_code":"coffee_shop","min_turns":4}'::jsonb, 30),
    (u2_id, 5, 'quiz', 'Unit 2 Quiz', 'Unit 2 Quiz',
     '{"questions":[{"type":"fill","prompt_en":"I ___ (drink) coffee every morning.","answer":"drink"},{"type":"fill","prompt_en":"She ___ (work) at a bank.","answer":"works"},{"type":"mc","prompt_en":"What are you ___ right now?","options":["do","doing","does","done"],"answer":"doing"}]}'::jsonb, 30)
  ON CONFLICT DO NOTHING;

  -- Lessons for Unit 3 (4 lesson)
  INSERT INTO public.lessons (unit_id, order_index, type, title_tr, title_en, content, xp_reward) VALUES
    (u3_id, 1, 'vocab', 'Yiyecek Kelimeleri', 'Food Words',
     '{"words":[{"en":"bread","tr":"ekmek"},{"en":"cheese","tr":"peynir"},{"en":"apple","tr":"elma"},{"en":"chicken","tr":"tavuk"},{"en":"rice","tr":"pirinç"},{"en":"water","tr":"su"},{"en":"tea","tr":"çay"},{"en":"coffee","tr":"kahve"}]}'::jsonb, 20),
    (u3_id, 2, 'grammar', 'Tanımlıklar', 'Articles',
     '{"topic_code":"a1_articles"}'::jsonb, 30),
    (u3_id, 3, 'conversation', 'Restoran Siparişi', 'Restaurant Order',
     '{"scenario_code":"coffee_shop","min_turns":5}'::jsonb, 30),
    (u3_id, 4, 'quiz', 'Unit 3 Quiz', 'Unit 3 Quiz',
     '{"questions":[{"type":"mc","prompt_en":"I would like ___ apple, please.","options":["a","an","the","-"],"answer":"an"},{"type":"fill","prompt_en":"Can I have ___ cup of tea?","answer":"a"},{"type":"mc","prompt_en":"What do you drink in the morning?","options":["bread","chicken","coffee","apple"],"answer":"coffee"}]}'::jsonb, 30)
  ON CONFLICT DO NOTHING;
END $$;
