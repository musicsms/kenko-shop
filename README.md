# Kenko Fresh

Flutter storefront MVP for Kenko Fresh.

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

For Android emulators, use a reachable host such as `http://10.0.2.2:8000` instead of `localhost`.

For real Android phones with the backend running on a VPS, use the Tailscale HTTPS flow in [Mobile Device Testing](docs/mobile-device-testing.md).

Validate Flutter:

```bash
flutter analyze
flutter test
flutter build apk --debug
```

Supabase self-host files live in `supabase/`. Copy `supabase/.env.example` to `supabase/.env`, replace placeholder secrets, run `docker compose up -d` from `supabase/`, then apply migrations from `supabase/migrations/`.

## Flutter Resources

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
