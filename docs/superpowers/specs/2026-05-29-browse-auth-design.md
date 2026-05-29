# Browse Tab + Auth Design

## Goal

Implement two empty placeholder tabs in the Kenko Fresh Flutter app:

1. **Browse tab** — TikTok Shop-style product discovery with search and category filters.
2. **Auth** — Optional email/password sign-in via Supabase Auth, wired into the existing checkout flow (account gate + post-order confirmation) and a real You tab profile screen.

## Scope

In scope:

- `BrowseScreen`: search bar, horizontal category filter chips, 2-column product grid, tap-to-detail.
- `AuthStore`: ChangeNotifier wrapping Supabase auth state stream.
- `AuthRepository`: email/password sign-in, sign-up, sign-out via Supabase.
- `AuthSheet`: bottom sheet with toggle sign-in / sign-up form.
- `YouScreen`: signed-in profile view vs. signed-out prompt.
- Wire `_AccountPrompt` "Continue with email" into `AuthSheet`.
- Wire `_OrderConfirmation` "Create account to track" into `AuthSheet`.
- Pass `AuthStore` down from `KenkoApp` to screens that need it.

Out of scope:

- Phone OTP auth (Twilio setup required — keep UI stub).
- Google / Facebook / Instagram OAuth (keep UI stubs).
- Order history screen (requires additional backend queries).
- Forgot password flow.
- Avatar image upload.

## Browse Screen

### Layout

Full-screen dark background (`KenkoColors.rawBlack`) consistent with the feed visual identity.

```
SafeArea
  Column
    ├── SearchBar (outlined, cream on dark)
    ├── SizedBox(8)
    ├── FilterChipRow (horizontal scroll, category chips)
    └── Expanded
          └── GridView.builder (2 columns, ProductBrowseCard)
```

### FilterChipRow

Categories derived dynamically from `sampleProducts` with an "All" chip prepended. Selecting a chip filters the visible grid. Only one chip active at a time.

### ProductBrowseCard

Compact card using `product.palette` gradient as background. Contents:

- Gradient background rectangle with rounded corners.
- Product name (bold, cream).
- Price + unit (small, muted cream).
- `+` add-to-cart icon button (harvest yellow, bottom-right).
- Limited-drop flash badge if `product.isLimitedDrop`.

Tap anywhere on card (except `+`) → opens existing `ProductDetailSheet`.

### Search Logic

Client-side filter on `sampleProducts`. Matches `product.name` and `product.category` case-insensitively. Search and category filter compose: both apply simultaneously.

### File

`lib/screens/browse_screen.dart`

## Auth Architecture

### AuthRepository

Thin wrapper over `Supabase.instance.client.auth`.

```dart
class AuthRepository {
  Future<void> signInWithEmail(String email, String password);
  Future<void> signUpWithEmail(String email, String password);
  Future<void> signOut();
}
```

Errors propagate as `AuthException` from the Supabase SDK. Callers handle display.

File: `lib/data/auth_repository.dart`

### AuthStore

`ChangeNotifier` that listens to `supabaseClient.auth.onAuthStateChange`.

```dart
class AuthStore extends ChangeNotifier {
  User? get currentUser;
  bool get isSignedIn;
}
```

Subscription cancelled in `dispose()`.

File: `lib/state/auth_store.dart`

### AuthSheet

Modal bottom sheet with two modes toggled by a tab/button: **Sign in** and **Create account**.

Fields: email, password. Single `FilledButton` for the active action. Error text below button on failure. Loading state disables fields and shows spinner.

After success: sheet pops. Callers may show a follow-up snackbar if needed (e.g., post-order confirmation).

File: `lib/widgets/auth_sheet.dart`

### YouScreen

Two states based on `AuthStore.isSignedIn`:

**Signed out:**
- Icon + headline "Track your orders"
- Short benefit copy
- "Sign in" FilledButton → opens `AuthSheet`

**Signed in:**
- Avatar circle with initials from email
- Email display
- "Sign out" OutlinedButton → calls `AuthRepository.signOut()`

File: `lib/screens/you_screen.dart`

## Wiring into Checkout Flow

### _AccountPrompt — "Continue with email"

Currently calls `_showAccountComingSoon()`. Replace with a call to open `AuthSheet`. On auth success, `CartSheet` detects signed-in state and can proceed directly to `guestForm` (or future signed-in checkout path).

Phone, Google, Facebook, Instagram buttons stay wired to a clearer "Coming soon" snackbar.

### _OrderConfirmation — "Create account to track"

Currently calls `_showAccountComingSoon()`. Replace with `AuthSheet` in sign-up mode. On success show snackbar: "Account created — your order is linked."

## KenkoApp Wiring

`AuthStore` and `AuthRepository` instantiated in `_KenkoAppState.initState()`, disposed in `dispose()`. Passed via constructor to `FreshFeedScreen`, which threads them to `CartSheet` (via existing `guestCheckoutSubmitter` pattern) and to `YouScreen`.

`_buildSelectedBody` in `FreshFeedScreen`:
- `case 1` → `BrowseScreen`
- `case 3` → `YouScreen`

## Architecture — New Files

```
lib/
  data/
    auth_repository.dart       ← new
  state/
    auth_store.dart            ← new
  screens/
    browse_screen.dart         ← new
    you_screen.dart            ← new
  widgets/
    auth_sheet.dart            ← new
```

Modified files:

- `lib/app/kenko_app.dart` — instantiate AuthStore + AuthRepository, pass to FreshFeedScreen
- `lib/screens/fresh_feed_screen.dart` — accept auth deps, wire tab 1 and 3, pass to CartSheet
- `lib/widgets/cart_sheet.dart` — wire auth buttons, accept authStore + authRepository

## Error Handling

- Auth errors: show `AuthException.message` inline in `AuthSheet`. Never crash.
- Browse: no network, no errors. Pure local filter.
- Sign-out failure: silent (Supabase sign-out is local-first).

## Testing

- Unit test `AuthStore`: responds to sign-in / sign-out auth state events.
- Widget smoke test `BrowseScreen`: renders product grid, filter chip changes visible items, search filters by name.
- Widget smoke test `YouScreen`: shows signed-out state by default, shows email when signed in.

## Acceptance Criteria

- Tab Browse shows searchable, filterable product grid. Tap opens ProductDetailSheet. Add-to-cart works.
- Tab You shows sign-in prompt when signed out; shows email + sign-out when signed in.
- "Continue with email" in checkout opens AuthSheet with working Supabase sign-in/sign-up.
- "Create account to track" after order opens AuthSheet in sign-up mode.
- `flutter analyze` and `flutter test` pass.
