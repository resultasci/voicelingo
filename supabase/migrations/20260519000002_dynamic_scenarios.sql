-- VoiceLingo Faz 7: Dinamik Senaryo Ãœretimi
-- Created: 2026-05-19

-- =============================================================================
-- scenarios: hem sistem (built-in) hem kullanÄ±cÄ± tarafÄ±ndan Ã¼retilen senaryolar
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.scenarios (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid REFERENCES auth.users(id) ON DELETE CASCADE,  -- null = system
  is_public       boolean NOT NULL DEFAULT false,
  category        text,            -- daily_life | travel | work | romance | emergency | education | health | other
  difficulty      text NOT NULL DEFAULT 'medium',  -- easy | medium | hard
  title_en        text NOT NULL,
  title_tr        text,
  setting         text NOT NULL,
  ai_role         text NOT NULL,
  user_role       text NOT NULL,
  starter_line    text,
  key_phrases     text[] DEFAULT ARRAY[]::text[],
  objectives      text[] DEFAULT ARRAY[]::text[],
  estimated_turns int NOT NULL DEFAULT 6,
  icon_code       text,            -- UI'da Material icon eÅŸleÅŸtirme
  system_prompt   text,             -- Ã¼retilen prompt; AI rolÃ¼nÃ¼ ve hedefleri iÃ§erir
  description_hash text,            -- aynÄ± request tekrar gelirse cache hit
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS scenarios_user_idx ON public.scenarios (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS scenarios_public_idx ON public.scenarios (is_public, created_at DESC) WHERE is_public = true;
CREATE INDEX IF NOT EXISTS scenarios_hash_idx ON public.scenarios (description_hash) WHERE description_hash IS NOT NULL;

ALTER TABLE public.scenarios ENABLE ROW LEVEL SECURITY;
-- Sistem senaryolarÄ± (user_id IS NULL) ve public senaryolar herkese okunabilir.
CREATE POLICY "scenarios_read_visible"
  ON public.scenarios FOR SELECT TO authenticated
  USING (user_id IS NULL OR is_public OR auth.uid() = user_id);
CREATE POLICY "scenarios_insert_self"
  ON public.scenarios FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "scenarios_update_self"
  ON public.scenarios FOR UPDATE TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "scenarios_delete_self"
  ON public.scenarios FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- =============================================================================
-- user_scenario_progress: kullanÄ±cÄ±nÄ±n her senaryodaki ilerlemesi
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.user_scenario_progress (
  user_id           uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  scenario_id       uuid REFERENCES public.scenarios(id) ON DELETE CASCADE,
  conversation_id   uuid REFERENCES public.conversations(id) ON DELETE SET NULL,
  objectives_met    int NOT NULL DEFAULT 0,
  total_objectives  int NOT NULL DEFAULT 0,
  completed_at      timestamptz,
  attempts          int NOT NULL DEFAULT 0,
  best_score        int,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, scenario_id)
);

ALTER TABLE public.user_scenario_progress ENABLE ROW LEVEL SECURITY;
CREATE POLICY "scenario_progress_all_self"
  ON public.user_scenario_progress FOR ALL TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- =============================================================================
-- Sistem senaryolarÄ± seed â€” daha Ã¶nce hardcoded ScenarioModel'lerin DB karÅŸÄ±lÄ±ÄŸÄ±
-- =============================================================================
INSERT INTO public.scenarios (
  user_id, is_public, category, difficulty, title_en, title_tr,
  setting, ai_role, user_role, starter_line,
  key_phrases, objectives, estimated_turns, icon_code, system_prompt
) VALUES
(NULL, true, 'daily_life', 'easy',
 'Coffee Shop Order', 'Kafe SipariÅŸi',
 'You are at a busy coffee shop in London.',
 'A friendly barista taking orders',
 'A customer ordering a drink',
 'Hi there! Welcome to Brew & Co. What can I get started for you today?',
 ARRAY['I''d like','a cappuccino','to go','for here','that''s all'],
 ARRAY['Order a drink','Specify size','Make small talk'],
 6, 'local_cafe_outlined',
 'You are a friendly barista at a busy coffee shop in London. Stay in character. Keep the conversation realistic, polite, and short. Help the user practice ordering, asking about menu items, and small talk. Reply in English; if the learner is stuck, you may add a tiny Turkish hint in parentheses.'),

(NULL, true, 'work', 'medium',
 'Job Interview', 'Ä°ÅŸ MÃ¼lakatÄ±',
 'You are in a first-round interview at a tech company.',
 'An HR recruiter conducting a friendly interview',
 'A candidate for a junior software role',
 'Thanks for joining today. Could you start by telling me a little about yourself?',
 ARRAY['my experience','I have worked','my strengths','I am interested'],
 ARRAY['Introduce yourself','Describe experience','Ask a question'],
 8, 'work_outline',
 'You are an HR recruiter conducting a friendly first-round interview for a junior software role. Ask one short question at a time and react naturally to the user''s answers. Keep replies under three sentences.'),

(NULL, true, 'health', 'medium',
 'Doctor Appointment', 'Doktor Randevusu',
 'You are at a general practitioner''s clinic.',
 'A calm, empathetic family doctor',
 'A patient with a minor illness',
 'Hello, please come in and have a seat. So, what brings you in today?',
 ARRAY['I have a','my throat hurts','since yesterday','how long'],
 ARRAY['Describe symptoms','Answer follow-up questions','Ask about treatment'],
 7, 'medical_services_outlined',
 'You are a calm, empathetic family doctor (GP). Ask the user about their symptoms, gently probe for details, and suggest reasonable next steps. Avoid heavy medical jargon. Keep replies short and supportive.'),

(NULL, true, 'daily_life', 'easy',
 'Casual Small Talk', 'TanÄ±ÅŸma',
 'You are at a coworking space lounge.',
 'A friendly stranger making small talk',
 'Someone new to the coworking space',
 'Hey! Mind if I sit here? It''s pretty crowded today, isn''t it?',
 ARRAY['Nice to meet you','I''m from','what do you do','have a good one'],
 ARRAY['Introduce yourself','Ask a question back','Switch topics naturally'],
 6, 'people_alt_outlined',
 'You are a friendly stranger at a coworking space lounge. Make light, curious small talk. Switch topics naturally (weather, weekend plans, work, hobbies). Keep replies short and inviting.'),

(NULL, true, 'travel', 'medium',
 'Airport Check-in', 'HavalimanÄ± / Seyahat',
 'You are at an international airport check-in counter.',
 'An airline check-in agent',
 'A traveler checking in for a flight',
 'Good morning, may I see your passport and booking reference, please?',
 ARRAY['my passport','window seat','one bag to check','boarding time'],
 ARRAY['Present documents','Choose seat','Ask about baggage'],
 6, 'flight_takeoff_outlined',
 'You are an airline check-in agent at an international airport. Help the user check in, answer baggage and boarding-time questions, and stay polite and efficient. Keep each turn under three sentences.')
ON CONFLICT DO NOTHING;
