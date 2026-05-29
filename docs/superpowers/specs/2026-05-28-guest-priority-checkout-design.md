# Separate Account Gate Checkout Design

## Goal

Keep shopping and cart review fast while adding an account step that helps customers understand why signing in matters for order tracking. Guest checkout remains available, but the guest tradeoff is explicit: guest orders need phone verification and may be processed after signed-in customer orders.

## Selected Approach

Use a separate account gate between cart review and checkout form.

Flow:

1. Customer taps the bottom cart tab and sees the cart sheet.
2. Cart shows products, quantity controls, subtotal, and a primary `Checkout` action only.
3. Tapping `Checkout` opens a dedicated account gate sheet.
4. The account gate offers phone, email, Google, Facebook, and Instagram sign-in entry points.
5. Sign-in buttons are MVP shell actions for this phase and show clear "coming next" feedback.
6. `Continue as guest` remains visible on the account gate.
7. Choosing guest opens the existing guest checkout form.
8. Guest checkout repeats the phone verification and lower priority notice before submission.
9. Successful checkout shows an on-theme receipt with order code, `Create account to track`, and `Continue shopping`.

## UI Boundaries

- Cart sheet owns cart review only: item rows, quantity controls, subtotal, and checkout entry.
- Account gate owns identity choices and guest warning copy.
- Guest checkout form owns delivery fields and submit behavior.
- Order confirmation owns receipt and next actions.

This keeps each surface short enough for small phones and avoids stacking social login, cart rows, delivery fields, and receipt actions into one crowded sheet.

## Current Constraints

Supabase Auth, OAuth provider configuration, and authenticated order ownership are not wired yet. This phase is a UX and flow improvement around the existing guest checkout RPC.

Real tracking needs a later backend phase:

- Add authenticated customer identity to orders, likely `orders.user_id`.
- Configure phone/email/social auth providers.
- Attach signed-in orders to the current user.
- Add a `My orders` view under the profile or account tab.

## Testing

- Opening cart with items shows the cart and checkout action without the account prompt.
- Tapping checkout opens the separate account gate.
- Account gate exposes phone, email, Google, Facebook, Instagram, and guest options.
- Continuing as guest opens the checkout form and shows the guest priority warning.
- Successful checkout shows receipt actions.
- Continue shopping closes checkout and returns to the feed.

## Spec Self-Review

- No placeholder backend behavior is presented as working auth.
- Scope stays limited to mobile UX and existing guest order submission.
- The account gate is separate from the cart so small-screen layout issues are addressed at the design level.
