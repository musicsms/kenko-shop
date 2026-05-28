import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kenko_shop/data/sample_products.dart';
import 'package:kenko_shop/models/guest_order.dart';
import 'package:kenko_shop/models/order_result.dart';
import 'package:kenko_shop/models/product.dart';
import 'package:kenko_shop/screens/fresh_feed_screen.dart';
import 'package:kenko_shop/state/cart_store.dart';
import 'package:kenko_shop/state/product_feed_store.dart';
import 'package:kenko_shop/widgets/cart_sheet.dart';
import 'package:kenko_shop/widgets/product_detail_sheet.dart';
import 'package:kenko_shop/widgets/product_scene.dart';

ProductFeedStore productFeedStore([Future<List<Product>> Function()? loader]) {
  final store = ProductFeedStore(loader ?? () async => sampleProducts);
  addTearDown(store.dispose);
  return store;
}

Future<void> pumpFreshFeed(
  WidgetTester tester, {
  required CartStore cartStore,
  ProductFeedStore? store,
  GuestCheckoutSubmitter? guestCheckoutSubmitter,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: FreshFeedScreen(
        productFeedStore: store ?? productFeedStore(),
        cartStore: cartStore,
        guestCheckoutSubmitter: guestCheckoutSubmitter,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('shows loading while feed products load', (tester) async {
    final completer = Completer<List<Product>>();
    final store = productFeedStore(() => completer.future);

    await tester.pumpWidget(
      MaterialApp(
        home: FreshFeedScreen(productFeedStore: store, cartStore: CartStore()),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('feed-loading')), findsOneWidget);

    completer.complete(sampleProducts);
    await tester.pump();

    expect(find.byKey(const Key('feed-loading')), findsNothing);
    expect(find.text(sampleProducts.first.name), findsOneWidget);
  });

  testWidgets('shows empty feed state when no products load', (tester) async {
    await pumpFreshFeed(
      tester,
      cartStore: CartStore(),
      store: productFeedStore(() async => []),
    );

    expect(find.byKey(const Key('feed-empty')), findsOneWidget);
    expect(find.text('KENKO FRESH'), findsOneWidget);
  });

  testWidgets('adds a feed product and updates the cart tab badge', (
    tester,
  ) async {
    final product = sampleProducts.first;

    await pumpFreshFeed(tester, cartStore: CartStore());

    expect(find.text(product.name), findsOneWidget);
    expect(find.text(product.origin.name), findsOneWidget);
    expect(find.byKey(const Key('compact-bottom-nav')), findsOneWidget);
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Browse'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.byKey(const Key('compact-cart-badge')), findsNothing);

    await tester.tap(find.byKey(const Key('add-to-cart-bok-choy')));
    await tester.pump();

    expect(find.byKey(const Key('compact-cart-badge')), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('opens product detail and cart sheets from the feed', (
    tester,
  ) async {
    final product = sampleProducts.first;
    final cartStore = CartStore();

    await pumpFreshFeed(tester, cartStore: cartStore);

    await tester.tap(find.text(product.name));
    await tester.pumpAndSettle();

    expect(find.text(product.origin.name), findsWidgets);
    expect(find.text('Suggested bundle'), findsOneWidget);

    await tester.tap(find.byTooltip('Close detail'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-to-cart-bok-choy')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('compact-nav-cart')));
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

    await pumpFreshFeed(tester, cartStore: cartStore);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(Key('add-to-cart-${product.id}')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('compact-nav-cart')));
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

  testWidgets('guest checkout validates required fields', (tester) async {
    final cartStore = CartStore();

    await pumpFreshFeed(
      tester,
      cartStore: cartStore,
      guestCheckoutSubmitter: (_) async => const OrderResult(
        orderId: 'order-test',
        orderCode: 'KF-TEST',
        total: 0,
        status: 'new',
      ),
    );

    await tester.tap(find.byKey(const Key('add-to-cart-bok-choy')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('compact-nav-cart')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('guest-submit-order')));
    await tester.pump();

    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Phone is required'), findsOneWidget);
    expect(find.text('Address is required'), findsOneWidget);
  });

  testWidgets('guest checkout fields use dark text on the light sheet', (
    tester,
  ) async {
    final cartStore = CartStore();

    await pumpFreshFeed(
      tester,
      cartStore: cartStore,
      guestCheckoutSubmitter: (_) async => const OrderResult(
        orderId: 'order-test',
        orderCode: 'KF-TEST',
        total: 0,
        status: 'new',
      ),
    );

    await tester.tap(find.byKey(const Key('add-to-cart-bok-choy')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('compact-nav-cart')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();

    final nameField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('guest-name-field')),
        matching: find.byType(TextField),
      ),
    );

    expect(nameField.style?.color, const Color(0xFF101510));
    expect(nameField.cursorColor, const Color(0xFF2E6B45));
  });

  testWidgets('successful remote guest checkout confirms order', (
    tester,
  ) async {
    final product = sampleProducts.first;
    final cartStore = CartStore();
    GuestOrderRequest? submittedRequest;

    await pumpFreshFeed(
      tester,
      cartStore: cartStore,
      guestCheckoutSubmitter: (request) async {
        submittedRequest = request;
        return OrderResult(
          orderId: 'order-test',
          orderCode: 'KF-TEST',
          total: product.price.toInt(),
          status: 'new',
        );
      },
    );

    await tester.tap(find.byKey(Key('add-to-cart-${product.id}')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('compact-nav-cart')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('guest-name-field')),
      'Mina Tan',
    );
    await tester.enterText(
      find.byKey(const Key('guest-phone-field')),
      '0901234567',
    );
    await tester.enterText(
      find.byKey(const Key('guest-address-field')),
      '12 Market Lane',
    );
    await tester.enterText(
      find.byKey(const Key('guest-note-field')),
      'Leave at door',
    );
    await tester.tap(find.byKey(const Key('guest-submit-order')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.textContaining('Order KF-TEST'), findsOneWidget);
    expect(submittedRequest, isNotNull);
    expect(submittedRequest!.items.single.productSlug, product.id);
    expect(submittedRequest!.items.single.quantity, 1);
    expect(cartStore.isEmpty, isTrue);
  });

  testWidgets('shows feed load errors and retries loading products', (
    tester,
  ) async {
    var attempts = 0;
    final store = productFeedStore(() async {
      attempts += 1;
      if (attempts == 1) {
        throw Exception('offline');
      }
      return sampleProducts;
    });

    await pumpFreshFeed(tester, cartStore: CartStore(), store: store);

    expect(find.byKey(const Key('feed-error')), findsOneWidget);
    expect(find.textContaining('offline'), findsOneWidget);

    await tester.tap(find.byKey(const Key('feed-retry')));
    await tester.pump();
    await tester.pump();

    expect(attempts, 2);
    expect(find.byKey(const Key('feed-error')), findsNothing);
    expect(find.text(sampleProducts.first.name), findsOneWidget);
  });
}
