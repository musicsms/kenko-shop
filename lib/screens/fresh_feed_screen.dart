import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kenko_shop/models/product.dart';
import 'package:kenko_shop/state/cart_store.dart';
import 'package:kenko_shop/widgets/cart_sheet.dart';
import 'package:kenko_shop/widgets/floating_cart_pill.dart';
import 'package:kenko_shop/widgets/product_detail_sheet.dart';
import 'package:kenko_shop/widgets/product_scene.dart';

class FreshFeedScreen extends StatefulWidget {
  const FreshFeedScreen({
    required this.products,
    required this.cartStore,
    super.key,
  });

  final List<Product> products;
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
    widget.cartStore.addListener(_handleCartChanged);
  }

  @override
  void didUpdateWidget(covariant FreshFeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cartStore != widget.cartStore) {
      oldWidget.cartStore.removeListener(_handleCartChanged);
      widget.cartStore.addListener(_handleCartChanged);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    widget.cartStore.removeListener(_handleCartChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _handleCartChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (widget.products.isEmpty)
            const Center(child: Text('KENKO FRESH'))
          else
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: widget.products.length,
              itemBuilder: (context, index) {
                final product = widget.products[index];
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
