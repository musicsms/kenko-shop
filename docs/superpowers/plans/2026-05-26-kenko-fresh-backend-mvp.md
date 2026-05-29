# Kenko Fresh Backend MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert Kenko Fresh from an offline Flutter prototype into a Supabase self-host Docker MVP with remote products and guest checkout through a secure RPC.

**Architecture:** Vendor the official Supabase Docker self-host assets into `supabase/`, add project SQL migrations for products/orders/RLS/RPC, and integrate Flutter through a repository layer. The app keeps offline fixtures as fallback when Supabase config is missing, while configured builds use remote products and guest order creation.

**Tech Stack:** Flutter 3.41.9, Dart 3.11.5, Supabase Flutter client, Supabase self-host Docker Compose, Postgres SQL, Row-Level Security, Postgres `security definer` RPC.

---

## File Structure

- `.gitignore`: ignore local Supabase secrets and generated volumes.
- `pubspec.yaml`: add Supabase client dependency.
- `supabase/`: official self-host Docker assets copied from `supabase/supabase/docker`.
- `supabase/.env.example`: committed example env copied from upstream, reviewed so it contains no real project secrets.
- `supabase/migrations/001_kenko_schema.sql`: Kenko tables, indexes, RLS, and `create_guest_order`.
- `supabase/migrations/002_seed_products.sql`: seed six products matching existing fixture content.
- `supabase/README.md`: local run and migration instructions.
- `lib/config/app_config.dart`: reads `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
- `lib/data/product_repository.dart`: offline/remote product loading.
- `lib/data/order_repository.dart`: guest checkout RPC payload and response mapping.
- `lib/models/guest_order.dart`: guest checkout input and item payloads.
- `lib/models/order_result.dart`: RPC response model.
- `lib/models/product.dart`: JSON hydration helpers for Supabase rows.
- `lib/state/product_feed_store.dart`: async product loading state.
- `lib/app/kenko_app.dart`: app root owns product feed store and repositories.
- `lib/screens/fresh_feed_screen.dart`: loading/error/empty states and remote product feed.
- `lib/widgets/cart_sheet.dart`: guest checkout form and submit flow.
- `test/data/product_repository_test.dart`: product JSON mapping/fallback tests.
- `test/data/order_repository_test.dart`: RPC payload/response tests with fake client.
- `test/state/product_feed_store_test.dart`: loading/error states.
- `test/screens/fresh_feed_screen_test.dart`: updated feed/checkout widget tests.

## Task 1: Vendor Supabase Self-Host Assets

**Files:**
- Modify: `.gitignore`
- Create/Modify: `supabase/docker-compose.yml`
- Create/Modify: `supabase/.env.example`
- Create: `supabase/README.md`
- Create: `supabase/migrations/.gitkeep`

- [ ] **Step 1: Add Supabase local ignores**

Update `.gitignore` with:

```gitignore
supabase/.env
supabase/volumes/
supabase/.branches/
```

- [ ] **Step 2: Copy official Docker assets**

Run from repo root:

```bash
rm -rf /tmp/kenko-supabase-upstream
git clone --depth 1 https://github.com/supabase/supabase /tmp/kenko-supabase-upstream
mkdir -p supabase
cp -R /tmp/kenko-supabase-upstream/docker/. supabase/
mkdir -p supabase/migrations
touch supabase/migrations/.gitkeep
```

Expected:

- `supabase/docker-compose.yml` exists.
- `supabase/.env.example` exists.
- `supabase/volumes/` may exist but is ignored except any upstream placeholder files already committed by copy.

- [ ] **Step 3: Verify official compose syntax**

Run:

```bash
cd supabase
docker compose --env-file .env.example config >/tmp/kenko-supabase-compose.yml
```

Expected: command exits `0`. If Docker Compose is not installed, record the exact error and continue only with files committed.

- [ ] **Step 4: Add Supabase README**

Create `supabase/README.md`:

````markdown
# Kenko Fresh Supabase

This directory contains the self-hosted Supabase Docker stack and Kenko Fresh database migrations.

## Setup

```bash
cp .env.example .env
```

Edit `.env` before starting the stack. Do not run production or shared environments with the placeholder secrets from `.env.example`.

## Start

```bash
docker compose up -d
docker compose ps
```

Studio is exposed through the Supabase API gateway. Use the host and ports configured by the vendored Supabase Docker files.

## Apply Kenko Migrations

After the database is healthy, apply migrations with `psql` using the Postgres connection details from `.env`:

```bash
psql "$POSTGRES_URL" -f migrations/001_kenko_schema.sql
psql "$POSTGRES_URL" -f migrations/002_seed_products.sql
```

If using the default Docker network from this directory, you can also run `psql` from a Postgres client container or host-installed client.

## Flutter

Run the app with:

```bash
flutter run \
  --dart-define=SUPABASE_URL=http://localhost:8000 \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

