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
 consent_by text not null check (consent_by = 'student_18_or_parent_guardian'),
 created_at timestamptz not null default now()
);
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
