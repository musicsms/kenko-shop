# Separate Account Gate Checkout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Separate cart review from the account/guest decision before checkout.

**Architecture:** `CartSheet` keeps cart review and starts checkout. A dedicated account gate appears only after checkout is tapped, then guest users continue into the existing guest checkout form. Auth provider buttons remain shell actions until Supabase Auth and order ownership are implemented.

**Tech Stack:** Flutter, Dart, widget tests.

---

### Task 1: Update Flow Tests

**Files:**
- Modify: `test/screens/fresh_feed_screen_test.dart`

- [x] Change cart-opening expectations so the cart shows item rows and `Checkout`, but does not show `Sign in for faster checkout`.
- [x] Add or update a test so tapping `Checkout` opens the separate account gate with phone, email, Google, Facebook, Instagram, and `Continue as guest`.
- [x] Keep guest checkout validation coverage: after `Continue as guest`, the checkout form shows the guest priority warning and validates name, phone, and address.
- [x] Keep successful checkout coverage: submit guest order, show order receipt, expose `Create account to track` and `Continue shopping`, then close the sheet.
- [x] Run `flutter test test/screens/fresh_feed_screen_test.dart` and verify the flow test fails before production code changes.

### Task 2: Refactor Cart Sheet State

**Files:**
- Modify: `lib/widgets/cart_sheet.dart`

- [x] Replace the pre-cart `_showGuestPath` prompt flow with an account-gate step shown only after checkout is tapped.
- [x] Add a local enum or equivalent state so sheet content is explicit: cart review, account gate, guest form, confirmation.
- [x] Keep the cart review compact with item rows, subtotal, and checkout button.
- [x] Move `_AccountPrompt` usage behind the checkout button instead of rendering it when the cart first opens.
- [x] Ensure auth buttons use shell snackbar feedback and `Continue as guest` transitions to the guest form.

### Task 3: Layout And Receipt Polish

**Files:**
- Modify: `lib/widgets/cart_sheet.dart`

- [x] Tune sheet initial heights per step so cart is compact, account gate has room, guest form is scrollable, and confirmation fits the theme.
- [x] Keep bottom padding sufficient for scrollable forms so final actions are tappable on small screens.
- [x] Keep the receipt-style confirmation with order code, guest priority notice, `Create account to track`, and `Continue shopping`.

### Task 4: Verification And Release

**Files:**
- Modify: `docs/superpowers/plans/2026-05-28-guest-priority-checkout.md`

- [x] Run `dart format lib/widgets/cart_sheet.dart test/screens/fresh_feed_screen_test.dart`.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Run `git diff --check`.
- [x] Run `flutter build apk --debug`.
- [ ] Commit and push `kenko-fresh-impl`.
- [ ] Tag and verify a new debug release.

### Self-Review

- Spec coverage: cart-only review, separate account gate, guest warning, receipt actions, and auth shell constraints are all represented.
- Placeholder scan: no placeholder implementation instructions remain.
- Type consistency: state is intentionally described as enum or equivalent because exact naming will follow existing `CartSheet` style during implementation.
