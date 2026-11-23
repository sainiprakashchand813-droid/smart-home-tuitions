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
create policy "Public can submit test results" on public.test_results for insert to anon with check (
 char_length(trim(student_name)) between 1 and 40 and class_level between 9 and 12
 and char_length(subject) between 1 and 60 and score >= 0
 and total_questions between 1 and 100 and score <= total_questions and accuracy between 0 and 100
);
create policy "Public can view leaderboard" on public.test_results for select to anon using (true);
grant usage on schema public to anon;
grant insert, select on public.test_results to anon;
grant usage, select on sequence public.test_results_id_seq to anon;