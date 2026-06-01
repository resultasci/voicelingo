-- Single-RPC content tree (courses → units → lessons) — replaces the 3-roundtrip
-- pattern in `courses_service.dart`. Returns a single JSONB blob the client
-- decodes lazily. STABLE so postgres can cache between calls in the same tx.
--
-- The function is filterable by language; the app only loads English content
-- today but other targets may follow.

CREATE OR REPLACE FUNCTION public.get_content_tree(p_language text DEFAULT 'en')
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT COALESCE(
    jsonb_agg(course_row ORDER BY (course_row->>'order_index')::int),
    '[]'::jsonb
  )
  FROM (
    SELECT
      jsonb_build_object(
        'id', c.id,
        'language', c.language,
        'level', c.level,
        'order_index', c.order_index,
        'units', COALESCE(
          (
            SELECT jsonb_agg(unit_row ORDER BY (unit_row->>'order_index')::int)
            FROM (
              SELECT
                jsonb_build_object(
                  'id', u.id,
                  'course_id', u.course_id,
                  'order_index', u.order_index,
                  'title_tr', u.title_tr,
                  'title_en', u.title_en,
                  'theme', u.theme,
                  'prerequisite_unit_id', u.prerequisite_unit_id,
                  'lessons', COALESCE(
                    (
                      SELECT jsonb_agg(
                        jsonb_build_object(
                          'id', l.id,
                          'unit_id', l.unit_id,
                          'order_index', l.order_index,
                          'type', l.type,
                          'title_tr', l.title_tr,
                          'title_en', l.title_en,
                          'content', l.content,
                          'xp_reward', l.xp_reward
                        ) ORDER BY l.order_index
                      )
                      FROM public.lessons l WHERE l.unit_id = u.id
                    ),
                    '[]'::jsonb
                  )
                ) AS unit_row
              FROM public.units u WHERE u.course_id = c.id
            ) AS units_agg
          ),
          '[]'::jsonb
        )
      ) AS course_row
    FROM public.courses c
    WHERE c.language = p_language
  ) AS courses_agg;
$$;

GRANT EXECUTE ON FUNCTION public.get_content_tree(text) TO anon, authenticated;
