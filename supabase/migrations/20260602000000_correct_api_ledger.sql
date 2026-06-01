-- Add missing rate limit columns for new actions.
ALTER TABLE public.api_usage
  ADD COLUMN IF NOT EXISTS turn_count integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS enrich_count integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS generate_scenario_count integer NOT NULL DEFAULT 0;

-- Update the increment function to support the new columns
CREATE OR REPLACE FUNCTION public.incr_api_usage(
  p_user_id uuid,
  p_action  text
) RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  new_count integer;
  today     date := ((now() AT TIME ZONE 'UTC')::date);
BEGIN
  IF p_action NOT IN ('chat', 'evaluate', 'transcribe', 'turn', 'enrich', 'generate-scenario') THEN
    RAISE EXCEPTION 'invalid action: %', p_action USING ERRCODE = '22023';
  END IF;

  IF p_action = 'chat' THEN
    INSERT INTO public.api_usage (user_id, usage_date, chat_count)
    VALUES (p_user_id, today, 1)
    ON CONFLICT (user_id, usage_date) DO UPDATE
      SET chat_count = api_usage.chat_count + 1,
          updated_at = now()
    RETURNING chat_count INTO new_count;
  ELSIF p_action = 'evaluate' THEN
    INSERT INTO public.api_usage (user_id, usage_date, evaluate_count)
    VALUES (p_user_id, today, 1)
    ON CONFLICT (user_id, usage_date) DO UPDATE
      SET evaluate_count = api_usage.evaluate_count + 1,
          updated_at = now()
    RETURNING evaluate_count INTO new_count;
  ELSIF p_action = 'transcribe' THEN
    INSERT INTO public.api_usage (user_id, usage_date, transcribe_count)
    VALUES (p_user_id, today, 1)
    ON CONFLICT (user_id, usage_date) DO UPDATE
      SET transcribe_count = api_usage.transcribe_count + 1,
          updated_at = now()
    RETURNING transcribe_count INTO new_count;
  ELSIF p_action = 'turn' THEN
    INSERT INTO public.api_usage (user_id, usage_date, turn_count)
    VALUES (p_user_id, today, 1)
    ON CONFLICT (user_id, usage_date) DO UPDATE
      SET turn_count = api_usage.turn_count + 1,
          updated_at = now()
    RETURNING turn_count INTO new_count;
  ELSIF p_action = 'enrich' THEN
    INSERT INTO public.api_usage (user_id, usage_date, enrich_count)
    VALUES (p_user_id, today, 1)
    ON CONFLICT (user_id, usage_date) DO UPDATE
      SET enrich_count = api_usage.enrich_count + 1,
          updated_at = now()
    RETURNING enrich_count INTO new_count;
  ELSIF p_action = 'generate-scenario' THEN
    INSERT INTO public.api_usage (user_id, usage_date, generate_scenario_count)
    VALUES (p_user_id, today, 1)
    ON CONFLICT (user_id, usage_date) DO UPDATE
      SET generate_scenario_count = api_usage.generate_scenario_count + 1,
          updated_at = now()
    RETURNING generate_scenario_count INTO new_count;
  END IF;

  RETURN new_count;
END;
$$;
