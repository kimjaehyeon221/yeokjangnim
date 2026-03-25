-- 회원 탈퇴: 본인 JWT로만 호출 (SECURITY DEFINER).
-- Supabase SQL Editor에서 한 번 실행하세요.

create or replace function public.delete_own_account()
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  delete from public.stamps where user_id = uid;
  delete from public.user_badges where user_id = uid;
  delete from public.profiles where id = uid;

  delete from auth.users where id = uid;
  return true;
end;
$$;

revoke all on function public.delete_own_account() from public;
grant execute on function public.delete_own_account() to authenticated;
