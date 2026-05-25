import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kenko_shop/data/sample_products.dart';
import 'package:kenko_shop/screens/fresh_feed_screen.dart';
import 'package:kenko_shop/state/cart_store.dart';
import 'package:kenko_shop/widgets/product_scene.dart';

void main() {
  testWidgets('adds a feed product to the floating cart', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FreshFeedScreen(products: sampleProducts, cartStore: CartStore()),
      ),
    );

    expect(find.text('Da Lat Baby Bok Choy'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-to-cart-bok-choy')));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
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
}
