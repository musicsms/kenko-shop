# Guest Shop Access Design

## Goal

Kenko Fresh is a guest-first shop. Visitors can open the app, browse products, add items to cart, and place a guest checkout order without creating an account or signing in.

## Decisions

- Product browsing must work with Supabase `anon` access.
- Checkout must work as a guest RPC using customer name, phone, address, note, and cart items.
- User login is optional future scope and must not block the first screen.
- If remote product loading fails, the app should keep the shop usable with bundled offline products and expose a clear backend error for debugging.
- CI builds must fail early if the configured Supabase anon key cannot read the product feed.

## Data Flow

The Flutter build receives `SUPABASE_URL` and `SUPABASE_ANON_KEY` through dart defines. At startup, the app initializes Supabase only when both values are present. The product repository reads active products through PostgREST as the anon role. The order repository calls `create_guest_order` as the anon role.

## Error Handling

An invalid, stale, or mismatched anon key must not be interpreted as a user login requirement. CI should catch invalid backend credentials before publishing a release APK. Runtime product feed failures should fall back to offline fixtures so the storefront remains viewable during backend or credential issues.

## Testing

- Unit tests cover remote product fallback behavior.
- Existing widget tests continue to cover feed and checkout flows.
- GitHub Actions validates the configured anon key by calling the product endpoint before building the APK.