For Android emulators, replace `localhost` with `10.0.2.2` or a reachable host IP.
````

- [ ] **Step 5: Verify repo hygiene**

Run:

```bash
git status --short
git check-ignore -v supabase/.env
git check-ignore -v supabase/volumes
```

Expected: `.env` and volumes paths are ignored; no real `.env` is staged.

- [ ] **Step 6: Commit**

```bash
git add .gitignore supabase
git commit -m "Add Supabase self-host scaffold"
```

## Task 2: Add Database Schema, RLS, And Checkout RPC

**Files:**
- Create: `supabase/migrations/001_kenko_schema.sql`
- Create: `supabase/tests/create_guest_order.sql`

- [ ] **Step 1: Create schema migration**

Create `supabase/migrations/001_kenko_schema.sql`:

```sql
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
    select 1 from public.products p
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
    select 1 from public.products p
    where p.id = product_bundles.product_id
      and p.is_active = true
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

  if jsonb_typeof(items) <> 'array' or jsonb_array_length(items) = 0 then
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
    item_slug := item->>'product_slug';
    item_quantity := (item->>'quantity')::integer;

    if coalesce(item_slug, '') = '' then
      raise exception 'product_slug_required' using errcode = '22023';
    end if;

    if item_quantity is null or item_quantity <= 0 or item_quantity > 99 then
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
```

- [ ] **Step 2: Add RPC smoke SQL**

Create `supabase/tests/create_guest_order.sql`:

```sql
select public.create_guest_order(
  'Test Customer',
  '0900000000',
  '123 Test Street',
  'Leave at door',
  '[{"product_slug":"bok-choy","quantity":2}]'::jsonb
) as result;

select count(*) as created_orders
from public.orders
where customer_phone = '0900000000';
```

- [ ] **Step 3: Validate SQL syntax**

If Postgres is available:

```bash
psql "$POSTGRES_URL" -v ON_ERROR_STOP=1 -f supabase/migrations/001_kenko_schema.sql
```

Expected: migration applies without error.

If Postgres is not available, run a static check:

```bash
python3 - <<'PY'
from pathlib import Path
sql = Path('supabase/migrations/001_kenko_schema.sql').read_text()
required = [
    'create table if not exists public.products',
    'alter table public.orders enable row level security',
    'security definer',
    'set search_path = public',
    'grant execute on function public.create_guest_order',
]
missing = [item for item in required if item not in sql]
if missing:
    raise SystemExit(f'missing: {missing}')
PY
```

- [ ] **Step 4: Commit schema**

```bash
git add supabase/migrations/001_kenko_schema.sql supabase/tests/create_guest_order.sql
git commit -m "Add Kenko Supabase schema"
```

## Task 3: Seed Products

**Files:**
- Create: `supabase/migrations/002_seed_products.sql`

- [ ] **Step 1: Create seed migration**

Create `supabase/migrations/002_seed_products.sql` with deterministic product IDs and the six existing products:

