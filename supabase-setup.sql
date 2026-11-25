create table if not exists public.test_results (
 id bigint generated always as identity primary key,
 student_name text not null check (char_length(student_name) between 1 and 40),
 class_level integer not null check (class_level between 9 and 12),
 subject text not null check (char_length(subject) between 1 and 60),
 score integer not null check (score >= 0),
 total_questions integer not null check (total_questions between 1 and 100 and score <= total_questions),
 accuracy integer not null check (accuracy between 0 and 100),
 created_at timestamptz not null default now()
);
create index if not exists test_results_weekly_idx on public.test_results (created_at desc, score desc);
alter table public.test_results enable row level security;
drop policy if exists "Public can submit test results" on public.test_results;
drop policy if exists "Public can view leaderboard" on public.test_results;
create policy "Public can submit test results" on public.test_results for insert to anon with check (
 char_length(trim(student_name)) between 1 and 40 and class_level between 9 and 12
 and char_length(subject) between 1 and 60 and score >= 0
 and total_questions between 1 and 100 and score <= total_questions and accuracy between 0 and 100
);
create policy "Public can view leaderboard" on public.test_results for select to anon using (true);
grant usage on schema public to anon;
grant insert, select on public.test_results to anon;
grant usage, select on sequence public.test_results_id_seq to anon;

-- Student registrations for free material and online tests.
-- Public visitors can submit registrations; personal data is not publicly readable.
create table if not exists public.student_leads (
 id bigint generated always as identity primary key,
 student_name text not null check (char_length(trim(student_name)) between 1 and 80),
 mobile_number text not null check (mobile_number ~ '^[6-9][0-9]{9}$'),
 board text not null check (board in ('RBSE','CBSE','Other')),
 class_level text not null check (char_length(class_level) between 1 and 30),
 city text not null check (char_length(city) between 1 and 80),
 address text not null check (char_length(trim(address)) between 2 and 180),
 resource text not null check (char_length(resource) between 1 and 100),
 consent boolean not null default false check (consent = true),
 consent_by text not null check (consent_by = 'student_or_guardian'),
 created_at timestamptz not null default now()
);
alter table public.student_leads drop constraint if exists student_leads_consent_by_check;
alter table public.student_leads add constraint student_leads_consent_by_check check (consent_by = 'student_or_guardian');
alter table public.student_leads enable row level security;
drop policy if exists "Visitors can register students" on public.student_leads;
create policy "Visitors can register students" on public.student_leads
for insert to anon
with check (
 consent = true
 and mobile_number ~ '^[6-9][0-9]{9}$'
 and char_length(trim(student_name)) between 1 and 80
);
grant usage on schema public to anon;
grant insert on public.student_leads to anon;

-- Parent home-tuition enquiries from the website.
-- Safe to run more than once. Public visitors can INSERT only; no public SELECT.
create table if not exists public.home_tuition_leads (
 id bigint generated always as identity primary key,
 parent_name text not null,
 mobile_number text not null,
 class_level text not null,
 preferred_time text not null default '',
 city text not null default 'Jaipur',
 address text not null default '',
 subject text not null default '',
 demo_requested boolean not null default false,
 source_page text not null default 'homepage',
 source_url text not null default '',
 created_at timestamptz not null default now()
);

-- Add any newer columns when this table already exists from an earlier setup.
alter table public.home_tuition_leads
 add column if not exists preferred_time text not null default '',
 add column if not exists city text not null default 'Jaipur',
 add column if not exists address text not null default '',
 add column if not exists subject text not null default '',
 add column if not exists demo_requested boolean not null default false,
 add column if not exists source_page text not null default 'homepage',
 add column if not exists source_url text not null default '',
 add column if not exists created_at timestamptz not null default now();

alter table public.home_tuition_leads enable row level security;
drop policy if exists "Visitors can submit home tuition enquiries" on public.home_tuition_leads;
create policy "Visitors can submit home tuition enquiries"
 on public.home_tuition_leads
 for insert to anon
 with check (
  char_length(trim(parent_name)) between 1 and 100
  and mobile_number ~ '^[6-9][0-9]{9}$'
  and char_length(class_level) between 1 and 80
  and char_length(city) between 1 and 80
 );
grant usage on schema public to anon;
grant insert on public.home_tuition_leads to anon;


-- Admin lead dashboard fields and access.
-- Create the admin user manually in Supabase Authentication > Users.
-- Keep public sign-ups disabled. Only authenticated users can read/update lead records.
alter table public.home_tuition_leads
 add column if not exists status text not null default 'New',
 add column if not exists follow_up_date date,
 add column if not exists notes text not null default '',
 add column if not exists updated_at timestamptz not null default now();

alter table public.student_leads
 add column if not exists status text not null default 'New',
 add column if not exists follow_up_date date,
 add column if not exists notes text not null default '',
 add column if not exists updated_at timestamptz not null default now();

alter table public.home_tuition_leads
 drop constraint if exists home_tuition_leads_status_check;
alter table public.home_tuition_leads
 add constraint home_tuition_leads_status_check
 check (status in ('New','Contacted','Demo Scheduled','Converted','Not Interested'));

alter table public.student_leads
 drop constraint if exists student_leads_status_check;
alter table public.student_leads
 add constraint student_leads_status_check
 check (status in ('New','Contacted','Demo Scheduled','Converted','Not Interested'));

drop policy if exists "Admins can read home tuition enquiries" on public.home_tuition_leads;
create policy "Admins can read home tuition enquiries"
 on public.home_tuition_leads for select to authenticated using (true);
drop policy if exists "Admins can update home tuition enquiries" on public.home_tuition_leads;
create policy "Admins can update home tuition enquiries"
 on public.home_tuition_leads for update to authenticated using (true) with check (true);

drop policy if exists "Admins can read student leads" on public.student_leads;
create policy "Admins can read student leads"
 on public.student_leads for select to authenticated using (true);
drop policy if exists "Admins can update student leads" on public.student_leads;
create policy "Admins can update student leads"
 on public.student_leads for update to authenticated using (true) with check (true);

drop policy if exists "Admins can read test results" on public.test_results;
create policy "Admins can read test results"
 on public.test_results for select to authenticated using (true);

grant select, update on public.home_tuition_leads to authenticated;
grant select, update on public.student_leads to authenticated;
grant select on public.test_results to authenticated;
