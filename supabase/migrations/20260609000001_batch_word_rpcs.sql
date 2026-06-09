-- Batch word RPCs: collapse N client round-trips into 1.
--
-- 1) add_words_batch: AI topic-generation inserts words one-by-one today
--    (N parallel INSERTs). Single INSERT .. ON CONFLICT DO NOTHING handles
--    dedup against the expression index unique_word_per_user (which PostgREST
--    upsert can't target because it uses lower(word)).
--
-- 2) commit_word_reviews: flashcard session commit issues one UPDATE per
--    reviewed word. Single statement via jsonb_to_recordset.
--
-- Both are SECURITY INVOKER: RLS on public.words still applies, and every
-- row is additionally pinned to auth.uid().

create or replace function public.add_words_batch(p_words jsonb)
returns table (id uuid, word text)
language sql
security invoker
set search_path = public
as $$
  insert into public.words (user_id, word, translation, next_review)
  select auth.uid(),
         btrim(w.word),
         coalesce(btrim(w.translation), ''),
         current_date
  from jsonb_to_recordset(p_words) as w(word text, translation text)
  where btrim(coalesce(w.word, '')) <> ''
  on conflict do nothing
  returning words.id, words.word;
$$;

create or replace function public.commit_word_reviews(p_reviews jsonb)
returns void
language sql
security invoker
set search_path = public
as $$
  update public.words w
  set ease_factor   = r.ease_factor,
      interval_days = r.interval_days,
      repetitions   = r.repetitions,
      next_review   = r.next_review
  from jsonb_to_recordset(p_reviews)
         as r(id uuid, ease_factor float, interval_days int,
              repetitions int, next_review date)
  where w.id = r.id
    and w.user_id = auth.uid();
$$;

revoke all on function public.add_words_batch(jsonb) from public, anon;
revoke all on function public.commit_word_reviews(jsonb) from public, anon;
grant execute on function public.add_words_batch(jsonb) to authenticated;
grant execute on function public.commit_word_reviews(jsonb) to authenticated;