```sql
insert into public.products (
  id,
  slug,
  name,
  category,
  price,
  unit,
  origin_name,
  origin_region,
  origin_story,
  harvest_label,
  soil_score,
  caption,
  is_limited_drop,
  drop_ends_at,
  palette_background,
  palette_primary,
  palette_secondary,
  palette_accent
) values
('11111111-1111-4111-8111-111111111111', 'bok-choy', 'Da Lat Baby Bok Choy', 'Greens', 42000, '300g', 'Moc Chau Morning Farm', 'Da Lat Highlands', 'Cut before sunrise and packed in reusable cold crates.', 'Harvested 06:10', 96, 'Crisp stems, sweet leaf, perfect for garlic stir-fry.', true, now() + interval '8 hours', '#101510', '#7FBF66', '#DCEB99', '#F2C35B'),
('22222222-2222-4222-8222-222222222222', 'dragon-fruit', 'Red Dragon Fruit', 'Fruit', 68000, '2 pcs', 'Binh Thuan Sun Field', 'Binh Thuan', 'Naturally ripened on the plant with no wax coating.', 'Harvested yesterday', 91, 'Cold, bright, and built for smoothie bowls.', false, null, '#1B1116', '#FF5C7A', '#FFD1DC', '#74C365'),
('33333333-3333-4333-8333-333333333333', 'golden-carrot', 'Golden Soil Carrot', 'Roots', 55000, '500g', 'Red Earth Co-op', 'Don Duong', 'Grown in mineral-rich red soil and washed by hand.', 'Pulled 09:25', 94, 'Snack sweet, soup ready, kid approved.', true, now() + interval '6 hours', '#17120E', '#E69035', '#FFD88A', '#6FA65F'),
('44444444-4444-4444-8444-444444444444', 'purple-basil', 'Purple Basil Bunch', 'Herbs', 28000, '80g', 'An Nhien Herb Garden', 'Gia Lam', 'Small-batch herb beds watered before dawn.', 'Cut 05:50', 89, 'Aromatic lift for salads, noodles, and grilled veg.', false, null, '#151019', '#8E5AC7', '#CDA8FF', '#7FBF66'),
('55555555-5555-4555-8555-555555555555', 'king-oyster', 'King Oyster Mushroom', 'Mushrooms', 72000, '250g', 'North Cloud Grow House', 'Sa Pa', 'Slow-grown in a cool controlled room for dense texture.', 'Picked 07:40', 92, 'Meaty slices for pan sear, broth, or vegan steak.', false, null, '#121417', '#D9C7A3', '#F3E7CE', '#9AC46A'),
('66666666-6666-4666-8666-666666666666', 'organic-box', 'Surprise Organic Box', 'Box', 189000, '6 items', 'Kenko Curated Farms', 'Rotating farms', 'A daily box built from the best harvest window.', 'Packed today', 95, 'Limited fresh drop for cooks who like surprises.', true, now() + interval '10 hours', '#16120B', '#FF6048', '#F2C35B', '#6FA65F')
on conflict (slug) do update set
  name = excluded.name,
  category = excluded.category,
  price = excluded.price,
  unit = excluded.unit,
  origin_name = excluded.origin_name,
  origin_region = excluded.origin_region,
  origin_story = excluded.origin_story,
  harvest_label = excluded.harvest_label,
  soil_score = excluded.soil_score,
  caption = excluded.caption,
  is_limited_drop = excluded.is_limited_drop,
  drop_ends_at = excluded.drop_ends_at,
  palette_background = excluded.palette_background,
  palette_primary = excluded.palette_primary,
  palette_secondary = excluded.palette_secondary,
  palette_accent = excluded.palette_accent,
  updated_at = now();

delete from public.product_nutrition_tags;
insert into public.product_nutrition_tags (product_id, label, value, sort_order) values
('11111111-1111-4111-8111-111111111111', 'Fiber', 'High', 1),
('11111111-1111-4111-8111-111111111111', 'Vitamin K', 'Rich', 2),
('22222222-2222-4222-8222-222222222222', 'Antioxidants', 'Bright', 1),
('22222222-2222-4222-8222-222222222222', 'Sugar', 'Natural', 2),
('33333333-3333-4333-8333-333333333333', 'Beta carotene', 'High', 1),
('33333333-3333-4333-8333-333333333333', 'Crunch', 'Firm', 2),
('44444444-4444-4444-8444-444444444444', 'Aroma', 'Strong', 1),
('44444444-4444-4444-8444-444444444444', 'Polyphenols', 'Good', 2),
('55555555-5555-4555-8555-555555555555', 'Protein', 'Plant', 1),
('55555555-5555-4555-8555-555555555555', 'Umami', 'Deep', 2),
('66666666-6666-4666-8666-666666666666', 'Variety', '6 picks', 1),
('66666666-6666-4666-8666-666666666666', 'Waste', 'Low', 2);

delete from public.product_bundles;
insert into public.product_bundles (product_id, related_product_id, sort_order) values
('11111111-1111-4111-8111-111111111111', '55555555-5555-4555-8555-555555555555', 1),
('11111111-1111-4111-8111-111111111111', '44444444-4444-4444-8444-444444444444', 2),
('22222222-2222-4222-8222-222222222222', '66666666-6666-4666-8666-666666666666', 1),
('33333333-3333-4333-8333-333333333333', '44444444-4444-4444-8444-444444444444', 1),
('33333333-3333-4333-8333-333333333333', '66666666-6666-4666-8666-666666666666', 2),
('44444444-4444-4444-8444-444444444444', '11111111-1111-4111-8111-111111111111', 1),
('44444444-4444-4444-8444-444444444444', '55555555-5555-4555-8555-555555555555', 2),
('55555555-5555-4555-8555-555555555555', '11111111-1111-4111-8111-111111111111', 1),
('55555555-5555-4555-8555-555555555555', '33333333-3333-4333-8333-333333333333', 2),
('66666666-6666-4666-8666-666666666666', '11111111-1111-4111-8111-111111111111', 1),
('66666666-6666-4666-8666-666666666666', '22222222-2222-4222-8222-222222222222', 2),
('66666666-6666-4666-8666-666666666666', '33333333-3333-4333-8333-333333333333', 3);
```

