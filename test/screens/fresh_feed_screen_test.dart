import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kenko_shop/data/sample_products.dart';
import 'package:kenko_shop/screens/fresh_feed_screen.dart';
import 'package:kenko_shop/state/cart_store.dart';
import 'package:kenko_shop/widgets/product_detail_sheet.dart';
import 'package:kenko_shop/widgets/product_scene.dart';

void main() {
  testWidgets('adds a feed product to the floating cart', (tester) async {
    final product = sampleProducts.first;

    await tester.pumpWidget(
      MaterialApp(
        home: FreshFeedScreen(products: sampleProducts, cartStore: CartStore()),
      ),
    );

    expect(find.text(product.name), findsOneWidget);
    expect(find.text(product.origin.name), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-to-cart-bok-choy')));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('opens product detail and cart sheets from the feed', (
    tester,
  ) async {
    final product = sampleProducts.first;
    final cartStore = CartStore();

    await tester.pumpWidget(
      MaterialApp(
        home: FreshFeedScreen(products: sampleProducts, cartStore: cartStore),
      ),
    );

    await tester.tap(find.text(product.name));
    await tester.pumpAndSettle();

    expect(find.text(product.origin.name), findsWidgets);
    expect(find.text('Suggested bundle'), findsOneWidget);

    await tester.tap(find.byTooltip('Close detail'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-to-cart-bok-choy')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('floating-cart-pill')));
    await tester.pumpAndSettle();

    expect(find.text('Your fresh cart'), findsOneWidget);
    expect(find.text(product.name), findsWidgets);
  });

  testWidgets('opens detail when tapping the product name panel', (
    tester,
  ) async {
    var openedDetail = false;
    final product = sampleProducts.first;

    await tester.pumpWidget(
      MaterialApp(
        home: ProductScene(
          product: product,
          onAdd: () {},
          onOpenDetail: () {
            openedDetail = true;
          },
        ),
      ),
    );

    await tester.tap(find.text(product.name));
    await tester.pump();

    expect(openedDetail, isTrue);
  });

  testWidgets('renders countdown from injected time', (tester) async {
    final product = sampleProducts.first;

    await tester.pumpWidget(
      MaterialApp(
        home: ProductScene(
          product: product,
          now: DateTime(2026, 5, 25, 17),
          onAdd: () {},
          onOpenDetail: () {},
        ),
      ),
    );

    expect(find.text('3h 0m left'), findsOneWidget);
  });

  testWidgets('updates countdown when injected time changes', (tester) async {
    final product = sampleProducts.first;

    await tester.pumpWidget(
      MaterialApp(
        home: ProductScene(
          product: product,
          now: DateTime(2026, 5, 25, 17),
          onAdd: () {},
          onOpenDetail: () {},
        ),
      ),
    );

    expect(find.text('3h 0m left'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: ProductScene(
          product: product,
          now: DateTime(2026, 5, 25, 17, 1),
          onAdd: () {},
          onOpenDetail: () {},
        ),
      ),
    );

    expect(find.text('3h 0m left'), findsNothing);
    expect(find.text('2h 59m left'), findsOneWidget);
  });

  testWidgets('detail sheet shows price and taste use notes', (tester) async {
    final product = sampleProducts.first;

    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailSheet(product: product, onAdd: () {}),
      ),
    );

    expect(
      find.text('${product.price.toStringAsFixed(0)} VND / ${product.unit}'),
      findsOneWidget,
    );
    expect(find.text('Taste & use'), findsOneWidget);
    expect(find.text(product.caption), findsOneWidget);
  });

  testWidgets('cart controls and checkout confirmation fit narrow layouts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final product = sampleProducts.first;
    final cartStore = CartStore();

    await tester.pumpWidget(
      MaterialApp(
        home: FreshFeedScreen(products: sampleProducts, cartStore: cartStore),
      ),
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(Key('add-to-cart-${product.id}')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('floating-cart-pill')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Increase ${product.name}'));
    await tester.pump();
    await tester.tap(find.byTooltip('Decrease ${product.name}'));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Checkout Demo'));
    await tester.pumpAndSettle();

    expect(
      find.text('Demo order packed. No payment was processed.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
