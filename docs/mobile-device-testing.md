# Mobile Device Testing

This guide explains how to test the Kenko Fresh Flutter app on a real Android phone while the Supabase backend runs on a VPS.

## Current Topology

```text
Android phone
  -> Tailscale VPN
  -> https://<vps-name>.<tailnet>.ts.net
  -> Tailscale Serve on VPS
  -> http://localhost:8000
  -> Supabase Kong
  -> Supabase PostgREST / RPC / Postgres
```

Use Tailscale Serve for private MVP testing. Nginx is not required unless you want a public custom domain, public internet access, or more complex routing.

## Requirements

On the VPS:

- Supabase Docker stack is running.
- Tailscale is installed and logged into the same tailnet as the phone.
- Tailscale MagicDNS and HTTPS certificates are enabled for the tailnet.

On the phone:

- Tailscale app is installed.
- The phone is logged into the same tailnet.
- Tailscale VPN is connected before opening the Kenko Fresh app.

## Start Supabase

From the repo worktree:

```bash
cd supabase
docker compose --env-file .env up -d
docker compose --env-file .env ps
```

Expected local Supabase endpoints on the VPS:

- API gateway: `http://localhost:8000`
- Postgres pooler: `localhost:5432`
- Transaction pooler: `localhost:6543`

For phone testing, the app should only call the HTTPS Tailscale URL. Do not expose Postgres ports publicly.

## Enable Tailscale HTTPS Proxy

On the VPS:

```bash
tailscale serve --bg --https=443 localhost:8000
tailscale serve status
```

The status output should show a URL like:

```text
https://<vps-name>.<tailnet>.ts.net
```

Use that exact URL as `SUPABASE_URL` when building or running the Flutter app.

If Tailscale asks to enable HTTPS certificates, approve it in the Tailscale admin flow, then run the command again.

## Verify Backend From The VPS

Run:

```bash
cd supabase
ANON_KEY=$(grep '^ANON_KEY=' .env | cut -d= -f2-)
curl -sS -f \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $ANON_KEY" \
  "http://localhost:8000/rest/v1/products?select=slug,name,price&order=created_at.desc"
```

Expected result: a JSON array with the seeded Kenko products.

Then verify the Tailscale HTTPS route:

```bash
TAILSCALE_URL="https://<vps-name>.<tailnet>.ts.net"
ANON_KEY=$(grep '^ANON_KEY=' .env | cut -d= -f2-)
curl -sS -f \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $ANON_KEY" \
  "$TAILSCALE_URL/rest/v1/products?select=slug,name,price&order=created_at.desc"
```

Expected result: the same product JSON array.

## Build APK For A Real Phone

From the repo root:

```bash
SUPABASE_URL="https://<vps-name>.<tailnet>.ts.net"
SUPABASE_ANON_KEY=$(grep '^ANON_KEY=' supabase/.env | cut -d= -f2-)

flutter build apk --debug \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
```

APK output:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

Install that APK on the phone, keep Tailscale connected, then open the app.

## Expected App Behavior

When backend connection works:

- Product feed loads the six seeded products from Supabase.
- Product detail sheets show nutrition tags and suggested bundles.
- Guest checkout creates a new order through `create_guest_order`.
- Totals are calculated by the database, not trusted from the client.

When backend connection fails:

- The app falls back to bundled offline product fixtures for the feed.
- Checkout cannot create a real backend order.

## Common Issues

### App works on emulator but not phone

`10.0.2.2` only works for Android emulators. Real phones need the Tailscale HTTPS URL:

```text
https://<vps-name>.<tailnet>.ts.net
```

### HTTPS URL does not open on the phone

Check:

```bash
tailscale status
tailscale serve status
```

Confirm the phone appears in the same tailnet and Tailscale VPN is connected.

### Products return from localhost but not from Tailscale URL

Re-run:

```bash
tailscale serve --bg --https=443 localhost:8000
```

Then test the HTTPS URL with `curl`.

### Checkout fails

Run the database smoke test:

```bash
cd supabase
docker compose --env-file .env exec -T db psql -U postgres -d postgres -v ON_ERROR_STOP=1 < tests/create_guest_order.sql
```

Expected result: JSON containing `order_id`, `order_code`, `total`, and `status`.

## Stop Services

Stop Tailscale Serve:

```bash
tailscale serve reset
```

Stop Supabase:

```bash
cd supabase
docker compose --env-file .env down
```
