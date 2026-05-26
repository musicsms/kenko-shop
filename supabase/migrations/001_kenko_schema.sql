create extension if not exists pgcrypto;

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  category text not null,
  price integer not null check (price >= 0),
  unit text not null,
  is_active boolean not null default true,
  origin_name text not null,
  origin_region text not null,
  origin_story text not null,
  harvest_label text not null,
  soil_score integer not null check (soil_score between 0 and 100),
  caption text not null,
  is_limited_drop boolean not null default false,
  drop_ends_at timestamptz,
  palette_background text not null,
  palette_primary text not null,
  palette_secondary text not null,
  palette_accent text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.product_nutrition_tags (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null constraint product_nutrition_tags_product_fk references public.products(id) on delete cascade,
  label text not null,
  value text not null,
  sort_order integer not null default 0
);

create table if not exists public.product_bundles (
  product_id uuid not null constraint product_bundles_product_fk references public.products(id) on delete cascade,
  related_product_id uuid not null constraint product_bundles_related_product_fk references public.products(id) on delete cascade,
  sort_order integer not null default 0,
  primary key (product_id, related_product_id),
  check (product_id <> related_product_id)
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_code text unique not null,
  customer_name text not null,
  customer_phone text not null,
  delivery_address text not null,
  note text,
  status text not null default 'new' check (status in ('new', 'confirmed', 'packed', 'delivered', 'cancelled')),
  subtotal integer not null check (subtotal >= 0),
  total integer not null check (total >= 0),
  created_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null constraint order_items_order_fk references public.orders(id) on delete cascade,
  product_id uuid constraint order_items_product_fk references public.products(id) on delete set null,
  product_name text not null,
  unit text not null,
  unit_price integer not null check (unit_price >= 0),
  quantity integer not null check (quantity > 0),
  line_total integer not null check (line_total >= 0)
);

create index if not exists products_active_created_idx on public.products (is_active, created_at desc);
create index if not exists product_nutrition_tags_product_sort_idx on public.product_nutrition_tags (product_id, sort_order);
create index if not exists product_bundles_product_sort_idx on public.product_bundles (product_id, sort_order);
create index if not exists product_bundles_related_product_idx on public.product_bundles (related_product_id);
create index if not exists orders_created_idx on public.orders (created_at desc);
create index if not exists orders_status_created_idx on public.orders (status, created_at desc);
create index if not exists order_items_order_idx on public.order_items (order_id);
create index if not exists order_items_product_idx on public.order_items (product_id);

alter table public.products enable row level security;
alter table public.product_nutrition_tags enable row level security;
alter table public.product_bundles enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

drop policy if exists "anon can read active products" on public.products;
create policy "anon can read active products"
on public.products
for select
to anon
using (is_active = true);

drop policy if exists "anon can read tags for active products" on public.product_nutrition_tags;
create policy "anon can read tags for active products"
on public.product_nutrition_tags
for select
to anon
using (
  exists (
    select 1
    from public.products p
    where p.id = product_nutrition_tags.product_id
      and p.is_active = true
  )
);

drop policy if exists "anon can read bundles for active products" on public.product_bundles;
create policy "anon can read bundles for active products"
on public.product_bundles
for select
to anon
using (
  exists (
    select 1
    from public.products p
    where p.id = product_bundles.product_id
      and p.is_active = true
  )
  and exists (
    select 1
    from public.products rp
    where rp.id = product_bundles.related_product_id
      and rp.is_active = true
  )
);

create or replace function public.create_guest_order(
  customer_name text,
  customer_phone text,
  delivery_address text,
  note text,
  items jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  trimmed_name text := btrim(customer_name);
  trimmed_phone text := btrim(customer_phone);
  trimmed_address text := btrim(delivery_address);
  order_id uuid := gen_random_uuid();
  order_code text := 'KF-' || upper(substr(encode(gen_random_bytes(6), 'hex'), 1, 10));
  computed_total integer := 0;
  item jsonb;
  item_slug text;
  item_quantity_text text;
  item_quantity integer;
  product_row public.products%rowtype;
  line_total integer;
begin
  if coalesce(trimmed_name, '') = '' then
    raise exception 'customer_name_required' using errcode = '22023';
  end if;

  if coalesce(trimmed_phone, '') = '' then
    raise exception 'customer_phone_required' using errcode = '22023';
  end if;

  if coalesce(trimmed_address, '') = '' then
    raise exception 'delivery_address_required' using errcode = '22023';
  end if;

  if coalesce(jsonb_typeof(items), '') <> 'array' then
    raise exception 'items_required' using errcode = '22023';
  end if;

  if jsonb_array_length(items) = 0 then
    raise exception 'items_required' using errcode = '22023';
  end if;

  insert into public.orders (
    id,
    order_code,
    customer_name,
    customer_phone,
    delivery_address,
    note,
    subtotal,
    total
  )
  values (
    order_id,
    order_code,
    trimmed_name,
    trimmed_phone,
    trimmed_address,
    nullif(btrim(note), ''),
    0,
    0
  );

  for item in select value from jsonb_array_elements(items)
  loop
    item_slug := btrim(item->>'product_slug');

    if coalesce(item_slug, '') = '' then
      raise exception 'product_slug_required' using errcode = '22023';
    end if;

    item_quantity_text := item->>'quantity';

    if coalesce(jsonb_typeof(item->'quantity'), '') <> 'number'
      or coalesce(item_quantity_text, '') !~ '^[0-9]+$'
      or length(item_quantity_text) > 2 then
      raise exception 'invalid_quantity' using errcode = '22023';
    end if;

    item_quantity := item_quantity_text::integer;

    if item_quantity <= 0 or item_quantity > 99 then
      raise exception 'invalid_quantity' using errcode = '22023';
    end if;

    select *
    into product_row
    from public.products
    where slug = item_slug
      and is_active = true;

    if product_row.id is null then
      raise exception 'product_not_found_or_inactive' using errcode = '22023';
    end if;

    line_total := product_row.price * item_quantity;
    computed_total := computed_total + line_total;

    insert into public.order_items (
      order_id,
      product_id,
      product_name,
      unit,
      unit_price,
      quantity,
      line_total
    )
    values (
      order_id,
      product_row.id,
      product_row.name,
      product_row.unit,
      product_row.price,
      item_quantity,
      line_total
    );
  end loop;

  update public.orders
  set subtotal = computed_total,
      total = computed_total
  where id = order_id;

  return jsonb_build_object(
    'order_id', order_id,
    'order_code', order_code,
    'total', computed_total,
    'status', 'new'
  );
end;
$$;

revoke all on function public.create_guest_order(text, text, text, text, jsonb) from public;
grant execute on function public.create_guest_order(text, text, text, text, jsonb) to anon;
