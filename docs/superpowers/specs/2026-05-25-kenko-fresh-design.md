# Kenko Fresh Design Spec

## Goal

Build a mobile prototype for an organic, clean-food shop that feels closer to TikTok commerce than a normal grocery catalog. The prototype runs offline with sample data and focuses on a distinctive product discovery experience.

The app should support both Android and iOS from one codebase.

## Scope

In scope:

- Flutter mobile app using Dart.
- Offline product fixtures.
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
- Soil score or traceability score.
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

## Data Model

`Product` should include:

- `id`
- `name`
- `category`
- `price`
- `unit`
- `heroColor` or visual palette fields
- `origin`
- `harvestLabel`
- `soilScore`
- `caption`
- `nutritionTags`
- `isLimitedDrop`
- `dropEndsLabel`

`CartItem` should include:

- `product`
- `quantity`

Fixtures should include a small but varied set: greens, fruit, roots, herbs, mushrooms, and an organic box.

## Visual System

The UI should avoid looking like a generic green grocery app. Use:

- Dark raw-farm backgrounds for feed contrast.
- Cream text surfaces where needed.
- Leaf and earth greens.
- Harvest yellow for freshness and warmth.
- Red-orange only for limited-drop accents.
- Grain/noise-like texture where feasible with Flutter shapes or lightweight painters.

Buttons should be clear and touch-friendly. The cart action should remain fast, visible, and thumb-accessible.

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

If a simulator/emulator is available, run the app and inspect:

- Feed page snapping.
- Add-to-cart behavior.
- Product detail sheet.
- Cart sheet quantity updates.
- Text fit on narrow mobile widths.

iOS build output requires macOS and Xcode. The Flutter source should remain iOS-ready, but the Ubuntu environment cannot produce a final iOS build.

## Acceptance Criteria

- App is a Flutter project in `/home/ubuntu/kenko-shop`.
- It runs from one codebase for Android and iOS targets.
- First screen is the full-screen Fresh Feed.
- Feed contains multiple sample organic products.
- User can add items to cart from the feed.
- User can open product details.
- User can open cart, change quantities, and complete demo checkout.
- Visual style matches Raw Farm Energy with limited-drop accents.
