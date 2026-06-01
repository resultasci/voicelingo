-- ============================================================================
-- Voicelingo — Persisted conversation history.
-- Adds `conversations` and `messages` tables with strict per-user RLS.
-- Idempotent: safe to re-run.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.conversations (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  scenario    text,
  title       text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS conversations_user_created_idx
  ON public.conversations (user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS public.messages (
  id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id  uuid        NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  user_id          uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role             text        NOT NULL CHECK (role IN ('user', 'assistant')),
  content          text        NOT NULL,
  eval_score       int,
  eval_suggestion  text,
  eval_explanation text,
  created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS messages_conversation_created_idx
  ON public.messages (conversation_id, created_at);

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations FORCE ROW LEVEL SECURITY;
ALTER TABLE public.messages      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages      FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "conv_own_select" ON public.conversations;
CREATE POLICY "conv_own_select" ON public.conversations
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "conv_own_insert" ON public.conversations;
CREATE POLICY "conv_own_insert" ON public.conversations
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "conv_own_update" ON public.conversations;
CREATE POLICY "conv_own_update" ON public.conversations
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "conv_own_delete" ON public.conversations;
CREATE POLICY "conv_own_delete" ON public.conversations
  FOR DELETE TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "msg_own_select" ON public.messages;
CREATE POLICY "msg_own_select" ON public.messages
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "msg_own_insert" ON public.messages;
CREATE POLICY "msg_own_insert" ON public.messages
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "msg_own_update" ON public.messages;
CREATE POLICY "msg_own_update" ON public.messages
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "msg_own_delete" ON public.messages;
CREATE POLICY "msg_own_delete" ON public.messages
  FOR DELETE TO authenticated USING (auth.uid() = user_id);