- [ ] **Step 2: Validate seed content**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
sql = Path('supabase/migrations/002_seed_products.sql').read_text()
for slug in ['bok-choy', 'dragon-fruit', 'golden-carrot', 'purple-basil', 'king-oyster', 'organic-box']:
    if slug not in sql:
        raise SystemExit(f'missing seed slug {slug}')
if sql.count("insert into public.products") != 1:
    raise SystemExit('expected one product insert block')
PY
```

- [ ] **Step 3: Commit seed**

```bash
git add supabase/migrations/002_seed_products.sql
git commit -m "Seed Kenko products"
```

## Task 4: Add Flutter Supabase Configuration And Product Repository

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/config/app_config.dart`
- Create: `lib/data/product_repository.dart`
- Modify: `lib/models/product.dart`
- Create: `test/data/product_repository_test.dart`

- [ ] **Step 1: Add dependency**

Run:

```bash
flutter pub add supabase_flutter
```

Expected: `pubspec.yaml` and `pubspec.lock` update.

- [ ] **Step 2: Add app config**

Create `lib/config/app_config.dart`:

```dart
class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  static const fromEnvironment = AppConfig(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get hasSupabaseConfig {
    return supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;
  }
}
```

- [ ] **Step 3: Add product JSON parsing tests**

Create `test/data/product_repository_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kenko_shop/data/product_repository.dart';

void main() {
  test('maps Supabase product rows to Product models', () {
    final product = productFromSupabaseRow({
      'slug': 'bok-choy',
      'name': 'Da Lat Baby Bok Choy',
      'category': 'Greens',
      'price': 42000,
      'unit': '300g',
      'origin_name': 'Moc Chau Morning Farm',
      'origin_region': 'Da Lat Highlands',
      'origin_story': 'Cut before sunrise.',
      'harvest_label': 'Harvested 06:10',
      'soil_score': 96,
      'caption': 'Crisp stems.',
      'is_limited_drop': true,
      'drop_ends_at': '2026-05-26T12:00:00.000Z',
      'palette_background': '#101510',
      'palette_primary': '#7FBF66',
      'palette_secondary': '#DCEB99',
      'palette_accent': '#F2C35B',
      'product_nutrition_tags': [
        {'label': 'Fiber', 'value': 'High'},
      ],
      'product_bundles': [
        {
          'related_product': {'slug': 'king-oyster'}
        }
      ],
    });

    expect(product.id, 'bok-choy');
    expect(product.price, 42000);
    expect(product.palette.primary, const Color(0xFF7FBF66));
    expect(product.nutritionTags.single.label, 'Fiber');
    expect(product.bundleProductIds, ['king-oyster']);
  });

  test('uses fallback products when remote config is missing', () async {
    final repository = ProductRepository.offline();

    final products = await repository.fetchProducts();

    expect(products, isNotEmpty);
  });
}
```

