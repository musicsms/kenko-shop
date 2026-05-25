# Kenko Fresh Design Spec

## Goal

Build a mobile prototype for an organic, clean-food shop that feels closer to TikTok commerce than a normal grocery catalog. The prototype runs offline with sample data and focuses on a distinctive product discovery experience.

The app should support both Android and iOS from one codebase.

## Scope

In scope:

- Flutter mobile app using Dart.
- Offline product fixtures.
- Offline visual strategy using bundled assets and procedural Flutter visuals only.
- Full-screen vertical fresh feed as the primary experience.
- Swipe between organic products.
- Add-to-cart from the feed.
- Product detail bottom sheet.
- Cart bottom sheet with quantity changes and demo checkout state.
- Raw farm visual mood with a small flash/drop commerce layer.

Out of scope:

- Real backend or API integration.
- Login/accounts.
- Payment integration.
- Real video hosting.
- Remote product images.
- Admin tools.
- Push notifications.

## Product Direction

Working name: **Kenko Fresh**.

The first screen opens directly into a vertical feed. Each feed page behaves like a short-form product story: a single organic item, visually rich background, origin badge, freshness metadata, and quick buying controls. The goal is to make browsing clean food feel energetic and content-led, not like scrolling a plain catalog.

The selected visual direction is **Raw Farm Energy** with a small amount of **Social Commerce Flash**:

- Raw, tactile, morning-harvest feel.
- Earth, leaf, cream, and harvest-yellow colors.
- Strong organic provenance signals.
- Occasional limited-drop badges and countdowns.
- Fast `+ cart` affordance similar to social commerce.

## Main User Flow

1. User opens the app and lands on the Fresh Feed.
2. User swipes vertically through featured organic products.
3. User taps `+` to add the current product to cart.
4. User taps the product panel to open quick detail.
5. User opens cart from the floating cart pill.
6. User adjusts quantities or taps `Checkout Demo`.
7. App shows an offline order preview/completion state.

## Screens

### Fresh Feed

The Fresh Feed is the main screen and should occupy the full viewport. It uses a vertical `PageView` or equivalent page-snapping feed. Each page is a custom product scene rather than a normal product card.

Each feed item includes:

- Product name.
- Farm/origin name.
- Price and unit.
- Harvest time.
- Organic/freshness badge.
- Soil score badge.
- Short creator-style caption.
- Floating add-to-cart button.
- Optional limited-drop countdown for selected items.

### Product Detail Sheet

The detail sheet opens from a feed item. It should feel like a compact product story, not a full catalog page.

Content:

- Larger product name and price.
- Farm origin.
- Harvest date/time.
- Certifications or clean-food tags.
- Nutrition highlights.
- Taste/use notes.
- Suggested bundle.
- Add-to-cart action.

### Cart Sheet

The cart opens as a bottom sheet or modal overlay from the floating cart pill.

Content:

- Cart items.
- Quantity controls.
- Subtotal.
- Demo checkout button.
- Empty state when no items are selected.
- Confirmation state after checkout demo.

## Architecture

Use Flutter and Dart.

Recommended structure:

```text
lib/
  main.dart
  app/
    kenko_app.dart
    theme.dart
  data/
    sample_products.dart
  models/
    farm_origin.dart
    nutrition_tag.dart
    product.dart
    cart_item.dart
  state/
    cart_store.dart
  screens/
    fresh_feed_screen.dart
  widgets/
    cart_sheet.dart
    product_detail_sheet.dart
    product_scene.dart
    fresh_badge.dart
    floating_cart_pill.dart
```

State should stay simple for the prototype. A lightweight `ChangeNotifier` cart store is enough; no backend state management framework is required unless the implementation naturally needs it.

Navigation should stay local and lightweight:

- Use Flutter's built-in `Navigator`/modal APIs rather than adding a routing package.
- Keep the Fresh Feed screen mounted behind sheets so the current feed index does not reset when sheets dismiss.
- Product detail and cart should be modal bottom sheets.
- Android back should dismiss an open sheet before exiting the feed screen.
- Sheet dismissal can happen through drag-down, backdrop tap, or system back.

Gesture handling should be explicit because the feed and sheets all consume vertical gestures:

- The vertical feed handles swipes only when no sheet is open.
- Bottom sheets should use `showModalBottomSheet` with controlled scroll content.
- If a sheet needs internal scrolling, use a single scrollable child inside the sheet instead of nesting multiple vertical scroll views.
- The feed `PageController` should be owned by the feed screen state so page position persists across modal presentation.

## Data Model

`Product` should include:

- `id`
- `name`
- `category`
- `price`
- `unit`
- `palette`
- `origin`
- `harvestLabel`
- `soilScore`
- `caption`
- `nutritionTags`
- `isLimitedDrop`
- `dropEndsAt`
- `bundleProductIds`

`CartItem` should include:

- `product`
- `quantity`

Fixtures should include a small but varied set: greens, fruit, roots, herbs, mushrooms, and an organic box.

Model details:

- `FarmOrigin` should be a separate value class with farm name, region, and short story fields.
- `NutritionTag` should be a separate value class with label and short value fields.
- `ProductPalette` should be a separate value class that contains the core colors needed by the feed scene.
- `soilScore` is an integer from 0 to 100. It represents a prototype traceability/freshness score and should display as a compact badge, for example `Soil 96`.
- `dropEndsAt` is nullable. If present, the UI derives a live countdown label from `DateTime.now()`. If absent, no countdown is shown.
- `bundleProductIds` is a list of related product IDs used by the product detail sheet for suggested bundles. It may be empty.

Countdown behavior:

- Limited-drop products use `dropEndsAt`.
- The countdown should update at a coarse interval such as once per minute, not every frame.
- Expired drops should display `Drop ended` or hide the urgency treatment; they should not crash or block add-to-cart in the offline prototype.

## Visual System

The UI should avoid looking like a generic green grocery app. Use:

- Dark raw-farm backgrounds for feed contrast.
- Cream text surfaces where needed.
- Leaf and earth greens.
- Harvest yellow for freshness and warmth.
- Red-orange only for limited-drop accents.
- Grain/noise-like texture where feasible with Flutter shapes or lightweight painters.

Buttons should be clear and touch-friendly. The cart action should remain fast, visible, and thumb-accessible.

Asset strategy:

- The prototype must not depend on network images.
- Primary product visuals should be procedural Flutter compositions: gradients, shapes, clipped blobs, badges, and lightweight `CustomPainter` details.
- If static images are needed, they must be bundled under `assets/` and referenced in `pubspec.yaml`.
- `flutter_svg` may be used only if SVG assets are bundled locally and the dependency is justified by actual assets.
- Prefer `CustomPainter` for subtle grain/organic texture so the app remains self-contained. Keep painters simple and avoid per-frame texture regeneration.
- Product scenes may use color palettes and abstract produce silhouettes instead of photorealistic images.

## Error Handling

Because this is an offline prototype, error states are limited:

- Empty cart state.
- Quantity cannot go below zero.
- Missing product data should fall back to readable labels.
- Demo checkout should never fail; it should transition to a confirmation state.

## Testing And Verification

Minimum verification:

- `flutter analyze`
- `flutter test`
- `flutter build apk --debug` or equivalent Android build check when available.

Minimum test coverage:

- Unit test for `CartStore` add, remove, increment, decrement, quantity, subtotal, and clear/checkout behavior.
- Unit test or pure function test for limited-drop countdown label derivation from `dropEndsAt`.
- Widget smoke test that renders the Fresh Feed with fixtures and verifies product name, add-to-cart action, and cart count update.

If a simulator/emulator is available, run the app and inspect:

- Feed page snapping.
- Add-to-cart behavior.
- Product detail sheet.
- Cart sheet quantity updates.
- Text fit on narrow mobile widths.

iOS build output requires macOS and Xcode. The Flutter source should remain iOS-ready, but the Ubuntu environment cannot produce or verify a final iOS build. Android build verification on Ubuntu is the local build gate.

## Acceptance Criteria

- App is a Flutter project in `/home/ubuntu/kenko-shop`.
- It runs from one codebase for Android and iOS targets.
- First screen is the full-screen Fresh Feed.
- Feed contains multiple sample organic products.
- User can add items to cart from the feed.
- User can open product details.
- User can open cart, change quantities, and complete demo checkout.
- Visual style matches Raw Farm Energy with limited-drop accents.
- `flutter analyze` and `flutter test` pass locally.
