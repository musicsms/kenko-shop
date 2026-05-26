# Kenko Fresh Backend MVP Design Spec

## Goal

Convert the current offline Kenko Fresh Flutter prototype into an MVP backed by a self-hosted Supabase stack running with Docker Compose.

The MVP should keep the TikTok-style Fresh Feed experience while making products and guest checkout real backend data flows.

## Scope

In scope:

- Supabase self-host configuration in the repo.
- Postgres schema and seed SQL for products and orders.
- Guest checkout without login.
- Flutter data layer for products and orders.
- Product feed loaded from Supabase when configured.
- Offline fixture fallback for development when Supabase is not configured or unavailable.
- Supabase Studio as the admin surface for product/order management.

Out of scope:

- User login/auth.
- SMS OTP.
- Online payment.
- Dedicated admin web app.
- Push notifications.
- Realtime order tracking.
- Complex inventory reservation.
- Production deployment automation.

## Selected Approach

Use **Supabase self-host with Docker Compose** and integrate the Flutter app through the Supabase Flutter client.

The app reads active products from Supabase. The cart remains local in Flutter. Checkout calls a Postgres RPC function, `create_guest_order`, instead of writing directly to `orders` or `order_items`.

This keeps the MVP small while avoiding a major security mistake: the client must not submit or control trusted totals.

## Backend Structure

Recommended repo structure:

```text
supabase/
  .env.example
  docker-compose.yml
  migrations/
    001_schema.sql
    002_seed_products.sql
```

The Docker Compose file should follow the official Supabase self-host pattern closely. Secrets and service keys must live in a local `.env` file and must not be committed.

The committed `.env.example` should document required variables without real secrets.

## Database Model

### products

Stores active products shown in the feed.

Important fields:

