import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kenko_shop/models/product.dart';
import 'package:kenko_shop/state/cart_store.dart';
import 'package:kenko_shop/state/product_feed_store.dart';
import 'package:kenko_shop/widgets/cart_sheet.dart';
import 'package:kenko_shop/widgets/floating_cart_pill.dart';
import 'package:kenko_shop/widgets/product_detail_sheet.dart';
import 'package:kenko_shop/widgets/product_scene.dart';

class FreshFeedScreen extends StatefulWidget {
  const FreshFeedScreen({
    required this.productFeedStore,
    required this.cartStore,
    super.key,
  });

  final ProductFeedStore productFeedStore;
  final CartStore cartStore;

  @override
  State<FreshFeedScreen> createState() => _FreshFeedScreenState();
}

class _FreshFeedScreenState extends State<FreshFeedScreen> {
  late final PageController _pageController;
  late DateTime _now;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _now = DateTime.now();
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _now = DateTime.now();
      });
    });
    widget.productFeedStore.addListener(_handleStoreChanged);
    widget.cartStore.addListener(_handleCartChanged);
    unawaited(widget.productFeedStore.load());
  }

  @override
  void didUpdateWidget(covariant FreshFeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productFeedStore != widget.productFeedStore) {
      oldWidget.productFeedStore.removeListener(_handleStoreChanged);
      widget.productFeedStore.addListener(_handleStoreChanged);
      unawaited(widget.productFeedStore.load());
    }
    if (oldWidget.cartStore != widget.cartStore) {
      oldWidget.cartStore.removeListener(_handleCartChanged);
      widget.cartStore.addListener(_handleCartChanged);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    widget.productFeedStore.removeListener(_handleStoreChanged);
    widget.cartStore.removeListener(_handleCartChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _handleStoreChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _handleCartChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final productFeedStore = widget.productFeedStore;
    final products = productFeedStore.products;

    return Scaffold(
      body: Stack(
        children: [
          if (productFeedStore.isLoading)
            const Center(
              key: Key('feed-loading'),
              child: CircularProgressIndicator(),
            )
          else if (productFeedStore.errorMessage != null)
            Center(
              key: const Key('feed-error'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      productFeedStore.errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('feed-retry'),
                    onPressed: () => unawaited(productFeedStore.load()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (productFeedStore.isEmpty)
            const Center(key: Key('feed-empty'), child: Text('KENKO FRESH'))
          else
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductScene(
                  product: product,
                  now: _now,
                  onAdd: () => widget.cartStore.add(product),
                  onOpenDetail: () => _openDetail(product),
                );
              },
            ),
          FloatingCartPill(
            count: widget.cartStore.totalQuantity,
            onTap: _openCart,
          ),
        ],
      ),
    );
  }

  Future<void> _openDetail(Product product) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailSheet(
        product: product,
        onAdd: () => widget.cartStore.add(product),
      ),
    );
  }

  Future<void> _openCart() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CartSheet(cartStore: widget.cartStore),
    );
  }
}
