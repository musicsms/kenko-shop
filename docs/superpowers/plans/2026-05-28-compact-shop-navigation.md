# Compact Shop Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add compact TikTok-style bottom navigation and make checkout form input readable.

**Architecture:** Keep `FreshFeedScreen` as the screen coordinator. Add a focused bottom nav widget under `lib/widgets/`, keep feed rendering in the existing PageView, and use lightweight placeholder views for Browse and You. Keep cart interactions routed through the existing `CartSheet`.

**Tech Stack:** Flutter, Dart, Material 3 widget tests.

---

### Task 1: Tests

**Files:**
- Modify: `test/screens/fresh_feed_screen_test.dart`

- [x] Add a widget test that the compact bottom nav renders Feed, Browse, Cart, and You.
- [x] Add a widget test that tapping Cart in the nav opens `CartSheet`.
- [x] Add a widget test that guest checkout fields use dark readable text style.
- [x] Run `flutter test test/screens/fresh_feed_screen_test.dart` and confirm the new tests fail before implementation.

### Task 2: UI Implementation

**Files:**
- Create: `lib/widgets/compact_bottom_nav.dart`
- Modify: `lib/screens/fresh_feed_screen.dart`
- Modify: `lib/widgets/product_scene.dart`
- Modify: `lib/widgets/cart_sheet.dart`

- [x] Create `CompactBottomNav` with four compact items and a cart badge.
- [x] Replace `FloatingCartPill` overlay with the compact bottom nav.
- [x] Add Browse and You placeholder states in `FreshFeedScreen`.
- [x] Reduce product scene bottom spacing and lift/shrink add-to-cart.
- [x] Add dark text/cursor/label/border input styling in `CartSheet`.
- [x] Run targeted tests.

### Task 3: Verification

**Files:**
- No source files.

- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [ ] Commit and push `kenko-fresh-impl`.
- [ ] Build/tag a new debug release if tests pass.
