import 'package:flutter/material.dart';
import 'package:kenko_shop/data/sample_products.dart';
import 'package:kenko_shop/models/farm_origin.dart';
import 'package:kenko_shop/models/nutrition_tag.dart';
import 'package:kenko_shop/models/product.dart';
import 'package:kenko_shop/models/product_palette.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _productSelect =
    '*, product_nutrition_tags(label,value,sort_order), '
    'product_bundles(related_product:products!product_bundles_related_product_fk(slug))';

class ProductRepository {
  ProductRepository.remote(SupabaseClient client)
    : _client = client,
      _isOffline = false;

  ProductRepository.offline() : _client = null, _isOffline = true;

  final SupabaseClient? _client;
  final bool _isOffline;

  Future<List<Product>> fetchProducts() async {
    if (_isOffline) {
      return sampleProducts;
    }

    final rows = await _client!
        .from('products')
        .select(_productSelect)
        .eq('is_active', true)
        .order('created_at');

    return rows
        .map((row) => productFromSupabaseRow(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }
}

Product productFromSupabaseRow(Map<String, dynamic> row) {
  final nutritionRows = _rows(row['product_nutrition_tags'])
    ..sort((left, right) => _sortOrder(left).compareTo(_sortOrder(right)));

  return Product(
    id: row['slug'] as String,
    name: row['name'] as String,
    category: row['category'] as String,
    price: (row['price'] as num).toDouble(),
    unit: row['unit'] as String,
    palette: ProductPalette(
      background: _parseHexColor(row['palette_background'] as String),
      primary: _parseHexColor(row['palette_primary'] as String),
      secondary: _parseHexColor(row['palette_secondary'] as String),
      accent: _parseHexColor(row['palette_accent'] as String),
    ),
    origin: FarmOrigin(
      name: row['origin_name'] as String,
      region: row['origin_region'] as String,
      story: row['origin_story'] as String,
    ),
    harvestLabel: row['harvest_label'] as String,
    soilScore: row['soil_score'] as int,
    caption: row['caption'] as String,
    nutritionTags: [
      for (final tag in nutritionRows)
        NutritionTag(
          label: tag['label'] as String,
          value: tag['value'] as String,
        ),
    ],
    isLimitedDrop: row['is_limited_drop'] as bool? ?? false,
    dropEndsAt: _parseNullableDateTime(row['drop_ends_at']),
    bundleProductIds: [
      for (final bundle in _rows(row['product_bundles']))
        if (bundle['related_product'] case final Map related)
          related['slug'] as String,
    ],
  );
}

List<Map<String, dynamic>> _rows(Object? value) {
  if (value is! List) {
    return [];
  }

  return [
    for (final item in value)
      if (item is Map) Map<String, dynamic>.from(item),
  ];
}

int _sortOrder(Map<String, dynamic> row) {
  final value = row['sort_order'];
  return value is num ? value.toInt() : 0;
}

DateTime? _parseNullableDateTime(Object? value) {
  if (value == null) {
    return null;
  }
  return DateTime.parse(value as String);
}

Color _parseHexColor(String value) {
  final normalized = value.trim().replaceFirst('#', '');
  if (normalized.length == 6) {
    return Color(0xFF000000 | int.parse(normalized, radix: 16));
  }
  if (normalized.length == 8) {
    return Color(int.parse(normalized, radix: 16));
  }
  throw FormatException('Expected #RRGGBB or #AARRGGBB color', value);
}
