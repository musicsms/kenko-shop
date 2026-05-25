import 'package:flutter/material.dart';

class ProductPalette {
  const ProductPalette({
    required this.background,
    required this.primary,
    required this.secondary,
    required this.accent,
  });

  final Color background;
  final Color primary;
  final Color secondary;
  final Color accent;
}
