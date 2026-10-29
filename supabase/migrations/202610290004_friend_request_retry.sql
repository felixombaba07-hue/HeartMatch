-- Allow a sender to retry a pending/declined friend request without granting
-- permission to accept requests on behalf of the recipient.
drop policy if exists "Sender can retry own friend request" on public.friend_requests;
create policy "Sender can retry own friend request"
  on public.friend_requests
  for update
  to authenticated
  using (auth.uid() = sender_id and status in ('pending', 'declined'))
  with check (auth.uid() = sender_id and status = 'pending');
