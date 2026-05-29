import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kenko_shop/data/sample_products.dart';
import 'package:kenko_shop/models/product.dart';
import 'package:kenko_shop/state/product_feed_store.dart';

class FakeProductLoader {
  FakeProductLoader(this.result);

  final Future<List<Product>> Function() result;

  Future<List<Product>> fetchProducts() => result();
}

void main() {
  test('loads products successfully', () async {
    final loader = FakeProductLoader(() async => sampleProducts);
    final store = ProductFeedStore(loader.fetchProducts);

    await store.load();

    expect(store.isLoading, isFalse);
    expect(store.products, sampleProducts);
    expect(store.errorMessage, isNull);
    expect(store.isEmpty, isFalse);
  });

  test('captures product loading errors', () async {
    final loader = FakeProductLoader(() async => throw Exception('offline'));
    final store = ProductFeedStore(loader.fetchProducts);

    await store.load();

    expect(store.isLoading, isFalse);
    expect(store.products, isEmpty);
    expect(store.errorMessage, contains('offline'));
  });

  test('does not notify after disposal when load completes', () async {
    final completer = Completer<List<Product>>();
    final store = ProductFeedStore(() => completer.future);
    final previousOnError = FlutterError.onError;
    Object? flutterError;
    FlutterError.onError = (details) {
      flutterError = details.exception;
    };
    addTearDown(() {
      FlutterError.onError = previousOnError;
    });

    final load = store.load();
    store.dispose();
    completer.complete(sampleProducts);

    await expectLater(load, completes);

    expect(flutterError, isNull);
  });
}