- [ ] **Step 4: Implement product repository**

Create `lib/data/product_repository.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:kenko_shop/data/sample_products.dart';
import 'package:kenko_shop/models/farm_origin.dart';
import 'package:kenko_shop/models/nutrition_tag.dart';
import 'package:kenko_shop/models/product.dart';
import 'package:kenko_shop/models/product_palette.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductRepository {
  ProductRepository.remote(this._client) : _useOffline = false;

  ProductRepository.offline()
      : _client = null,
        _useOffline = true;

  final SupabaseClient? _client;
  final bool _useOffline;

  Future<List<Product>> fetchProducts() async {
    if (_useOffline) {
      return sampleProducts;
    }

    final rows = await _client!
        .from('products')
        .select('*, product_nutrition_tags(label,value,sort_order), product_bundles(related_product:products!product_bundles_related_product_fk(slug))')
        .eq('is_active', true)
        .order('created_at');

    return rows
        .map<Product>((row) => productFromSupabaseRow(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
  }
}

Product productFromSupabaseRow(Map<String, dynamic> row) {
  final tags = (row['product_nutrition_tags'] as List<dynamic>? ?? [])
      .map((tag) {
        final map = Map<String, dynamic>.from(tag as Map);
        return NutritionTag(
          label: map['label'] as String,
          value: map['value'] as String,
        );
      })
      .toList(growable: false);

  final bundles = (row['product_bundles'] as List<dynamic>? ?? [])
      .map((bundle) => Map<String, dynamic>.from(bundle as Map))
      .map((bundle) => Map<String, dynamic>.from(bundle['related_product'] as Map))
      .map((related) => related['slug'] as String)
      .toList(growable: false);

  return Product(
    id: row['slug'] as String,
    name: row['name'] as String,
    category: row['category'] as String,
    price: (row['price'] as num).toDouble(),
    unit: row['unit'] as String,
    palette: ProductPalette(
      background: _parseHexColor(row['palette_background'] as String),
      primary: _parseHexColor(row['palette_primary'] as String),
      secondary: _parseHexColor(row['palette_secondary'] as String),
      accent: _parseHexColor(row['palette_accent'] as String),
    ),
    origin: FarmOrigin(
      name: row['origin_name'] as String,
      region: row['origin_region'] as String,
      story: row['origin_story'] as String,
    ),
    harvestLabel: row['harvest_label'] as String,
    soilScore: row['soil_score'] as int,
    caption: row['caption'] as String,
    nutritionTags: tags,
    isLimitedDrop: row['is_limited_drop'] as bool? ?? false,
    dropEndsAt: row['drop_ends_at'] == null
        ? null
        : DateTime.parse(row['drop_ends_at'] as String),
    bundleProductIds: bundles,
  );
}

Color _parseHexColor(String value) {
  final normalized = value.replaceFirst('#', '');
  return Color(int.parse('FF$normalized', radix: 16));
}
```

- [ ] **Step 5: Run tests**

```bash
flutter test test/data/product_repository_test.dart
flutter analyze
flutter test
```

Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/config lib/data/product_repository.dart test/data/product_repository_test.dart
git commit -m "Add Supabase product repository"
```

## Task 5: Add Product Feed Store And Remote Loading UI

**Files:**
- Create: `lib/state/product_feed_store.dart`
- Modify: `lib/app/kenko_app.dart`
- Modify: `lib/screens/fresh_feed_screen.dart`
- Create: `test/state/product_feed_store_test.dart`
- Modify: `test/widget_test.dart`
- Modify: `test/screens/fresh_feed_screen_test.dart`

- [ ] **Step 1: Add feed store tests**

Create `test/state/product_feed_store_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kenko_shop/data/sample_products.dart';
import 'package:kenko_shop/models/product.dart';
import 'package:kenko_shop/state/product_feed_store.dart';

