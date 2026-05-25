import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kenko_shop/data/sample_products.dart';
import 'package:kenko_shop/models/farm_origin.dart';
import 'package:kenko_shop/models/nutrition_tag.dart';
import 'package:kenko_shop/models/product.dart';
import 'package:kenko_shop/models/product_palette.dart';

void main() {
  test('defensively copies product list fields as unmodifiable lists', () {
    final nutritionTags = [const NutritionTag(label: 'Fiber', value: 'High')];
    final bundleProductIds = ['bok-choy'];

    final product = Product(
      id: 'test-product',
      name: 'Test Product',
      category: 'Greens',
      price: 12000,
      unit: '100g',
      palette: const ProductPalette(
        background: Color(0xFF000000),
        primary: Color(0xFFFFFFFF),
        secondary: Color(0xFFCCCCCC),
        accent: Color(0xFF00AA00),
      ),
      origin: const FarmOrigin(
        name: 'Test Farm',
        region: 'Test Region',
        story: 'Test story.',
      ),
      harvestLabel: 'Harvested today',
      soilScore: 90,
      caption: 'Test caption.',
      nutritionTags: nutritionTags,
      bundleProductIds: bundleProductIds,
    );

    nutritionTags.add(const NutritionTag(label: 'Vitamin K', value: 'Rich'));
    bundleProductIds.add('golden-carrot');

    expect(product.nutritionTags, hasLength(1));
    expect(product.bundleProductIds, hasLength(1));
    expect(
      () => product.nutritionTags.add(
        const NutritionTag(label: 'Protein', value: 'Plant'),
      ),
      throwsUnsupportedError,
    );
    expect(
      () => product.bundleProductIds.add('king-oyster'),
      throwsUnsupportedError,
    );
  });

  test('exposes sample products as an unmodifiable list', () {
    expect(
      () => sampleProducts.add(sampleProducts.first),
      throwsUnsupportedError,
    );
  });
}
