# Guest Shop Access Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep the shop browsable and checkout-capable for guests, and prevent release APKs from shipping with invalid Supabase anon credentials.

**Architecture:** The Flutter repository layer remains the boundary between UI and Supabase. Remote product loading falls back to bundled fixtures when Supabase rejects or fails the feed request. GitHub Actions validates the configured anon key against the live product endpoint before building and publishing the release APK.

**Tech Stack:** Flutter, Dart, Supabase Flutter, GitHub Actions, PostgREST.

---

### Task 1: Product Feed Fallback

**Files:**
- Modify: `lib/data/product_repository.dart`
- Modify: `test/data/product_repository_test.dart`

- [x] Add a unit test proving a remote product repository can fall back to offline fixtures when its loader throws.
- [x] Add a small repository constructor for tests that accepts a remote loader.
- [x] Update `fetchProducts()` so remote failures return `sampleProducts`.
- [x] Run `flutter test test/data/product_repository_test.dart`.

### Task 2: CI Backend Credential Smoke Test

**Files:**
- Modify: `.github/workflows/android-debug.yml`

- [x] Add a step after `Check Supabase anon key` that calls `$SUPABASE_URL/rest/v1/products?select=slug&limit=1` with `apikey` and `Authorization: Bearer` headers.
- [x] Keep the build blocked if the endpoint returns unauthorized or any non-2xx status.
- [x] Run `git diff --check`.

### Task 3: Refresh Secret And Release

**Files:**
- No source files.

- [x] Set GitHub secret `SUPABASE_ANON_KEY` from local `supabase/.env`.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [ ] Commit and push `kenko-fresh-impl`.
- [ ] Tag a new debug release and verify GitHub Actions publishes the APK.
