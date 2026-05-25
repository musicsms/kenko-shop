import 'package:flutter/material.dart';
import 'package:kenko_shop/app/theme.dart';
import 'package:kenko_shop/data/sample_products.dart';
import 'package:kenko_shop/screens/fresh_feed_screen.dart';
import 'package:kenko_shop/state/cart_store.dart';

class KenkoApp extends StatefulWidget {
  const KenkoApp({super.key});

  @override
  State<KenkoApp> createState() => _KenkoAppState();
}

class _KenkoAppState extends State<KenkoApp> {
  final CartStore _cartStore = CartStore();

  @override
  void dispose() {
    _cartStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kenko Fresh',
      theme: buildKenkoTheme(),
      home: FreshFeedScreen(products: sampleProducts, cartStore: _cartStore),
    );
  }
}
