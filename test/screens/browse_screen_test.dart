import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kenko_shop/data/sample_products.dart';
import 'package:kenko_shop/screens/browse_screen.dart';
import 'package:kenko_shop/state/cart_store.dart';
import 'package:kenko_shop/state/product_feed_store.dart';

Future<void> pumpBrowseScreen(
  WidgetTester tester,
  CartStore cartStore,
  ProductFeedStore productFeedStore,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BrowseScreen(
        cartStore: cartStore,
        productFeedStore: productFeedStore,
      ),
    ),
  );
  await tester.pump();
}

ProductFeedStore _loadedStore() {
  final store = ProductFeedStore(() async => List.from(sampleProducts));
  return store;
}

void main() {
  testWidgets('shows all products when no filter is active', (tester) async {
    final cartStore = CartStore();
    addTearDown(cartStore.dispose);
    final productFeedStore = _loadedStore();
    await productFeedStore.load();
    addTearDown(productFeedStore.dispose);
    await pumpBrowseScreen(tester, cartStore, productFeedStore);

    for (final product in sampleProducts) {
      expect(find.text(product.name), findsOneWidget);
    }
  });

  testWidgets('category chip hides products from other categories', (
    tester,
  ) async {
    final cartStore = CartStore();
    addTearDown(cartStore.dispose);
    final productFeedStore = _loadedStore();
    await productFeedStore.load();
    addTearDown(productFeedStore.dispose);
    await pumpBrowseScreen(tester, cartStore, productFeedStore);

    await tester.tap(find.byKey(const Key('browse-chip-Greens')));
    await tester.pump();

    expect(find.text('Da Lat Baby Bok Choy'), findsOneWidget);
    expect(find.text('Red Dragon Fruit'), findsNothing);
    expect(find.text('Golden Soil Carrot'), findsNothing);
  });

  testWidgets('All chip restores full product list after filtering', (
    tester,
  ) async {
    final cartStore = CartStore();
    addTearDown(cartStore.dispose);
    final productFeedStore = _loadedStore();
    await productFeedStore.load();
    addTearDown(productFeedStore.dispose);
    await pumpBrowseScreen(tester, cartStore, productFeedStore);

    await tester.tap(find.byKey(const Key('browse-chip-Greens')));
    await tester.pump();
    expect(find.text('Red Dragon Fruit'), findsNothing);

    await tester.tap(find.byKey(const Key('browse-chip-All')));
    await tester.pump();
    expect(find.text('Red Dragon Fruit'), findsOneWidget);
  });

  testWidgets('search filters products by name', (tester) async {
    final cartStore = CartStore();
    addTearDown(cartStore.dispose);
    final productFeedStore = _loadedStore();
    await productFeedStore.load();
    addTearDown(productFeedStore.dispose);
    await pumpBrowseScreen(tester, cartStore, productFeedStore);

    await tester.enterText(find.byKey(const Key('browse-search-field')), 'carrot');
    await tester.pump();

    expect(find.text('Golden Soil Carrot'), findsOneWidget);
    expect(find.text('Da Lat Baby Bok Choy'), findsNothing);
  });

  testWidgets('add button increments cart store', (tester) async {
    final cartStore = CartStore();
    addTearDown(cartStore.dispose);
    final productFeedStore = _loadedStore();
    await productFeedStore.load();
    addTearDown(productFeedStore.dispose);
    await pumpBrowseScreen(tester, cartStore, productFeedStore);

    expect(cartStore.totalQuantity, 0);
    await tester.tap(find.byKey(Key('browse-add-${sampleProducts.first.id}')));
    await tester.pump();

    expect(cartStore.totalQuantity, 1);
  });
}
