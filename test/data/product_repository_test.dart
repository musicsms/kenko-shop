import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kenko_shop/config/app_config.dart';
import 'package:kenko_shop/data/product_repository.dart';
import 'package:kenko_shop/data/sample_products.dart';

void main() {
  group('AppConfig', () {
    test('has Supabase config only when URL and anon key are non-empty', () {
      const configured = AppConfig(
        supabaseUrl: ' https://example.supabase.co ',
        supabaseAnonKey: ' anon-key ',
      );
      const missingUrl = AppConfig(
        supabaseUrl: ' ',
        supabaseAnonKey: 'anon-key',
      );
      const missingKey = AppConfig(
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: '\t',
      );

      expect(configured.hasSupabaseConfig, isTrue);
      expect(missingUrl.hasSupabaseConfig, isFalse);
      expect(missingKey.hasSupabaseConfig, isFalse);
    });
  });

  group('productFromSupabaseRow', () {
    test(
      'maps nested nutrition tags and product bundles to product fields',
      () {
        final product = productFromSupabaseRow({
          'slug': 'bok-choy',
          'name': 'Da Lat Baby Bok Choy',
          'category': 'Greens',
          'price': 42000,
          'unit': '300g',
          'origin_name': 'Moc Chau Morning Farm',
          'origin_region': 'Da Lat Highlands',
          'origin_story': 'Cut before sunrise and packed cold.',
          'harvest_label': 'Harvested 06:10',
          'soil_score': 96,
          'caption': 'Crisp stems, sweet leaf.',
          'is_limited_drop': true,
          'drop_ends_at': '2026-05-25T20:00:00.000Z',
          'palette_background': '#101510',
          'palette_primary': '#7FBF66',
          'palette_secondary': '#DCEB99',
          'palette_accent': '#F2C35B',
          'product_nutrition_tags': [
            {'label': 'Vitamin K', 'value': 'Rich', 'sort_order': 2},
            {'label': 'Fiber', 'value': 'High', 'sort_order': 1},
          ],
          'product_bundles': [
            {
              'related_product': {'slug': 'king-oyster'},
            },
            {
              'related_product': {'slug': 'purple-basil'},
            },
          ],
        });

        expect(product.id, 'bok-choy');
        expect(product.name, 'Da Lat Baby Bok Choy');
        expect(product.category, 'Greens');
        expect(product.price, 42000.0);
        expect(product.unit, '300g');
        expect(product.origin.name, 'Moc Chau Morning Farm');
        expect(product.origin.region, 'Da Lat Highlands');
        expect(product.origin.story, 'Cut before sunrise and packed cold.');
        expect(product.harvestLabel, 'Harvested 06:10');
        expect(product.soilScore, 96);
        expect(product.caption, 'Crisp stems, sweet leaf.');
        expect(product.isLimitedDrop, isTrue);
        expect(product.dropEndsAt, DateTime.parse('2026-05-25T20:00:00.000Z'));
        expect(product.nutritionTags.map((tag) => tag.label), [
          'Fiber',
          'Vitamin K',
        ]);
        expect(product.nutritionTags.map((tag) => tag.value), ['High', 'Rich']);
        expect(product.bundleProductIds, ['king-oyster', 'purple-basil']);
      },
    );

    test('parses #RRGGBB color values as opaque Flutter colors', () {
      final product = productFromSupabaseRow({
        'slug': 'dragon-fruit',
        'name': 'Red Dragon Fruit',
        'category': 'Fruit',
        'price': 68000,
        'unit': '2 pcs',
        'origin_name': 'Binh Thuan Sun Field',
        'origin_region': 'Binh Thuan',
        'origin_story': 'Naturally ripened on the plant.',
        'harvest_label': 'Harvested yesterday',
        'soil_score': 91,
        'caption': 'Cold, bright, and built for smoothie bowls.',
        'is_limited_drop': false,
        'drop_ends_at': null,
        'palette_background': '#1B1116',
        'palette_primary': '#FF5C7A',
        'palette_secondary': '#FFD1DC',
        'palette_accent': '#74C365',
        'product_nutrition_tags': const [],
        'product_bundles': const [],
      });

      expect(product.palette.background, const Color(0xFF1B1116));
      expect(product.palette.primary, const Color(0xFFFF5C7A));
      expect(product.palette.secondary, const Color(0xFFFFD1DC));
      expect(product.palette.accent, const Color(0xFF74C365));
    });
  });

  test('offline repository returns sample products', () async {
    final products = await ProductRepository.offline().fetchProducts();

    expect(products, sampleProducts);
  });
}
