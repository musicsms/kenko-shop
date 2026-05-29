import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kenko_shop/app/theme.dart';
import 'package:kenko_shop/data/auth_repository.dart';
import 'package:kenko_shop/models/product.dart';
import 'package:kenko_shop/screens/browse_screen.dart';
import 'package:kenko_shop/screens/you_screen.dart';
import 'package:kenko_shop/state/auth_store.dart';
import 'package:kenko_shop/state/cart_store.dart';
import 'package:kenko_shop/state/product_feed_store.dart';
import 'package:kenko_shop/widgets/auth_sheet.dart';
import 'package:kenko_shop/widgets/cart_sheet.dart';
import 'package:kenko_shop/widgets/compact_bottom_nav.dart';
import 'package:kenko_shop/widgets/product_detail_sheet.dart';
import 'package:kenko_shop/widgets/product_scene.dart';

class FreshFeedScreen extends StatefulWidget {
  const FreshFeedScreen({
    required this.productFeedStore,
    required this.cartStore,
    this.guestCheckoutSubmitter,
    this.authStore,
    this.authRepository,
    super.key,
  });

  final ProductFeedStore productFeedStore;
  final CartStore cartStore;
  final GuestCheckoutSubmitter? guestCheckoutSubmitter;
  final AuthStoreBase? authStore;
  final AuthRepository? authRepository;

  @override
  State<FreshFeedScreen> createState() => _FreshFeedScreenState();
}

class _FreshFeedScreenState extends State<FreshFeedScreen> {
  late final PageController _pageController;
  late DateTime _now;
  Timer? _countdownTimer;
  int _selectedTab = 0;

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
          Positioned.fill(
            child: _buildSelectedBody(productFeedStore, products),
          ),
          CompactBottomNav(
            selectedIndex: _selectedTab,
            cartCount: widget.cartStore.totalQuantity,
            onSelect: _handleNavSelection,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedBody(
    ProductFeedStore productFeedStore,
    List<Product> products,
  ) {
    return switch (_selectedTab) {
      0 => _buildFeed(productFeedStore, products),
      1 => BrowseScreen(cartStore: widget.cartStore),
      3 => _buildYouTab(),
      _ => _buildFeed(productFeedStore, products),
    };
  }

  Widget _buildYouTab() {
    final authStore = widget.authStore;
    final authRepository = widget.authRepository;
    if (authStore == null || authRepository == null) {
      return const _PlaceholderTab(
        key: Key('you-placeholder'),
        icon: Icons.person_rounded,
        title: 'Your Kenko',
        message: 'Saved addresses and optional sign-in can come later.',
      );
    }
    return YouScreen(
      authStore: authStore,
      onSignIn: () => _openAuthSheet(authRepository),
      onSignOut: () => unawaited(authRepository.signOut()),
    );
  }

  void _openAuthSheet(AuthRepository authRepository) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AuthSheet(authRepository: authRepository),
    );
  }

  Widget _buildFeed(ProductFeedStore productFeedStore, List<Product> products) {
    if (productFeedStore.isLoading) {
      return const Center(
        key: Key('feed-loading'),
        child: CircularProgressIndicator(),
      );
    }
    if (productFeedStore.errorMessage != null) {
      return Center(
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
      );
    }
    if (productFeedStore.isEmpty) {
      return const Center(key: Key('feed-empty'), child: Text('KENKO FRESH'));
    }

    return PageView.builder(
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
    );
  }

  void _handleNavSelection(int index) {
    if (index == 2) {
      unawaited(_openCart());
      return;
    }
    setState(() {
      _selectedTab = index;
    });
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
      builder: (context) => CartSheet(
        cartStore: widget.cartStore,
        guestCheckoutSubmitter: widget.guestCheckoutSubmitter,
        authRepository: widget.authRepository,
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KenkoColors.rawBlack,
            Color(0xFF173421),
            KenkoColors.rawBlack,
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 110),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: KenkoColors.harvest, size: 38),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: KenkoColors.cream,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: KenkoColors.cream.withValues(alpha: 0.72),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