- `id uuid primary key`
- `slug text unique not null`
- `name text not null`
- `category text not null`
- `price integer not null`
- `unit text not null`
- `is_active boolean not null default true`
- `origin_name text not null`
- `origin_region text not null`
- `origin_story text not null`
- `harvest_label text not null`
- `soil_score integer not null check (soil_score between 0 and 100)`
- `caption text not null`
- `is_limited_drop boolean not null default false`
- `drop_ends_at timestamptz`
- palette fields for procedural UI:
  - `palette_background text not null`
  - `palette_primary text not null`
  - `palette_secondary text not null`
  - `palette_accent text not null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Use integer prices in VND to avoid floating-point currency issues.

### product_nutrition_tags

Stores nutrition/value tags displayed on product detail sheets.

Fields:

- `id uuid primary key`
- `product_id uuid not null references products(id) on delete cascade`
- `label text not null`
- `value text not null`
- `sort_order integer not null default 0`

### product_bundles

Stores suggested bundle relationships.

Fields:

- `product_id uuid not null references products(id) on delete cascade`
- `related_product_id uuid not null references products(id) on delete cascade`
- `sort_order integer not null default 0`
- primary key: `(product_id, related_product_id)`

### orders

Stores guest checkout orders.

Fields:

- `id uuid primary key`
- `order_code text unique not null`
- `customer_name text not null`
- `customer_phone text not null`
- `delivery_address text not null`
- `note text`
- `status text not null default 'new'`
- `subtotal integer not null`
- `total integer not null`
- `created_at timestamptz not null default now()`

Initial status values:

- `new`
- `confirmed`
- `packed`
- `delivered`
- `cancelled`

### order_items

Stores product snapshots at checkout time.

Fields:

- `id uuid primary key`
- `order_id uuid not null references orders(id) on delete cascade`
- `product_id uuid references products(id) on delete set null`
- `product_name text not null`
- `unit text not null`
- `unit_price integer not null`
- `quantity integer not null check (quantity > 0)`
- `line_total integer not null`

Snapshot fields are required so old orders remain readable even if product data changes later.

## Indexes And Constraints

Add indexes for the access paths the app and Studio will use:

- `products(is_active, created_at desc)` for active product feed reads.
- `product_nutrition_tags(product_id, sort_order)` for product detail hydration.
- `product_bundles(product_id, sort_order)` for suggested bundles.
- `product_bundles(related_product_id)` for foreign-key maintenance.
- `orders(created_at desc)` for Studio order review.
- `orders(status, created_at desc)` for manual order workflow filtering.
- `order_items(order_id)` for order detail lookup and cascade performance.
- `order_items(product_id)` for foreign-key maintenance.

Foreign key columns must be indexed explicitly. Postgres does not create those indexes automatically.

## RPC Checkout

Create a Postgres function:

```sql
create_guest_order(
  customer_name text,
  customer_phone text,
  delivery_address text,
  note text,
  items jsonb
)
```

The RPC should:

- Validate customer name, phone, and delivery address are non-empty after trimming.
- Validate `items` is a non-empty JSON array.
- Validate each item has a product identifier and positive integer quantity.
- Load active products from the database.
- Reject inactive or missing products.
- Calculate line totals and order total from database prices.
- Insert one row in `orders`.
- Insert item snapshots in `order_items`.
- Return an object containing:
  - `order_id`
  - `order_code`
  - `total`
  - `status`

The client must not send a trusted subtotal or total.

Implementation details:

- The function should run as `security definer` so anonymous clients can create orders without direct table write grants.
- The function must set a fixed `search_path`, for example `set search_path = public`.
- Grant `execute` on `create_guest_order` to the `anon` role only after the function is defined.
- Do not grant anonymous `insert` on `orders` or `order_items`.
- Keep the function body short and transactional; a single Postgres function call is already atomic unless the function catches and suppresses errors.

## Security And RLS

Enable Row-Level Security for public tables.

Client access rules:

- Anonymous clients can select active products.
- Anonymous clients can select nutrition tags and bundle links only for active products.
- Anonymous clients cannot select, insert, update, or delete `orders` or `order_items` directly.
- Anonymous clients can execute `create_guest_order`.

Privilege rules:

- Revoke broad public table access before adding specific policies.
- Use least-privilege grants for `anon`.
- Prefer explicit table policies over relying on application-side filtering.

Admin access:

- Supabase Studio/service role can manage products and review orders.

PII handling:

- Guest order fields contain personal data.
- Orders and order items must not have public select policies.
- `.env` and service role secrets must not be committed.

## Flutter App Changes

The existing Flutter app remains the main customer app.

Add configuration via compile-time defines:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Data behavior:

- If both values are present, initialize Supabase and use remote repositories.
- If either value is missing, use offline fixture fallback.
- If product fetch fails, show an error state with a retry action and allow fallback only in development mode.

Recommended Flutter additions:

```text
lib/config/app_config.dart
lib/data/product_repository.dart
lib/data/order_repository.dart
lib/models/guest_order.dart
lib/models/order_result.dart
lib/state/product_feed_store.dart
```

### Product Loading

`ProductRepository.fetchProducts()` should load active products with enough related data to hydrate existing `Product` models:

- base product rows
- nutrition tags
- bundle product IDs/slugs

The existing procedural visual system should continue using palette fields from the backend.

### Checkout Flow

The cart remains local.

The cart sheet checkout button should open a guest checkout form collecting:

- customer name
- phone
- delivery address
- optional note

On submit:

- Validate fields locally for basic empty values.
- Call `OrderRepository.createGuestOrder(...)`.
- Show loading while submitting.
- On success, clear the cart and show order code/status confirmation.
- On error, keep cart contents and show a retryable error.

## Admin Workflow

Use SQL seed and Supabase Studio for MVP operations.

Admin can:

- Review seeded products.
- Edit product active state, price, copy, drop time, palette, and tags.
- Review orders and update status manually.

No custom admin web dashboard is included in this phase.

## Dev Workflow

Expected local flow:

1. Copy `supabase/.env.example` to `supabase/.env`.
2. Fill local secrets and public anon key values.
3. Start Supabase self-host:

```bash
cd supabase
docker compose up -d
```

4. Apply migrations/seeds.
5. Run the Flutter app with:

```bash
flutter run \
  --dart-define=SUPABASE_URL=http://localhost:8000 \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

For Android emulator, `localhost` may need to become `10.0.2.2` or a host LAN IP depending on network setup.

## Testing And Verification

Backend verification:

- `docker compose config`
- SQL migration syntax check or apply against local Postgres.
- Seed data creates the six existing products.
- RPC success path creates order and order items.
- RPC rejects empty customer fields.
- RPC rejects invalid product IDs and invalid quantities.

Flutter verification:

- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
- Product repository JSON mapping test.
- Order repository/RPC payload test.
- Checkout form widget test for validation and success state.
- Existing cart/feed tests continue to pass.

iOS build remains source-ready but cannot be verified in this Ubuntu environment.

## Acceptance Criteria

- Supabase self-host files exist under `supabase/`.
- Schema and seed migrations are committed.
- Six products are available from the database.
- Flutter app can run with offline fallback when Supabase config is missing.
- Flutter app can load products from Supabase when config is present.
- Guest checkout creates an order through RPC.
- Client never writes orders or order items directly.
- Orders are visible in Supabase Studio.
- `flutter analyze`, `flutter test`, and `flutter build apk --debug` pass locally.
