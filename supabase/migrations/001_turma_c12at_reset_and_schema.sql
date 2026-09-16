-- Turma C12AT
-- Reuses Supabase Auth from the former Product Hub project.
-- Auth users are preserved. Product Hub application data is removed.

create extension if not exists pgcrypto;

-- Remove Product Hub application objects while keeping auth.users intact.
drop function if exists public.get_public_storefront(text);
drop function if exists public.create_workspace(text, text, text);
drop function if exists public.is_org_admin(uuid);
drop function if exists public.is_org_member(uuid);

drop table if exists public.analytics_events cascade;
drop table if exists public.product_images cascade;
drop table if exists public.products cascade;
drop table if exists public.categories cascade;
drop table if exists public.storefronts cascade;
drop table if exists public.organization_members cascade;
drop table if exists public.organizations cascade;

-- Existing profile records remain so existing Auth accounts keep their profile.
alter table public.profiles add column if not exists nickname text;
alter table public.profiles add column if not exists last_activity_at timestamptz;

-- Core class model.
create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  institution text,
  school_year text,
  invite_code text not null unique,
  created_by uuid not null references auth.users(id) on delete restrict,
  status text not null default 'active' check (status in ('active', 'suspended', 'archived')),
  settings jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.class_members (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'student' check (role in ('admin', 'teacher', 'student')),
  status text not null default 'pending' check (status in ('pending', 'approved', 'blocked', 'removed')),
  joined_at timestamptz,
  created_at timestamptz not null default now(),
  unique (class_id, user_id)
);

create unique index if not exists one_approved_class_per_user
  on public.class_members(user_id)
  where status = 'approved';

create index if not exists class_members_class_idx on public.class_members(class_id, status);
create index if not exists class_members_user_idx on public.class_members(user_id, status);

-- One collective conversation per class.
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete restrict,
  content text,
  message_type text not null default 'text' check (message_type in ('text','image','video','audio','pdf','document','file','location','system')),
  reply_to_id uuid references public.messages(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz,
  deleted_at timestamptz,
  check (content is not null or message_type <> 'text')
);

create index if not exists messages_class_created_idx on public.messages(class_id, created_at desc, id desc);

create table if not exists public.message_reactions (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  reaction text not null,
  created_at timestamptz not null default now(),
  unique (message_id, user_id, reaction)
);

create index if not exists message_reactions_message_idx on public.message_reactions(message_id, created_at);

create table if not exists public.attachments (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  file_name text not null,
  file_path text not null,
  file_type text not null,
  file_size bigint,
  mime_type text,
  created_at timestamptz not null default now()
);

create index if not exists attachments_message_idx on public.attachments(message_id);

-- Materials and AI processing.
create table if not exists public.materials (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  uploaded_by uuid not null references auth.users(id) on delete restrict,
  attachment_id uuid references public.attachments(id) on delete set null,
  title text not null,
  subject text not null default 'Other',
  description text,
  extracted_text text,
  content_hash text,
  processing_status text not null default 'PENDING' check (processing_status in ('PENDING','PROCESSING','COMPLETED','FAILED')),
  processing_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists materials_class_created_idx on public.materials(class_id, created_at desc);
create unique index if not exists materials_class_hash_idx on public.materials(class_id, content_hash) where content_hash is not null;

create table if not exists public.ai_analyses (
  id uuid primary key default gen_random_uuid(),
  material_id uuid not null references public.materials(id) on delete cascade,
  type text not null check (type in ('summary','simple_explanation','child_explanation','key_points','questions','qa','mindmap','glossary','exercises','quick_review')),
  content jsonb not null,
  model text,
  created_at timestamptz not null default now()
);

create index if not exists ai_analyses_material_idx on public.ai_analyses(material_id, created_at desc);

create table if not exists public.quizzes (
  id uuid primary key default gen_random_uuid(),
  material_id uuid not null references public.materials(id) on delete cascade,
  title text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.quiz_questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.quizzes(id) on delete cascade,
  question text not null,
  question_type text not null check (question_type in ('multiple_choice','true_false','short_answer','essay')),
  options jsonb,
  correct_answer text,
  explanation text,
  position integer not null default 0
);

create index if not exists quiz_questions_quiz_idx on public.quiz_questions(quiz_id, position);

create table if not exists public.quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.quizzes(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  score numeric(6,2),
  started_at timestamptz not null default now(),
  completed_at timestamptz
);

create index if not exists quiz_attempts_user_idx on public.quiz_attempts(user_id, started_at desc);

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete restrict,
  title text not null,
  content text not null,
  pinned boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists announcements_class_created_idx on public.announcements(class_id, created_at desc);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  body text not null,
  type text not null,
  read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists notifications_user_created_idx on public.notifications(user_id, created_at desc);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  message_id uuid references public.messages(id) on delete set null,
  material_id uuid references public.materials(id) on delete set null,
  type text not null,
  content text,
  status text not null default 'pending' check (status in ('pending','reviewed','resolved','dismissed')),
  admin_action text,
  created_at timestamptz not null default now()
);

