import 'package:flutter/material.dart';
import 'package:kenko_shop/models/farm_origin.dart';
import 'package:kenko_shop/models/nutrition_tag.dart';
import 'package:kenko_shop/models/product.dart';
import 'package:kenko_shop/models/product_palette.dart';

final sampleProducts = <Product>[
  Product(
    id: 'bok-choy',
    name: 'Da Lat Baby Bok Choy',
    category: 'Greens',
    price: 42000,
    unit: '300g',
    palette: const ProductPalette(
      background: Color(0xFF101510),
      primary: Color(0xFF7FBF66),
      secondary: Color(0xFFDCEB99),
      accent: Color(0xFFF2C35B),
    ),
    origin: const FarmOrigin(
      name: 'Moc Chau Morning Farm',
      region: 'Da Lat Highlands',
      story: 'Cut before sunrise and packed in reusable cold crates.',
    ),
    harvestLabel: 'Harvested 06:10',
    soilScore: 96,
    caption: 'Crisp stems, sweet leaf, perfect for garlic stir-fry.',
    nutritionTags: const [
      NutritionTag(label: 'Fiber', value: 'High'),
      NutritionTag(label: 'Vitamin K', value: 'Rich'),
    ],
    isLimitedDrop: true,
    dropEndsAt: DateTime(2026, 5, 25, 20),
    bundleProductIds: ['king-oyster', 'purple-basil'],
  ),
  const Product(
    id: 'dragon-fruit',
    name: 'Red Dragon Fruit',
    category: 'Fruit',
    price: 68000,
    unit: '2 pcs',
    palette: ProductPalette(
      background: Color(0xFF1B1116),
      primary: Color(0xFFFF5C7A),
      secondary: Color(0xFFFFD1DC),
      accent: Color(0xFF74C365),
    ),
    origin: FarmOrigin(
      name: 'Binh Thuan Sun Field',
      region: 'Binh Thuan',
      story: 'Naturally ripened on the plant with no wax coating.',
    ),
    harvestLabel: 'Harvested yesterday',
    soilScore: 91,
    caption: 'Cold, bright, and built for smoothie bowls.',
    nutritionTags: [
      NutritionTag(label: 'Antioxidants', value: 'Bright'),
      NutritionTag(label: 'Sugar', value: 'Natural'),
    ],
    bundleProductIds: ['organic-box'],
  ),
  Product(
    id: 'golden-carrot',
    name: 'Golden Soil Carrot',
    category: 'Roots',
    price: 55000,
    unit: '500g',
    palette: const ProductPalette(
      background: Color(0xFF17120E),
      primary: Color(0xFFE69035),
      secondary: Color(0xFFFFD88A),
      accent: Color(0xFF6FA65F),
    ),
    origin: const FarmOrigin(
      name: 'Red Earth Co-op',
      region: 'Don Duong',
      story: 'Grown in mineral-rich red soil and washed by hand.',
    ),
    harvestLabel: 'Pulled 09:25',
    soilScore: 94,
    caption: 'Snack sweet, soup ready, kid approved.',
    nutritionTags: const [
      NutritionTag(label: 'Beta carotene', value: 'High'),
      NutritionTag(label: 'Crunch', value: 'Firm'),
    ],
    isLimitedDrop: true,
    dropEndsAt: DateTime(2026, 5, 25, 18, 30),
    bundleProductIds: ['purple-basil', 'organic-box'],
  ),
  const Product(
    id: 'purple-basil',
    name: 'Purple Basil Bunch',
    category: 'Herbs',
    price: 28000,
    unit: '80g',
    palette: ProductPalette(
      background: Color(0xFF151019),
      primary: Color(0xFF8E5AC7),
      secondary: Color(0xFFCDA8FF),
      accent: Color(0xFF7FBF66),
    ),
    origin: FarmOrigin(
      name: 'An Nhien Herb Garden',
      region: 'Gia Lam',
      story: 'Small-batch herb beds watered before dawn.',
    ),
    harvestLabel: 'Cut 05:50',
    soilScore: 89,
    caption: 'Aromatic lift for salads, noodles, and grilled veg.',
    nutritionTags: [
      NutritionTag(label: 'Aroma', value: 'Strong'),
      NutritionTag(label: 'Polyphenols', value: 'Good'),
    ],
    bundleProductIds: ['bok-choy', 'king-oyster'],
  ),
  const Product(
    id: 'king-oyster',
    name: 'King Oyster Mushroom',
    category: 'Mushrooms',
    price: 72000,
    unit: '250g',
    palette: ProductPalette(
      background: Color(0xFF121417),
      primary: Color(0xFFD9C7A3),
      secondary: Color(0xFFF3E7CE),
      accent: Color(0xFF9AC46A),
    ),
    origin: FarmOrigin(
      name: 'North Cloud Grow House',
      region: 'Sa Pa',
      story: 'Slow-grown in a cool controlled room for dense texture.',
    ),
    harvestLabel: 'Picked 07:40',
    soilScore: 92,
    caption: 'Meaty slices for pan sear, broth, or vegan steak.',
    nutritionTags: [
      NutritionTag(label: 'Protein', value: 'Plant'),
      NutritionTag(label: 'Umami', value: 'Deep'),
    ],
    bundleProductIds: ['bok-choy', 'golden-carrot'],
  ),
  Product(
    id: 'organic-box',
    name: 'Surprise Organic Box',
    category: 'Box',
    price: 189000,
    unit: '6 items',
    palette: const ProductPalette(
      background: Color(0xFF16120B),
      primary: Color(0xFFFF6048),
      secondary: Color(0xFFF2C35B),
      accent: Color(0xFF6FA65F),
    ),
    origin: const FarmOrigin(
      name: 'Kenko Curated Farms',
      region: 'Rotating farms',
      story: 'A daily box built from the best harvest window.',
    ),
    harvestLabel: 'Packed today',
    soilScore: 95,
    caption: 'Limited fresh drop for cooks who like surprises.',
    nutritionTags: const [
      NutritionTag(label: 'Variety', value: '6 picks'),
      NutritionTag(label: 'Waste', value: 'Low'),
    ],
    isLimitedDrop: true,
    dropEndsAt: DateTime(2026, 5, 25, 21),
    bundleProductIds: ['bok-choy', 'dragon-fruit', 'golden-carrot'],
  ),
];

Product? findProductById(String id) {
  for (final product in sampleProducts) {
    if (product.id == id) {
      return product;
    }
  }
  return null;
}
