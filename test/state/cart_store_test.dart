import 'package:flutter_test/flutter_test.dart';
import 'package:kenko_shop/data/sample_products.dart';
import 'package:kenko_shop/state/cart_store.dart';

void main() {
  test('adds product and increments quantity', () {
    final store = CartStore();
    final product = sampleProducts.first;

    store.add(product);
    store.add(product);

    expect(store.items.length, 1);
    expect(store.quantityFor(product.id), 2);
    expect(store.totalQuantity, 2);
  });

  test('decrements and removes item at zero', () {
    final store = CartStore();
    final product = sampleProducts.first;

    store.add(product);
    store.add(product);
    store.decrement(product.id);
    store.decrement(product.id);

    expect(store.items, isEmpty);
    expect(store.quantityFor(product.id), 0);
  });

  test('calculates subtotal', () {
    final store = CartStore();
    final first = sampleProducts[0];
    final second = sampleProducts[1];

    store.add(first);
    store.add(second);
    store.add(second);

    expect(store.subtotal, first.price + second.price * 2);
  });

  test('checkout clears items and records completion state', () {
    final store = CartStore();
    final product = sampleProducts.first;

    store.add(product);
    store.checkoutDemo();

    expect(store.items, isEmpty);
    expect(store.checkoutComplete, isTrue);
  });

  test('reset checkout state when adding a new item', () {
    final store = CartStore();
    final product = sampleProducts.first;

    store.add(product);
    store.checkoutDemo();
    store.add(product);

    expect(store.checkoutComplete, isFalse);
    expect(store.totalQuantity, 1);
  });
}