class FakeProductLoader {
  FakeProductLoader(this.result);

  final Future<List<Product>> Function() result;

  Future<List<Product>> fetchProducts() => result();
}

void main() {
  test('loads products successfully', () async {
    final loader = FakeProductLoader(() async => sampleProducts);
    final store = ProductFeedStore(loader.fetchProducts);

    await store.load();

    expect(store.isLoading, isFalse);
    expect(store.products, sampleProducts);
    expect(store.errorMessage, isNull);
  });

  test('captures product loading errors', () async {
    final loader = FakeProductLoader(() async => throw Exception('offline'));
    final store = ProductFeedStore(loader.fetchProducts);

    await store.load();

    expect(store.isLoading, isFalse);
    expect(store.products, isEmpty);
    expect(store.errorMessage, contains('offline'));
  });
}
```

- [ ] **Step 2: Implement feed store**

Create `lib/state/product_feed_store.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:kenko_shop/models/product.dart';

typedef ProductLoader = Future<List<Product>> Function();

class ProductFeedStore extends ChangeNotifier {
  ProductFeedStore(this._loader);

  final ProductLoader _loader;

  bool _isLoading = false;
  List<Product> _products = [];
  String? _errorMessage;

  bool get isLoading => _isLoading;
  List<Product> get products => List.unmodifiable(_products);
  String? get errorMessage => _errorMessage;
  bool get isEmpty => !_isLoading && _products.isEmpty && _errorMessage == null;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _loader();
    } catch (error) {
      _products = [];
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

- [ ] **Step 3: Update FreshFeedScreen constructor and states**

Modify `FreshFeedScreen` to take `ProductFeedStore productFeedStore` instead of direct `products`. It should:

- Listen to `productFeedStore` and `cartStore`.
- Start `productFeedStore.load()` in `initState`.
- Render centered loading indicator when loading.
- Render error message and `Retry` button when error.
- Render empty state when no products.
- Render existing `PageView` when products are available.

Keep test-friendly keys:

```dart
const Key('feed-loading')
const Key('feed-error')
const Key('feed-empty')
const Key('feed-retry')
```

- [ ] **Step 4: Wire app root**

Modify `KenkoApp`:

- Read `AppConfig.fromEnvironment`.
- If `hasSupabaseConfig`, initialize Supabase before `runApp` or in app bootstrap.
- Own `ProductRepository` and `ProductFeedStore`.
- Use `ProductRepository.offline()` when config is missing.

If `Supabase.initialize` must be async, move initialization to `main()`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment;
  if (config.hasSupabaseConfig) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabaseAnonKey,
    );
  }
  runApp(KenkoApp(config: config));
}
```

- [ ] **Step 5: Update widget tests**

Update existing tests to construct a `ProductFeedStore(() async => sampleProducts)` and pump until loading completes:

```dart
await tester.pump();
await tester.pump();
```

Also add a test that an error loader displays `feed-error` and retry triggers another load.

- [ ] **Step 6: Verify**

```bash
flutter test test/state/product_feed_store_test.dart
flutter test test/screens/fresh_feed_screen_test.dart
flutter analyze
flutter test
```

- [ ] **Step 7: Commit**

```bash
git add lib/app lib/main.dart lib/screens lib/state test
git commit -m "Load feed products through repository"
```

## Task 6: Add Order Repository And Guest Order Models

**Files:**
- Create: `lib/models/guest_order.dart`
- Create: `lib/models/order_result.dart`
- Create: `lib/data/order_repository.dart`
- Create: `test/data/order_repository_test.dart`

- [ ] **Step 1: Write order repository tests**

Create `test/data/order_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kenko_shop/data/order_repository.dart';
import 'package:kenko_shop/models/guest_order.dart';

