import 'package:flutter/material.dart';
import 'package:kenko_shop/app/theme.dart';
import 'package:kenko_shop/config/app_config.dart';
import 'package:kenko_shop/data/auth_repository.dart';
import 'package:kenko_shop/data/order_repository.dart';
import 'package:kenko_shop/data/product_repository.dart';
import 'package:kenko_shop/screens/fresh_feed_screen.dart';
import 'package:kenko_shop/state/auth_store.dart';
import 'package:kenko_shop/state/cart_store.dart';
import 'package:kenko_shop/state/product_feed_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KenkoApp extends StatefulWidget {
  const KenkoApp({required this.config, super.key});

  final AppConfig config;

  @override
  State<KenkoApp> createState() => _KenkoAppState();
}

class _KenkoAppState extends State<KenkoApp> {
  late final CartStore _cartStore;
  late final OrderRepository? _orderRepository;
  late final ProductRepository _productRepository;
  late final ProductFeedStore _productFeedStore;
  late final AuthStore? _authStore;
  late final AuthRepository? _authRepository;

  @override
  void initState() {
    super.initState();
    _cartStore = CartStore();
    _productRepository = widget.config.hasSupabaseConfig
        ? ProductRepository.remote(Supabase.instance.client)
        : ProductRepository.offline();
    _orderRepository = widget.config.hasSupabaseConfig
        ? OrderRepository(Supabase.instance.client)
        : null;
    _productFeedStore = ProductFeedStore(_productRepository.fetchProducts);
    _authStore = widget.config.hasSupabaseConfig
        ? AuthStore(Supabase.instance.client)
        : null;
    _authRepository = widget.config.hasSupabaseConfig
        ? AuthRepository(Supabase.instance.client)
        : null;
  }

  @override
  void dispose() {
    _productFeedStore.dispose();
    _cartStore.dispose();
    _authStore?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kenko Fresh',
      theme: buildKenkoTheme(),
      home: FreshFeedScreen(
        productFeedStore: _productFeedStore,
        cartStore: _cartStore,
        guestCheckoutSubmitter: _orderRepository?.createGuestOrder,
        authStore: _authStore,
        authRepository: _authRepository,
      ),
    );
  }
}
