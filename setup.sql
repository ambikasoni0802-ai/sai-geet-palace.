-- Run this whole file in Supabase > SQL Editor
create table bookings(
 id uuid primary key default gen_random_uuid(), created_at timestamptz default now(),
 flat_no text not null, name text not null, father_name text, dob date, gender text, occupation text,
 phone text not null, alt_phone text, email text, address text, city text, state text, pincode text,
 aadhaar text, pan text, payment_mode text, amount numeric, status text default 'pending',
 aadhaar_file text, pan_file text, photo_file text);
create unique index one_active_booking on bookings(flat_no) where status<>'cancelled';
create table appointments(
 id uuid primary key default gen_random_uuid(), created_at timestamptz default now(),
 name text not null, phone text not null, purpose text, interested_in text, appt_date date, time_slot text, message text, status text default 'pending');
create table booked_flats(flat_no text primary key);
alter table bookings enable row level security;
alter table appointments enable row level security;
alter table booked_flats enable row level security;
create policy "public insert bookings" on bookings for insert to anon with check (status='pending');
create policy "admin bookings" on bookings for all to authenticated using(true) with check(true);
create policy "public insert appts" on appointments for insert to anon with check (status='pending');
create policy "admin appts" on appointments for all to authenticated using(true) with check(true);
create policy "read booked flats" on booked_flats for select to anon, authenticated using(true);
create function sync_booked() returns trigger language plpgsql security definer set search_path=public as $$
begin
 if tg_op='DELETE' then delete from booked_flats where flat_no=old.flat_no; return null; end if;
 if new.status='cancelled' then delete from booked_flats where flat_no=new.flat_no;
 else insert into booked_flats values(new.flat_no) on conflict do nothing; end if;
 return null;
end $$;
create trigger t_sync after insert or update or delete on bookings for each row execute function sync_booked();
insert into storage.buckets(id,name,public) values('documents','documents',false);
create policy "anon upload docs" on storage.objects for insert to anon, authenticated with check (bucket_id='documents');
create policy "admin read docs" on storage.objects for select to authenticated using (bucket_id='documents');
