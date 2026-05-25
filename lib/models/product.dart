import 'package:kenko_shop/models/farm_origin.dart';
import 'package:kenko_shop/models/nutrition_tag.dart';
import 'package:kenko_shop/models/product_palette.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.unit,
    required this.palette,
    required this.origin,
    required this.harvestLabel,
    required this.soilScore,
    required this.caption,
    required this.nutritionTags,
    required this.bundleProductIds,
    this.isLimitedDrop = false,
    this.dropEndsAt,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final String unit;
  final ProductPalette palette;
  final FarmOrigin origin;
  final String harvestLabel;
  final int soilScore;
  final String caption;
  final List<NutritionTag> nutritionTags;
  final bool isLimitedDrop;
  final DateTime? dropEndsAt;
  final List<String> bundleProductIds;
}
