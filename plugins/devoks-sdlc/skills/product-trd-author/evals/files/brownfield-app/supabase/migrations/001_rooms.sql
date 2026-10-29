create table rooms (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  floor int not null,
  capacity int not null,
  active boolean not null default true
);
