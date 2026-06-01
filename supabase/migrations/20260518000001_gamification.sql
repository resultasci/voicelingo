-- VoiceLingo Faz 4: Onboarding + Gamification
-- Created: 2026-05-18
-- Adds: badges catalog, user_badges junction, daily_quests, profile extension fields.

-- =============================================================================
-- profiles: yeni alanlar
-- =============================================================================
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS streak_freezes int NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_active_at timestamptz,
  ADD COLUMN IF NOT EXISTS onboarding_completed_at timestamptz,
  ADD COLUMN IF NOT EXISTS daily_minute_goal int NOT NULL DEFAULT 10,
  ADD COLUMN IF NOT EXISTS learning_motivation text;

COMMENT ON COLUMN public.profiles.streak_freezes IS 'Haftada 1 kazanılabilen streak koruma token sayısı';
COMMENT ON COLUMN public.profiles.last_active_at IS 'Streak reset hesaplaması için son aktivite';
COMMENT ON COLUMN public.profiles.daily_minute_goal IS 'Kullanıcının hedeflediği günlük çalışma dakikası (5/10/20/30)';
COMMENT ON COLUMN public.profiles.learning_motivation IS 'work | exam | travel | hobby';

-- =============================================================================
-- badges: tüm rozetlerin tek kaynağı (seed verisi)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.badges (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code        text UNIQUE NOT NULL,
  name_tr     text NOT NULL,
  name_en     text NOT NULL,
  description_tr text,
  description_en text,
  icon        text,
  criteria    jsonb NOT NULL,
  xp_reward   int  NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE  public.badges IS 'Rozet kataloğu - kullanıcılar tarafından kazanılabilir';
COMMENT ON COLUMN public.badges.criteria IS '{"type":"words_added","target":50} gibi koşul tanımı';

-- RLS: read-only for everyone
ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;
CREATE POLICY "badges_select_all"
  ON public.badges FOR SELECT
  TO authenticated
  USING (true);

-- =============================================================================
-- user_badges: kazanılan rozetler
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.user_badges (
  user_id   uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  badge_id  uuid REFERENCES public.badges(id) ON DELETE CASCADE,
  earned_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, badge_id)
);

CREATE INDEX IF NOT EXISTS user_badges_user_earned_idx
  ON public.user_badges (user_id, earned_at DESC);

ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_badges_select_self"
  ON public.user_badges FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);
CREATE POLICY "user_badges_insert_self"
  ON public.user_badges FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- =============================================================================