void main() {
  test('builds guest order RPC payload without trusting totals', () {
    final request = GuestOrderRequest(
      customerName: 'Linh Nguyen',
      customerPhone: '0900000000',
      deliveryAddress: '12 Farm Lane',
      note: 'Call before delivery',
      items: const [
        GuestOrderItem(productSlug: 'bok-choy', quantity: 2),
      ],
    );

    final payload = buildCreateGuestOrderPayload(request);

    expect(payload['customer_name'], 'Linh Nguyen');
    expect(payload['customer_phone'], '0900000000');
    expect(payload['delivery_address'], '12 Farm Lane');
    expect(payload['note'], 'Call before delivery');
    expect(payload['items'], [
      {'product_slug': 'bok-choy', 'quantity': 2},
    ]);
    expect(payload.containsKey('total'), isFalse);
    expect(payload.containsKey('subtotal'), isFalse);
  });

  test('parses order result', () {
    final result = OrderResult.fromJson({
      'order_id': '11111111-1111-4111-8111-111111111111',
      'order_code': 'KF-ABC123',
      'total': 84000,
      'status': 'new',
    });

    expect(result.orderCode, 'KF-ABC123');
    expect(result.total, 84000);
    expect(result.status, 'new');
  });
}
```

- [ ] **Step 2: Add guest order models**

Create `lib/models/guest_order.dart`:

```dart
class GuestOrderItem {
  const GuestOrderItem({
    required this.productSlug,
    required this.quantity,
  });

  final String productSlug;
  final int quantity;

  Map<String, dynamic> toJson() {
    return {
      'product_slug': productSlug,
      'quantity': quantity,
    };
  }
}

class GuestOrderRequest {
  const GuestOrderRequest({
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.items,
    this.note,
  });

  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final String? note;
  final List<GuestOrderItem> items;
}
```

Create `lib/models/order_result.dart`:

```dart
class OrderResult {
  const OrderResult({
    required this.orderId,
    required this.orderCode,
    required this.total,
    required this.status,
  });

  factory OrderResult.fromJson(Map<String, dynamic> json) {
    return OrderResult(
      orderId: json['order_id'] as String,
      orderCode: json['order_code'] as String,
      total: (json['total'] as num).toInt(),
      status: json['status'] as String,
    );
  }

  final String orderId;
  final String orderCode;
  final int total;
  final String status;
}
```

- [ ] **Step 3: Add order repository**

Create `lib/data/order_repository.dart`:

```dart
import 'package:kenko_shop/models/guest_order.dart';
import 'package:kenko_shop/models/order_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderRepository {
  const OrderRepository(this._client);

  final SupabaseClient _client;

  Future<OrderResult> createGuestOrder(GuestOrderRequest request) async {
    final response = await _client.rpc(
      'create_guest_order',
      params: buildCreateGuestOrderPayload(request),
    );

    return OrderResult.fromJson(Map<String, dynamic>.from(response as Map));
  }
}

Map<String, dynamic> buildCreateGuestOrderPayload(GuestOrderRequest request) {
  return {
    'customer_name': request.customerName.trim(),
    'customer_phone': request.customerPhone.trim(),
    'delivery_address': request.deliveryAddress.trim(),
    'note': request.note?.trim(),
    'items': request.items.map((item) => item.toJson()).toList(growable: false),
  };
}
```

- [ ] **Step 4: Verify**

```bash
flutter test test/data/order_repository_test.dart
flutter analyze
flutter test
```

- [ ] **Step 5: Commit**

```bash
git add lib/models/guest_order.dart lib/models/order_result.dart lib/data/order_repository.dart test/data/order_repository_test.dart
git commit -m "Add guest order repository"
```

## Task 7: Add Guest Checkout UI Flow

**Files:**
- Modify: `lib/widgets/cart_sheet.dart`
- Modify: `lib/screens/fresh_feed_screen.dart`
- Modify: `lib/app/kenko_app.dart`
- Modify: `test/screens/fresh_feed_screen_test.dart`

- [ ] **Step 1: Refactor dependencies**

Pass an optional checkout callback from `FreshFeedScreen` into `CartSheet`:

```dart
typedef GuestCheckoutSubmitter = Future<OrderResult> Function(GuestOrderRequest request);
```

If no remote checkout submitter is available, `CartSheet` should keep existing demo checkout behavior.

- [ ] **Step 2: Add checkout form UI**

In `CartSheet`, when cart has items and user taps checkout:

- Show fields with keys:
  - `guest-name-field`
  - `guest-phone-field`
  - `guest-address-field`
  - `guest-note-field`
- Show submit button key `guest-submit-order`.
- Validate name, phone, and address are non-empty.
- Convert cart items into `GuestOrderItem(productSlug: item.product.id, quantity: item.quantity)`.
- On success, call `cartStore.checkoutDemo()` or add a new `cartStore.markCheckoutComplete()` that clears cart and preserves remote order result state in the sheet.
- Show confirmation text containing `Order <code>`.
- On error, keep cart contents and show retryable error.

- [ ] **Step 3: Add widget tests**

Update `test/screens/fresh_feed_screen_test.dart` with:

```dart
testWidgets('validates guest checkout fields', (tester) async {
  // Render feed with one cart item and a fake submitter.
  // Open cart, tap Checkout Demo/Checkout, tap submit empty form.
  // Expect validation copy for required fields.
});

