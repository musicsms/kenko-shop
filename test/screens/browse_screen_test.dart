import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kenko_shop/data/sample_products.dart';
import 'package:kenko_shop/screens/browse_screen.dart';
import 'package:kenko_shop/state/cart_store.dart';

Future<void> pumpBrowseScreen(WidgetTester tester, CartStore cartStore) async {
  await tester.pumpWidget(
    MaterialApp(home: BrowseScreen(cartStore: cartStore)),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows all products when no filter is active', (tester) async {
    final cartStore = CartStore();
    addTearDown(cartStore.dispose);
    await pumpBrowseScreen(tester, cartStore);

    for (final product in sampleProducts) {
      expect(find.text(product.name), findsOneWidget);
    }
  });

  testWidgets('category chip hides products from other categories', (
    tester,
  ) async {
    final cartStore = CartStore();
    addTearDown(cartStore.dispose);
    await pumpBrowseScreen(tester, cartStore);

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
    await pumpBrowseScreen(tester, cartStore);

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
    await pumpBrowseScreen(tester, cartStore);

    await tester.enterText(find.byKey(const Key('browse-search-field')), 'carrot');
    await tester.pump();

    expect(find.text('Golden Soil Carrot'), findsOneWidget);
    expect(find.text('Da Lat Baby Bok Choy'), findsNothing);
  });

  testWidgets('add button increments cart store', (tester) async {
    final cartStore = CartStore();
    addTearDown(cartStore.dispose);
    await pumpBrowseScreen(tester, cartStore);

    expect(cartStore.totalQuantity, 0);
    await tester.tap(find.byKey(Key('browse-add-${sampleProducts.first.id}')));
    await tester.pump();

    expect(cartStore.totalQuantity, 1);
  });
}
