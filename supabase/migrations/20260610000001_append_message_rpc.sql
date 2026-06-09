-- append_message: persist a chat message in ONE round-trip.
--
-- The conversation screen previously did INSERT messages .. RETURNING followed
-- by UPDATE conversations.updated_at — two sequential client round-trips per
-- bubble. This RPC folds both into a single statement with data-modifying CTEs.
--
-- SECURITY INVOKER: RLS on public.messages / public.conversations still
-- applies, and the insert is additionally gated on conversation ownership so a
-- foreign conversation id silently inserts nothing (returns null).

create or replace function public.append_message(
  p_conversation_id uuid,
  p_role text,
  p_content text
)
returns uuid
language sql
security invoker
set search_path = public
as $$
  with ins as (
    insert into public.messages (conversation_id, user_id, role, content)
    select p_conversation_id, auth.uid(), p_role, p_content
    where p_role in ('user', 'assistant')
      and exists (
        select 1 from public.conversations c
        where c.id = p_conversation_id and c.user_id = auth.uid()
      )
    returning id
  ),
  touch as (
    update public.conversations
    set updated_at = now()
    where id = p_conversation_id
      and user_id = auth.uid()
      and exists (select 1 from ins)
  )
  select id from ins;
$$;

revoke all on function public.append_message(uuid, text, text) from public, anon;
grant execute on function public.append_message(uuid, text, text) to authenticated;
