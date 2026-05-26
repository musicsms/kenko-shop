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
