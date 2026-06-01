-- Feature flag matrix. Single-row table (id=1). Production rollbacks update
-- this row from the dashboard; no app rebuild needed.

CREATE TABLE IF NOT EXISTS public.app_config (
  id                     int  PRIMARY KEY,
  use_turn_endpoint      bool NOT NULL DEFAULT true,
  use_streaming_tts      bool NOT NULL DEFAULT true,
  use_lazy_stack         bool NOT NULL DEFAULT true,
  use_content_tree_rpc   bool NOT NULL DEFAULT true,
  updated_at             timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT app_config_single_row CHECK (id = 1)
);

INSERT INTO public.app_config (id) VALUES (1)
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

-- Everyone (anon + authenticated) can read flags; writes go through dashboard
-- service role only.
DROP POLICY IF EXISTS app_config_read_all ON public.app_config;
CREATE POLICY app_config_read_all ON public.app_config
  FOR SELECT
  TO anon, authenticated
  USING (true);