-- daily_quests: günlük görevler
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.daily_quests (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  quest_date   date NOT NULL,
  quest_type   text NOT NULL,
  target       int  NOT NULL,
  progress     int  NOT NULL DEFAULT 0,
  completed_at timestamptz,
  xp_reward    int  NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS daily_quests_user_date_type_uniq
  ON public.daily_quests (user_id, quest_date, quest_type);

CREATE INDEX IF NOT EXISTS daily_quests_user_date_idx
  ON public.daily_quests (user_id, quest_date);

ALTER TABLE public.daily_quests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "daily_quests_all_self"
  ON public.daily_quests FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- =============================================================================
-- Badge seed verisi (idempotent UPSERT)
-- =============================================================================
INSERT INTO public.badges (code, name_tr, name_en, description_tr, description_en, icon, criteria, xp_reward)
VALUES
  -- Streak rozetleri
  ('streak_3',  '3 Gün',         '3-Day Streak',   '3 gün üst üste çalıştın!',   '3 days in a row!',     'flame', '{"type":"streak","target":3}',   50),
  ('streak_7',  'Bir Hafta',     '7-Day Streak',   '7 gün üst üste çalıştın!',   '7 days in a row!',     'flame', '{"type":"streak","target":7}',   100),
  ('streak_30', 'Bir Ay',        '30-Day Streak',  '30 gün üst üste çalıştın!',  '30 days in a row!',    'flame', '{"type":"streak","target":30}',  500),
  ('streak_100','Yüz Gün',       '100-Day Streak', '100 gün üst üste çalıştın!', '100 days in a row!',   'flame', '{"type":"streak","target":100}', 2000),
  -- Kelime rozetleri
  ('words_10',  'İlk Adım',      'First Steps',    '10 kelime öğrendin',         'Learned 10 words',     'book',  '{"type":"words_mastered","target":10}',   30),
  ('words_50',  'Sözlük Avcısı', 'Word Hunter',    '50 kelime ustası oldun',     'Mastered 50 words',    'book',  '{"type":"words_mastered","target":50}',   150),
  ('words_100', 'Yüz Kelime',    'Centurion',      '100 kelime ustası oldun',    'Mastered 100 words',   'book',  '{"type":"words_mastered","target":100}',  300),
  ('words_500', 'Beş Yüz',       'Five Hundred',   '500 kelime ustası oldun',    'Mastered 500 words',   'book',  '{"type":"words_mastered","target":500}',  1500),
  -- Konuşma rozetleri
  ('talk_10',   'İlk Sohbet',    'First Talk',     '10 konuşma turu tamamladın', 'Completed 10 turns',   'mic',   '{"type":"conversation_turns","target":10}',   30),
  ('talk_100',  'Sohbet Eden',   'Conversationalist','100 konuşma turu tamamladın','Completed 100 turns','mic', '{"type":"conversation_turns","target":100}',  200),
  ('talk_500',  'Konuşmacı',     'Speaker',        '500 konuşma turu tamamladın','Completed 500 turns', 'mic',   '{"type":"conversation_turns","target":500}',  1000),
  -- Score rozetleri
  ('perfect_5', 'Mükemmel',      'Perfectionist',  '5 kez 95+ puan aldın',       '5 perfect scores',     'star',  '{"type":"perfect_scores","target":5}',   100),
  -- Zaman bazlı
  ('early_bird','Sabah Kuşu',    'Early Bird',     'Sabah 06-09 arası çalıştın', 'Studied 6am-9am',      'sun',   '{"type":"time_window","window":"morning"}',  50),
  ('night_owl', 'Gece Kuşu',     'Night Owl',      'Gece 22-02 arası çalıştın',  'Studied 10pm-2am',     'moon',  '{"type":"time_window","window":"night"}',    50),
  -- Senaryo
  ('scenarios_5','Senarist',     'Scenarist',      '5 senaryo tamamladın',       'Completed 5 scenarios','theater_comedy','{"type":"scenarios_completed","target":5}',150)
ON CONFLICT (code) DO NOTHING;

-- =============================================================================
-- updated_at için trigger (timestamp güncelleme - profiles.last_active_at için)
-- =============================================================================
CREATE OR REPLACE FUNCTION public.touch_profile_activity()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.profiles
     SET last_active_at = now()
   WHERE id = auth.uid();
  RETURN NEW;
END;
$$;

-- =============================================================================
-- RPC: badge unlock kontrol + insert (atomic, double-award önler)
-- =============================================================================
CREATE OR REPLACE FUNCTION public.try_award_badge(p_badge_code text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid;
  v_badge   public.badges%ROWTYPE;
  v_already boolean;
  v_xp_reward int;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'unauthorized');
  END IF;

  SELECT * INTO v_badge FROM public.badges WHERE code = p_badge_code;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'badge_not_found');
  END IF;

  SELECT true INTO v_already
    FROM public.user_badges
   WHERE user_id = v_user_id AND badge_id = v_badge.id;

  IF v_already THEN
    RETURN jsonb_build_object('ok', false, 'error', 'already_earned');
  END IF;

  INSERT INTO public.user_badges (user_id, badge_id)
    VALUES (v_user_id, v_badge.id);

  -- XP ödülü uygula
  v_xp_reward := v_badge.xp_reward;
  IF v_xp_reward > 0 THEN
    UPDATE public.profiles
       SET xp = xp + v_xp_reward
     WHERE id = v_user_id;
  END IF;

  RETURN jsonb_build_object(
    'ok', true,
    'badge_id', v_badge.id,
    'name_tr', v_badge.name_tr,
    'name_en', v_badge.name_en,
    'icon', v_badge.icon,
    'xp_reward', v_xp_reward
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.try_award_badge(text) TO authenticated;

-- =============================================================================
-- RPC: daily quest progress artırımı + auto-complete + XP ödülü (atomic)
-- =============================================================================
CREATE OR REPLACE FUNCTION public.increment_quest_progress(
  p_quest_id uuid,
  p_delta    int
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id   uuid;
  v_quest     public.daily_quests%ROWTYPE;
  v_new_prog  int;
  v_completed boolean := false;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'unauthorized');
  END IF;

  SELECT * INTO v_quest
    FROM public.daily_quests
   WHERE id = p_quest_id AND user_id = v_user_id
   FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'quest_not_found');
  END IF;

  -- Zaten tamamlanmışsa idempotent
  IF v_quest.completed_at IS NOT NULL THEN
    RETURN jsonb_build_object('ok', true, 'row', row_to_json(v_quest));
  END IF;

  v_new_prog := LEAST(v_quest.target, v_quest.progress + p_delta);
  IF v_new_prog >= v_quest.target THEN
    v_completed := true;
  END IF;

  UPDATE public.daily_quests
     SET progress = v_new_prog,
         completed_at = CASE WHEN v_completed THEN now() ELSE NULL END
   WHERE id = p_quest_id
   RETURNING * INTO v_quest;

  -- Completion ise XP ödülü uygula
  IF v_completed AND v_quest.xp_reward > 0 THEN
    UPDATE public.profiles
       SET xp = xp + v_quest.xp_reward,
           last_active_at = now()
     WHERE id = v_user_id;
  END IF;

  RETURN jsonb_build_object(
    'ok', true,
    'row', row_to_json(v_quest),
    'completed', v_completed
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.increment_quest_progress(uuid, int) TO authenticated;