create index if not exists reports_status_created_idx on public.reports(status, created_at desc);

-- Authorization helpers use database membership, never user metadata.
create or replace function public.is_class_member(target_class uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.class_members cm
    where cm.class_id = target_class
      and cm.user_id = auth.uid()
      and cm.status = 'approved'
  );
$$;

create or replace function public.is_class_staff(target_class uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.class_members cm
    where cm.class_id = target_class
      and cm.user_id = auth.uid()
      and cm.status = 'approved'
      and cm.role in ('admin','teacher')
  );
$$;

create or replace function public.is_class_admin(target_class uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.class_members cm
    where cm.class_id = target_class
      and cm.user_id = auth.uid()
      and cm.status = 'approved'
      and cm.role = 'admin'
  );
$$;

create or replace function public.my_class_id()
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select cm.class_id
  from public.class_members cm
  where cm.user_id = auth.uid() and cm.status = 'approved'
  order by cm.joined_at asc nulls last
  limit 1;
$$;

-- Keep the existing profile trigger for Auth users and refresh profile activity.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles(id, full_name, avatar_url)
  values (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url')
  on conflict (id) do update set
    full_name = coalesce(excluded.full_name, public.profiles.full_name),
    avatar_url = coalesce(excluded.avatar_url, public.profiles.avatar_url),
    updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- RLS: every exposed application table is protected.
alter table public.profiles enable row level security;
alter table public.classes enable row level security;
alter table public.class_members enable row level security;
alter table public.messages enable row level security;
alter table public.message_reactions enable row level security;
alter table public.attachments enable row level security;
alter table public.materials enable row level security;
alter table public.ai_analyses enable row level security;
alter table public.quizzes enable row level security;
alter table public.quiz_questions enable row level security;
alter table public.quiz_attempts enable row level security;
alter table public.announcements enable row level security;
alter table public.notifications enable row level security;
alter table public.reports enable row level security;

-- Profiles: class members may see the limited profile fields needed for the class UI.
create policy profiles_self_or_class_read on public.profiles
for select to authenticated
using (
  id = auth.uid()
  or exists (
    select 1 from public.class_members mine
    join public.class_members other on other.class_id = mine.class_id
    where mine.user_id = auth.uid() and mine.status = 'approved'
      and other.user_id = profiles.id and other.status = 'approved'
  )
);

create policy profiles_self_update on public.profiles
for update to authenticated
using (id = auth.uid())
with check (id = auth.uid());

create policy classes_member_read on public.classes
for select to authenticated
using (public.is_class_member(id));

create policy class_members_member_read on public.class_members
for select to authenticated
using (public.is_class_member(class_id));

create policy class_members_admin_manage on public.class_members
for all to authenticated
using (public.is_class_admin(class_id))
with check (public.is_class_admin(class_id));

create policy messages_member_read on public.messages
for select to authenticated
using (public.is_class_member(class_id));

create policy messages_member_insert on public.messages
for insert to authenticated
with check (public.is_class_member(class_id) and sender_id = auth.uid());

create policy messages_sender_update on public.messages
for update to authenticated
using (sender_id = auth.uid() and public.is_class_member(class_id))
with check (sender_id = auth.uid() and public.is_class_member(class_id));

create policy messages_sender_delete on public.messages
for delete to authenticated
using (sender_id = auth.uid() and public.is_class_member(class_id));

create policy reactions_member_read on public.message_reactions
for select to authenticated
using (exists (select 1 from public.messages m where m.id = message_id and public.is_class_member(m.class_id)));

create policy reactions_member_insert on public.message_reactions
for insert to authenticated
with check (user_id = auth.uid() and exists (select 1 from public.messages m where m.id = message_id and public.is_class_member(m.class_id)));

create policy reactions_self_delete on public.message_reactions
for delete to authenticated
using (user_id = auth.uid());

create policy attachments_member_read on public.attachments
for select to authenticated
using (exists (select 1 from public.messages m where m.id = message_id and public.is_class_member(m.class_id)));

create policy attachments_sender_insert on public.attachments
for insert to authenticated
with check (exists (select 1 from public.messages m where m.id = message_id and m.sender_id = auth.uid() and public.is_class_member(m.class_id)));

create policy materials_member_read on public.materials
for select to authenticated
using (public.is_class_member(class_id));

create policy materials_member_insert on public.materials
for insert to authenticated
with check (public.is_class_member(class_id) and uploaded_by = auth.uid());

create policy materials_staff_update on public.materials
for update to authenticated
using (public.is_class_staff(class_id))
with check (public.is_class_staff(class_id));

create policy analyses_member_read on public.ai_analyses
for select to authenticated
using (exists (select 1 from public.materials m where m.id = material_id and public.is_class_member(m.class_id)));

create policy quizzes_member_read on public.quizzes
for select to authenticated
using (exists (select 1 from public.materials m where m.id = material_id and public.is_class_member(m.class_id)));

create policy quiz_questions_member_read on public.quiz_questions
for select to authenticated
using (exists (
  select 1 from public.quizzes q
  join public.materials m on m.id = q.material_id
  where q.id = quiz_id and public.is_class_member(m.class_id)
));

create policy quiz_attempts_self_read on public.quiz_attempts
for select to authenticated
using (user_id = auth.uid());

create policy quiz_attempts_self_insert on public.quiz_attempts
for insert to authenticated
with check (user_id = auth.uid());

create policy quiz_attempts_self_update on public.quiz_attempts
for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy announcements_member_read on public.announcements
for select to authenticated
using (public.is_class_member(class_id));

create policy announcements_staff_manage on public.announcements
for all to authenticated
using (public.is_class_staff(class_id))
with check (public.is_class_staff(class_id) and created_by = auth.uid());

create policy notifications_self_read on public.notifications
for select to authenticated
using (user_id = auth.uid());

create policy notifications_self_update on public.notifications
for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy reports_self_insert on public.reports
for insert to authenticated
with check (reporter_id = auth.uid());

create policy reports_self_read on public.reports
for select to authenticated
using (reporter_id = auth.uid() or exists (
  select 1 from public.class_members cm
  where cm.user_id = auth.uid() and cm.status = 'approved' and cm.role = 'admin'
));

-- Realtime publication for the collaborative parts of the app.
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.message_reactions;
alter publication supabase_realtime add table public.class_members;
alter publication supabase_realtime add table public.announcements;
alter publication supabase_realtime add table public.materials;
alter publication supabase_realtime add table public.ai_analyses;
alter publication supabase_realtime add table public.notifications;
