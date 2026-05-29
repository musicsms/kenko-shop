# Compact Shop Navigation Design

## Goal

Make the shop easier to navigate than a pure vertical feed while keeping the existing immersive Kenko visual style. Checkout form fields must remain readable on the light cart sheet.

## Decisions

- Use a compact bottom navigation bar around 58 px tall.
- Keep four tabs: Feed, Browse, Cart, You.
- Feed remains the vertical product swipe experience.
- Browse and You are lightweight placeholder surfaces for this MVP.
- Cart opens the existing cart sheet and shows a quantity badge.
- Remove the old floating cart pill so the bottom nav is the primary navigation.
- Keep each product scene's add-to-cart action as a separate floating action above the nav.
- Checkout input fields on the cream sheet use dark text, dark cursor, visible borders, and dark labels.

## Layout

The bottom nav uses a cream surface with moss active state and compact label text. Feed content gets enough bottom padding so product copy and add-to-cart controls do not collide with the nav. The nav stays visible across Feed, Browse, and You.

## Testing

- Widget tests verify the bottom nav renders.
- Widget tests verify tapping Cart opens the cart sheet.
- Widget tests verify the checkout field text style is dark/readable.