testWidgets('submits guest checkout and shows order code', (tester) async {
  // Render feed with fake submitter returning OrderResult(orderCode: 'KF-TEST').
  // Add bok choy, open cart, fill fields, submit.
  // Expect Order KF-TEST confirmation.
});
```

Use exact visible validation strings from the implementation, for example:

- `Name is required`
- `Phone is required`
- `Address is required`

- [ ] **Step 4: Wire app repository**

In `KenkoApp`, when Supabase is configured:

- Create `OrderRepository(Supabase.instance.client)`.
- Pass a submitter to `FreshFeedScreen`.

When offline:

- Do not pass remote submitter; retain demo checkout fallback.

- [ ] **Step 5: Verify**

```bash
flutter test test/screens/fresh_feed_screen_test.dart
flutter analyze
flutter test
```

- [ ] **Step 6: Commit**

```bash
git add lib/app lib/screens lib/widgets test/screens
git commit -m "Add guest checkout flow"
```

## Task 8: End-To-End Verification And Documentation

**Files:**
- Modify: `README.md`
- Modify: `supabase/README.md`
- Modify: `.gitignore` if needed

- [ ] **Step 1: Update root README**

Add a section to `README.md`:

````markdown
## Kenko Fresh MVP

Run offline fixture mode:

```bash
flutter run
```

Run with self-hosted Supabase:

```bash
flutter run \
  --dart-define=SUPABASE_URL=http://localhost:8000 \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

Validate Flutter:

```bash
flutter analyze
flutter test
flutter build apk --debug
```

Supabase self-host files live in `supabase/`. Copy `supabase/.env.example` to `supabase/.env`, replace secrets, run `docker compose up -d`, then apply migrations from `supabase/migrations/`.
````

- [ ] **Step 2: Run final verification**

Run:

```bash
docker compose --env-file supabase/.env.example -f supabase/docker-compose.yml config >/tmp/kenko-compose-final.yml
flutter analyze
flutter test
flutter build apk --debug
git status --short
```

Expected:

- Compose config passes if Docker Compose is installed.
- Flutter analyze/test/APK build pass.
- Git status only shows intended docs changes before commit.

- [ ] **Step 3: Commit docs/final verification changes**

```bash
git add README.md supabase/README.md .gitignore
git commit -m "Document backend MVP workflow"
```

If no files changed, do not create an empty commit.

## Self-Review

Spec coverage:

- Supabase self-host files: Task 1.
- Schema, indexes, RLS, RPC: Task 2.
- Six product seeds: Task 3.
- Flutter Supabase config and product loading: Tasks 4 and 5.
- Offline fallback: Task 4 and Task 5.
- Guest checkout RPC payload and UI: Tasks 6 and 7.
- Studio/admin workflow documentation: Tasks 1 and 8.
- Verification: Task 8.

Placeholder scan:

- No `TBD`, `TODO`, or unspecified code blocks are present.

Type consistency:

- `Product.id` remains the product slug in Flutter, matching `GuestOrderItem.productSlug`.
- `create_guest_order` expects `product_slug`, matching `GuestOrderItem.toJson()`.
- `OrderResult` fields match RPC response keys.

Known implementation caveat:

- Official Supabase Docker assets are intentionally vendored from upstream during Task 1 instead of manually rewriting a large compose file. This follows current Supabase self-host guidance and reduces compose drift.
