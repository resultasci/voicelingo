-- VoiceLingo Faz 5: AI Karakter Sistemi
-- Created: 2026-05-18
-- Adds: profiles.selected_character_id, conversations.character_id (snapshot at start)

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS selected_character_id text NOT NULL DEFAULT 'lily';

COMMENT ON COLUMN public.profiles.selected_character_id IS
  'Kullanıcının seçtiği AI koç karakter ID — client tarafında AICharacters.byId() ile çözülür';

-- Conversation snapshot: konuşma başladığında o anki karakter — sonradan
-- kullanıcı karakteri değişse bile eski sohbet kayıtları doğru karakteri
-- yansıtır (immutable history).
ALTER TABLE public.conversations
  ADD COLUMN IF NOT EXISTS character_id text;

COMMENT ON COLUMN public.conversations.character_id IS
  'Konuşma başlatıldığında seçili karakter — değişmez (immutable snapshot)';
