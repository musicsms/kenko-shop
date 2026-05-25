# Kenko Fresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Kenko Fresh Flutter prototype: a TikTok-style offline organic food feed with add-to-cart, detail sheets, cart sheet, procedural visuals, and tests.

**Architecture:** Use a small Flutter app with local fixtures, value models, and a `ChangeNotifier` cart store. The Fresh Feed owns page state and presents product/cart modal sheets so the feed stays mounted behind overlays.

**Tech Stack:** Flutter 3.41.9, Dart 3.11.5, Material 3, built-in `ChangeNotifier`, built-in `Navigator`/modal sheet APIs, Flutter widget/unit tests.

---

## File Structure

- `pubspec.yaml`: Flutter package metadata and SDK configuration.
- `analysis_options.yaml`: lint configuration using Flutter recommended lints.
- `lib/main.dart`: app entrypoint.
- `lib/app/kenko_app.dart`: root `MaterialApp`, theme wiring, and cart store ownership.
- `lib/app/theme.dart`: shared colors, text styles, and Material theme.
- `lib/data/sample_products.dart`: offline product fixtures and lookup helpers.
- `lib/models/farm_origin.dart`: farm origin value class.
- `lib/models/nutrition_tag.dart`: nutrition value class.
- `lib/models/product_palette.dart`: color palette value class for product scenes.
- `lib/models/product.dart`: product value class.
- `lib/models/cart_item.dart`: cart item value class.
- `lib/state/cart_store.dart`: cart operations and demo checkout state.
- `lib/utils/drop_countdown.dart`: pure countdown label function for `dropEndsAt`.
- `lib/screens/fresh_feed_screen.dart`: primary vertical feed and modal orchestration.
- `lib/widgets/product_scene.dart`: full-screen product scene.
- `lib/widgets/fresh_badge.dart`: compact badge/pill widget.
- `lib/widgets/floating_cart_pill.dart`: bottom cart affordance.
- `lib/widgets/product_detail_sheet.dart`: product detail modal content.
- `lib/widgets/cart_sheet.dart`: cart modal content.
- `test/state/cart_store_test.dart`: cart unit tests.
- `test/utils/drop_countdown_test.dart`: countdown unit tests.
- `test/screens/fresh_feed_screen_test.dart`: feed widget smoke test.

## Task 1: Scaffold Flutter Project

**Files:**
- Create: Flutter platform files via `flutter create`
- Modify: `pubspec.yaml`
- Modify: `analysis_options.yaml`
- Create: `lib/main.dart`
- Create: `lib/app/kenko_app.dart`
- Create: `lib/app/theme.dart`
- Create: `test/widget_test.dart`

- [ ] **Step 1: Create the Flutter project in the existing repo**

Run:

```bash
flutter create --project-name kenko_shop --platforms=android,ios .
```

Expected: Flutter creates `android/`, `ios/`, `lib/`, `test/`, and `pubspec.yaml` without deleting `docs/`.

- [ ] **Step 2: Replace `pubspec.yaml` content**

Use this complete package file:

```yaml
name: kenko_shop
description: "Kenko Fresh offline mobile commerce prototype."
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ^3.11.5

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
```

- [ ] **Step 3: Replace `analysis_options.yaml`**

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
```

- [ ] **Step 4: Create the root app shell**

`lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:kenko_shop/app/kenko_app.dart';

void main() {
  runApp(const KenkoApp());
}
```

`lib/app/theme.dart`:

```dart
import 'package:flutter/material.dart';

class KenkoColors {
  static const rawBlack = Color(0xFF101510);
  static const leaf = Color(0xFF5E9B56);
  static const moss = Color(0xFF2E6B45);
  static const cream = Color(0xFFF6F2E7);
  static const harvest = Color(0xFFF2C35B);
  static const flash = Color(0xFFFF6048);
  static const soil = Color(0xFF6E4B32);
}

ThemeData buildKenkoTheme() {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: KenkoColors.leaf,
      brightness: Brightness.dark,
      surface: KenkoColors.rawBlack,
    ),
    useMaterial3: true,
  );

  return base.copyWith(
    scaffoldBackgroundColor: KenkoColors.rawBlack,
    textTheme: base.textTheme.apply(
      bodyColor: KenkoColors.cream,
      displayColor: KenkoColors.cream,
    ),
  );
}
```

`lib/app/kenko_app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:kenko_shop/app/theme.dart';

class KenkoApp extends StatelessWidget {
  const KenkoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kenko Fresh',
      theme: buildKenkoTheme(),
      home: const Scaffold(
        body: Center(child: Text('Kenko Fresh')),
      ),
    );
  }
}
```

- [ ] **Step 5: Replace generated smoke test**

`test/widget_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kenko_shop/main.dart' as app;

void main() {
  testWidgets('Kenko app renders shell', (tester) async {
    app.main();
    await tester.pump();

    expect(find.text('Kenko Fresh'), findsOneWidget);
  });
}
```

- [ ] **Step 6: Verify scaffold**

Run:

```bash
flutter analyze
flutter test
```

Expected: both pass.

- [ ] **Step 7: Commit scaffold**

```bash
git add .
git commit -m "Create Flutter app shell"
```

## Task 2: Add Models, Fixtures, And Countdown Logic

**Files:**
- Create: `lib/models/farm_origin.dart`
- Create: `lib/models/nutrition_tag.dart`
- Create: `lib/models/product_palette.dart`
- Create: `lib/models/product.dart`
- Create: `lib/models/cart_item.dart`
- Create: `lib/data/sample_products.dart`
- Create: `lib/utils/drop_countdown.dart`
- Create: `test/utils/drop_countdown_test.dart`

- [ ] **Step 1: Write countdown tests first**

`test/utils/drop_countdown_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kenko_shop/utils/drop_countdown.dart';

void main() {
  test('returns empty label when drop end is null', () {
    expect(formatDropCountdown(null, DateTime(2026, 5, 25, 8)), '');
  });

  test('formats minutes remaining', () {
    final now = DateTime(2026, 5, 25, 8);
    final endsAt = DateTime(2026, 5, 25, 8, 45);

    expect(formatDropCountdown(endsAt, now), '45m left');
  });

  test('formats hours and minutes remaining', () {
    final now = DateTime(2026, 5, 25, 8);
    final endsAt = DateTime(2026, 5, 25, 10, 30);

    expect(formatDropCountdown(endsAt, now), '2h 30m left');
  });

  test('formats expired drop', () {
    final now = DateTime(2026, 5, 25, 8);
    final endsAt = DateTime(2026, 5, 25, 7, 59);

    expect(formatDropCountdown(endsAt, now), 'Drop ended');
  });
}
```

- [ ] **Step 2: Run countdown test to verify failure**

Run:

```bash
flutter test test/utils/drop_countdown_test.dart
```

Expected: FAIL because `drop_countdown.dart` does not exist.

- [ ] **Step 3: Add model files and countdown implementation**

`lib/models/farm_origin.dart`:

```dart
class FarmOrigin {
  const FarmOrigin({
    required this.name,
    required this.region,
    required this.story,
  });

  final String name;
  final String region;
  final String story;
}
```

`lib/models/nutrition_tag.dart`:

```dart
class NutritionTag {
  const NutritionTag({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}
```

`lib/models/product_palette.dart`:

```dart
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
```

`lib/models/product.dart`:

```dart
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
```

`lib/models/cart_item.dart`:

```dart
import 'package:kenko_shop/models/product.dart';

class CartItem {
  const CartItem({
    required this.product,
    required this.quantity,
  });

  final Product product;
  final int quantity;

  double get lineTotal => product.price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }
}
```

`lib/utils/drop_countdown.dart`:

```dart
String formatDropCountdown(DateTime? endsAt, DateTime now) {
  if (endsAt == null) {
    return '';
  }

  final remaining = endsAt.difference(now);
  if (remaining.inMinutes <= 0) {
    return 'Drop ended';
  }

  final hours = remaining.inHours;
  final minutes = remaining.inMinutes.remainder(60);
  if (hours > 0) {
    return '${hours}h ${minutes}m left';
  }

  return '${remaining.inMinutes}m left';
}
```

- [ ] **Step 4: Add sample fixtures**

`lib/data/sample_products.dart`:

```dart
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
  Product(
    id: 'dragon-fruit',
    name: 'Red Dragon Fruit',
    category: 'Fruit',
    price: 68000,
    unit: '2 pcs',
    palette: const ProductPalette(
      background: Color(0xFF1B1116),
      primary: Color(0xFFFF5C7A),
      secondary: Color(0xFFFFD1DC),
      accent: Color(0xFF74C365),
    ),
    origin: const FarmOrigin(
      name: 'Binh Thuan Sun Field',
      region: 'Binh Thuan',
      story: 'Naturally ripened on the plant with no wax coating.',
    ),
    harvestLabel: 'Harvested yesterday',
    soilScore: 91,
    caption: 'Cold, bright, and built for smoothie bowls.',
    nutritionTags: const [
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
  Product(
    id: 'purple-basil',
    name: 'Purple Basil Bunch',
    category: 'Herbs',
    price: 28000,
    unit: '80g',
    palette: const ProductPalette(
      background: Color(0xFF151019),
      primary: Color(0xFF8E5AC7),
      secondary: Color(0xFFCDA8FF),
      accent: Color(0xFF7FBF66),
    ),
    origin: const FarmOrigin(
      name: 'An Nhien Herb Garden',
      region: 'Gia Lam',
      story: 'Small-batch herb beds watered before dawn.',
    ),
    harvestLabel: 'Cut 05:50',
    soilScore: 89,
    caption: 'Aromatic lift for salads, noodles, and grilled veg.',
    nutritionTags: const [
      NutritionTag(label: 'Aroma', value: 'Strong'),
      NutritionTag(label: 'Polyphenols', value: 'Good'),
    ],
    bundleProductIds: ['bok-choy', 'king-oyster'],
  ),
  Product(
    id: 'king-oyster',
    name: 'King Oyster Mushroom',
    category: 'Mushrooms',
    price: 72000,
    unit: '250g',
    palette: const ProductPalette(
      background: Color(0xFF121417),
      primary: Color(0xFFD9C7A3),
      secondary: Color(0xFFF3E7CE),
      accent: Color(0xFF9AC46A),
    ),
    origin: const FarmOrigin(
      name: 'North Cloud Grow House',
      region: 'Sa Pa',
      story: 'Slow-grown in a cool controlled room for dense texture.',
    ),
    harvestLabel: 'Picked 07:40',
    soilScore: 92,
    caption: 'Meaty slices for pan sear, broth, or vegan steak.',
    nutritionTags: const [
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
```

- [ ] **Step 5: Run tests**

Run:

```bash
flutter test test/utils/drop_countdown_test.dart
flutter analyze
```

Expected: both pass.

- [ ] **Step 6: Commit domain layer**

```bash
git add lib/models lib/data lib/utils test/utils
git commit -m "Add product fixtures and countdown logic"
```

## Task 3: Add Cart Store With Unit Tests

**Files:**
- Create: `lib/state/cart_store.dart`
- Create: `test/state/cart_store_test.dart`

- [ ] **Step 1: Write failing cart tests**

`test/state/cart_store_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kenko_shop/data/sample_products.dart';
import 'package:kenko_shop/state/cart_store.dart';

void main() {
  test('adds product and increments quantity', () {
    final store = CartStore();
    final product = sampleProducts.first;

    store.add(product);
    store.add(product);

    expect(store.items.length, 1);
    expect(store.quantityFor(product.id), 2);
    expect(store.totalQuantity, 2);
  });

  test('decrements and removes item at zero', () {
    final store = CartStore();
    final product = sampleProducts.first;

    store.add(product);
    store.add(product);
    store.decrement(product.id);
    store.decrement(product.id);

    expect(store.items, isEmpty);
    expect(store.quantityFor(product.id), 0);
  });

  test('calculates subtotal', () {
    final store = CartStore();
    final first = sampleProducts[0];
    final second = sampleProducts[1];

    store.add(first);
    store.add(second);
    store.add(second);

    expect(store.subtotal, first.price + second.price * 2);
  });

  test('checkout clears items and records completion state', () {
    final store = CartStore();
    final product = sampleProducts.first;

    store.add(product);
    store.checkoutDemo();

    expect(store.items, isEmpty);
    expect(store.checkoutComplete, isTrue);
  });

  test('reset checkout state when adding a new item', () {
    final store = CartStore();
    final product = sampleProducts.first;

    store.add(product);
    store.checkoutDemo();
    store.add(product);

    expect(store.checkoutComplete, isFalse);
    expect(store.totalQuantity, 1);
  });
}
```

- [ ] **Step 2: Run cart tests to verify failure**

Run:

```bash
flutter test test/state/cart_store_test.dart
```

Expected: FAIL because `CartStore` does not exist.

- [ ] **Step 3: Implement cart store**

`lib/state/cart_store.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:kenko_shop/models/cart_item.dart';
import 'package:kenko_shop/models/product.dart';

class CartStore extends ChangeNotifier {
  final Map<String, CartItem> _itemsByProductId = {};
  bool _checkoutComplete = false;

  List<CartItem> get items => List.unmodifiable(_itemsByProductId.values);

  bool get isEmpty => _itemsByProductId.isEmpty;

  bool get checkoutComplete => _checkoutComplete;

  int get totalQuantity {
    return _itemsByProductId.values.fold<int>(
      0,
      (total, item) => total + item.quantity,
    );
  }

  double get subtotal {
    return _itemsByProductId.values.fold<double>(
      0,
      (total, item) => total + item.lineTotal,
    );
  }

  int quantityFor(String productId) {
    return _itemsByProductId[productId]?.quantity ?? 0;
  }

  void add(Product product) {
    final current = _itemsByProductId[product.id];
    _itemsByProductId[product.id] = current == null
        ? CartItem(product: product, quantity: 1)
        : current.copyWith(quantity: current.quantity + 1);
    _checkoutComplete = false;
    notifyListeners();
  }

  void increment(String productId) {
    final current = _itemsByProductId[productId];
    if (current == null) {
      return;
    }
    _itemsByProductId[productId] = current.copyWith(
      quantity: current.quantity + 1,
    );
    notifyListeners();
  }

  void decrement(String productId) {
    final current = _itemsByProductId[productId];
    if (current == null) {
      return;
    }
    if (current.quantity <= 1) {
      _itemsByProductId.remove(productId);
    } else {
      _itemsByProductId[productId] = current.copyWith(
        quantity: current.quantity - 1,
      );
    }
    notifyListeners();
  }

  void remove(String productId) {
    if (_itemsByProductId.remove(productId) != null) {
      notifyListeners();
    }
  }

  void checkoutDemo() {
    _itemsByProductId.clear();
    _checkoutComplete = true;
    notifyListeners();
  }
}
```

- [ ] **Step 4: Run cart tests**

Run:

```bash
flutter test test/state/cart_store_test.dart
flutter analyze
```

Expected: both pass.

- [ ] **Step 5: Commit cart store**

```bash
git add lib/state test/state
git commit -m "Add cart store"
```

## Task 4: Build Fresh Feed Screen And Widget Smoke Test

**Files:**
- Modify: `lib/app/kenko_app.dart`
- Create: `lib/screens/fresh_feed_screen.dart`
- Create: `lib/widgets/fresh_badge.dart`
- Create: `lib/widgets/product_scene.dart`
- Create: `lib/widgets/floating_cart_pill.dart`
- Create: `test/screens/fresh_feed_screen_test.dart`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Write feed widget test first**

`test/screens/fresh_feed_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kenko_shop/data/sample_products.dart';
import 'package:kenko_shop/screens/fresh_feed_screen.dart';
import 'package:kenko_shop/state/cart_store.dart';

void main() {
  testWidgets('renders feed and updates cart count', (tester) async {
    final cartStore = CartStore();

    await tester.pumpWidget(
      MaterialApp(
        home: FreshFeedScreen(
          products: sampleProducts,
          cartStore: cartStore,
        ),
      ),
    );

    expect(find.text(sampleProducts.first.name), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-to-cart-bok-choy')));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run feed test to verify failure**

Run:

```bash
flutter test test/screens/fresh_feed_screen_test.dart
```

Expected: FAIL because `FreshFeedScreen` does not exist.

- [ ] **Step 3: Add reusable badge**

`lib/widgets/fresh_badge.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:kenko_shop/app/theme.dart';

class FreshBadge extends StatelessWidget {
  const FreshBadge({
    required this.label,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final color = foregroundColor ?? KenkoColors.cream;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Add product scene**

`lib/widgets/product_scene.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:kenko_shop/app/theme.dart';
import 'package:kenko_shop/models/product.dart';
import 'package:kenko_shop/utils/drop_countdown.dart';
import 'package:kenko_shop/widgets/fresh_badge.dart';

class ProductScene extends StatelessWidget {
  const ProductScene({
    required this.product,
    required this.onAdd,
    required this.onOpenDetail,
    super.key,
  });

  final Product product;
  final VoidCallback onAdd;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final countdown = formatDropCountdown(product.dropEndsAt, DateTime.now());
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            product.palette.background,
            Color.alphaBlend(
              product.palette.primary.withValues(alpha: 0.18),
              product.palette.background,
            ),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _OrganicTexturePainter(product.palette.primary)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 116),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'KENKO FRESH',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const Spacer(),
                      FreshBadge(
                        label: product.harvestLabel,
                        icon: Icons.eco_outlined,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Center(
                    child: _ProduceMark(product: product),
                  ),
                  const Spacer(),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FreshBadge(
                        label: 'Soil ${product.soilScore}',
                        icon: Icons.grass_outlined,
                        backgroundColor: KenkoColors.soil.withValues(alpha: 0.55),
                      ),
                      if (countdown.isNotEmpty)
                        FreshBadge(
                          label: countdown,
                          icon: Icons.flash_on,
                          backgroundColor: KenkoColors.flash.withValues(alpha: 0.9),
                          foregroundColor: Colors.white,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: onOpenDetail,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 42,
                            height: 0.95,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          product.caption,
                          style: TextStyle(
                            color: KenkoColors.cream.withValues(alpha: 0.82),
                            fontSize: 15,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '${product.price.toStringAsFixed(0)} VND / ${product.unit}',
                          style: const TextStyle(
                            color: KenkoColors.harvest,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 122,
            child: FloatingActionButton(
              key: Key('add-to-cart-${product.id}'),
              heroTag: 'add-${product.id}',
              backgroundColor: KenkoColors.cream,
              foregroundColor: KenkoColors.rawBlack,
              onPressed: onAdd,
              child: const Icon(Icons.add_shopping_cart),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProduceMark extends StatelessWidget {
  const _ProduceMark({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              color: product.palette.primary.withValues(alpha: 0.28),
              shape: BoxShape.circle,
            ),
          ),
          Transform.rotate(
            angle: -0.28,
            child: Container(
              width: 155,
              height: 220,
              decoration: BoxDecoration(
                color: product.palette.secondary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(90),
                  topRight: Radius.circular(90),
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(96),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 38,
                    offset: const Offset(0, 22),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 34,
            top: 34,
            child: Container(
              width: 86,
              height: 42,
              decoration: BoxDecoration(
                color: product.palette.accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(42),
                  bottomRight: Radius.circular(42),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrganicTexturePainter extends CustomPainter {
  const _OrganicTexturePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 0; i < 18; i += 1) {
      final y = size.height * (i / 18);
      canvas.drawArc(
        Rect.fromLTWH(-60 + i * 12, y - 80, size.width + 120, 160),
        0.1,
        2.7,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrganicTexturePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
```

- [ ] **Step 5: Add floating cart pill**

`lib/widgets/floating_cart_pill.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:kenko_shop/app/theme.dart';

class FloatingCartPill extends StatelessWidget {
  const FloatingCartPill({
    required this.count,
    required this.onTap,
    super.key,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: KenkoColors.cream,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            key: const Key('floating-cart-pill'),
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shopping_basket_outlined,
                    color: KenkoColors.rawBlack,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$count',
                    style: const TextStyle(
                      color: KenkoColors.rawBlack,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Fresh cart',
                    style: TextStyle(
                      color: KenkoColors.rawBlack,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Add feed screen**

`lib/screens/fresh_feed_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:kenko_shop/models/product.dart';
import 'package:kenko_shop/state/cart_store.dart';
import 'package:kenko_shop/widgets/floating_cart_pill.dart';
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    widget.cartStore.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    widget.cartStore.removeListener(_onCartChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _openDetail(Product product) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const SizedBox.shrink();
      },
    );
  }

  void _openCart() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: widget.products.length,
            itemBuilder: (context, index) {
              final product = widget.products[index];
              return ProductScene(
                product: product,
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
}
```

- [ ] **Step 7: Wire app to feed**

Replace `lib/app/kenko_app.dart`:

```dart
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
  late final CartStore _cartStore;

  @override
  void initState() {
    super.initState();
    _cartStore = CartStore();
  }

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
      home: FreshFeedScreen(
        products: sampleProducts,
        cartStore: _cartStore,
      ),
    );
  }
}
```

Replace `test/widget_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kenko_shop/main.dart' as app;

void main() {
  testWidgets('Kenko app renders feed', (tester) async {
    app.main();
    await tester.pump();

    expect(find.text('KENKO FRESH'), findsOneWidget);
  });
}
```

- [ ] **Step 8: Run feed tests**

Run:

```bash
flutter test test/screens/fresh_feed_screen_test.dart
flutter test
flutter analyze
```

Expected: all pass.

- [ ] **Step 9: Commit feed**

```bash
git add lib/app lib/screens lib/widgets test
git commit -m "Build fresh feed screen"
```

## Task 5: Add Product Detail And Cart Sheets

**Files:**
- Create: `lib/widgets/product_detail_sheet.dart`
- Create: `lib/widgets/cart_sheet.dart`
- Modify: `lib/screens/fresh_feed_screen.dart`
- Modify: `test/screens/fresh_feed_screen_test.dart`

- [ ] **Step 1: Extend widget test for detail and cart sheets**

Append this test to `test/screens/fresh_feed_screen_test.dart`:

```dart
testWidgets('opens product detail and cart sheets', (tester) async {
  final cartStore = CartStore();

  await tester.pumpWidget(
    MaterialApp(
      home: FreshFeedScreen(
        products: sampleProducts,
        cartStore: cartStore,
      ),
    ),
  );

  await tester.tap(find.text(sampleProducts.first.name));
  await tester.pumpAndSettle();

  expect(find.text(sampleProducts.first.origin.name), findsOneWidget);
  expect(find.text('Suggested bundle'), findsOneWidget);

  await tester.tap(find.byTooltip('Close detail'));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('add-to-cart-bok-choy')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('floating-cart-pill')));
  await tester.pumpAndSettle();

  expect(find.text('Your fresh cart'), findsOneWidget);
  expect(find.text(sampleProducts.first.name), findsWidgets);
});
```

- [ ] **Step 2: Run extended test to verify failure**

Run:

```bash
flutter test test/screens/fresh_feed_screen_test.dart
```

Expected: FAIL because sheets are placeholders.

- [ ] **Step 3: Implement product detail sheet**

`lib/widgets/product_detail_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:kenko_shop/app/theme.dart';
import 'package:kenko_shop/data/sample_products.dart';
import 'package:kenko_shop/models/product.dart';
import 'package:kenko_shop/widgets/fresh_badge.dart';

class ProductDetailSheet extends StatelessWidget {
  const ProductDetailSheet({
    required this.product,
    required this.onAdd,
    super.key,
  });

  final Product product;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final bundleProducts = product.bundleProductIds
        .map(findProductById)
        .whereType<Product>()
        .toList(growable: false);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: KenkoColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: KenkoColors.rawBlack.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Close detail',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: KenkoColors.rawBlack),
                ),
              ),
              Text(
                product.name,
                style: const TextStyle(
                  color: KenkoColors.rawBlack,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.origin.name,
                style: const TextStyle(
                  color: KenkoColors.moss,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.origin.story,
                style: TextStyle(
                  color: KenkoColors.rawBlack.withValues(alpha: 0.72),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FreshBadge(
                    label: 'Soil ${product.soilScore}',
                    backgroundColor: KenkoColors.soil,
                  ),
                  FreshBadge(
                    label: product.harvestLabel,
                    backgroundColor: KenkoColors.moss,
                  ),
                  for (final tag in product.nutritionTags)
                    FreshBadge(
                      label: '${tag.label}: ${tag.value}',
                      backgroundColor: KenkoColors.rawBlack,
                    ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Suggested bundle',
                style: TextStyle(
                  color: KenkoColors.rawBlack,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              if (bundleProducts.isEmpty)
                Text(
                  'This harvest is best on its own.',
                  style: TextStyle(
                    color: KenkoColors.rawBlack.withValues(alpha: 0.7),
                  ),
                )
              else
                for (final bundle in bundleProducts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: bundle.palette.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            bundle.name,
                            style: const TextStyle(
                              color: KenkoColors.rawBlack,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_shopping_cart),
                label: Text('Add ${product.unit}'),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 4: Implement cart sheet**

`lib/widgets/cart_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:kenko_shop/app/theme.dart';
import 'package:kenko_shop/state/cart_store.dart';

class CartSheet extends StatelessWidget {
  const CartSheet({
    required this.cartStore,
    super.key,
  });

  final CartStore cartStore;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cartStore,
      builder: (context, _) {
        return DraggableScrollableSheet(
          initialChildSize: 0.68,
          minChildSize: 0.36,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return DecoratedBox(
              decoration: const BoxDecoration(
                color: KenkoColors.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                children: [
                  const Text(
                    'Your fresh cart',
                    style: TextStyle(
                      color: KenkoColors.rawBlack,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (cartStore.checkoutComplete)
                    const Text(
                      'Demo order packed. No payment was processed.',
                      style: TextStyle(
                        color: KenkoColors.moss,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  else if (cartStore.isEmpty)
                    Text(
                      'Swipe the harvest feed and tap + to start a basket.',
                      style: TextStyle(
                        color: KenkoColors.rawBlack.withValues(alpha: 0.7),
                      ),
                    )
                  else ...[
                    for (final item in cartStore.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: const TextStyle(
                                      color: KenkoColors.rawBlack,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    '${item.product.price.toStringAsFixed(0)} VND / ${item.product.unit}',
                                    style: TextStyle(
                                      color: KenkoColors.rawBlack.withValues(alpha: 0.62),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => cartStore.decrement(item.product.id),
                              icon: const Icon(Icons.remove_circle_outline),
                              color: KenkoColors.rawBlack,
                            ),
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                color: KenkoColors.rawBlack,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            IconButton(
                              onPressed: () => cartStore.increment(item.product.id),
                              icon: const Icon(Icons.add_circle_outline),
                              color: KenkoColors.rawBlack,
                            ),
                          ],
                        ),
                      ),
                    const Divider(color: Color(0x335E9B56)),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Subtotal',
                            style: TextStyle(
                              color: KenkoColors.rawBlack,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          '${cartStore.subtotal.toStringAsFixed(0)} VND',
                          style: const TextStyle(
                            color: KenkoColors.rawBlack,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: cartStore.checkoutDemo,
                      child: const Text('Checkout Demo'),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
```

- [ ] **Step 5: Wire sheets into feed**

Update imports and methods in `lib/screens/fresh_feed_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:kenko_shop/models/product.dart';
import 'package:kenko_shop/state/cart_store.dart';
import 'package:kenko_shop/widgets/cart_sheet.dart';
import 'package:kenko_shop/widgets/floating_cart_pill.dart';
import 'package:kenko_shop/widgets/product_detail_sheet.dart';
import 'package:kenko_shop/widgets/product_scene.dart';
```

Replace `_openDetail` and `_openCart`:

```dart
  void _openDetail(Product product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ProductDetailSheet(
          product: product,
          onAdd: () => widget.cartStore.add(product),
        );
      },
    );
  }

  void _openCart() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CartSheet(cartStore: widget.cartStore);
      },
    );
  }
```

- [ ] **Step 6: Run sheet tests**

Run:

```bash
flutter test test/screens/fresh_feed_screen_test.dart
flutter test
flutter analyze
```

Expected: all pass.

- [ ] **Step 7: Commit sheets**

```bash
git add lib/screens lib/widgets test/screens
git commit -m "Add product detail and cart sheets"
```

## Task 6: Final Visual Polish And Platform Build Verification

**Files:**
- Modify: `lib/widgets/product_scene.dart`
- Modify: `lib/widgets/cart_sheet.dart`
- Modify: `lib/widgets/product_detail_sheet.dart`
- Modify: `.gitignore` if Flutter generated files require standard ignores

- [ ] **Step 1: Run full verification before polish**

Run:

```bash
flutter analyze
flutter test
flutter build apk --debug
```

Expected: analyze/test pass. APK debug build passes if Android SDK licenses/tooling are available in the environment.

- [ ] **Step 2: Inspect generated ignore state**

Run:

```bash
git status --short
```

Expected: source files and generated project files are visible; transient `.dart_tool/`, `build/`, and platform build products are ignored.

- [ ] **Step 3: Polish visual details without changing behavior**

Apply only non-functional refinements:

- Ensure text does not overlap on narrow screens by keeping body copy below 16px and constraining large product names to the lower third.
- Keep feed controls above the floating cart pill.
- Keep red-orange limited-drop accents limited to countdown/drop UI.
- Keep `CustomPainter` deterministic and not animated per frame.

- [ ] **Step 4: Run final verification**

Run:

```bash
flutter analyze
flutter test
flutter build apk --debug
```

Expected:

- `flutter analyze`: no issues.
- `flutter test`: all unit and widget tests pass.
- `flutter build apk --debug`: debug APK builds, unless blocked by missing Android SDK/license setup. If blocked, record the exact tooling error.

- [ ] **Step 5: Optional local run if device/emulator exists**

Run:

```bash
flutter devices
flutter run
```

Expected: if a device/emulator is available, the app launches to the Fresh Feed.

- [ ] **Step 6: Commit final verification changes**

```bash
git add .
git commit -m "Polish Kenko Fresh prototype"
```

## Self-Review

Spec coverage:

- Offline Flutter app: Task 1.
- Android/iOS one codebase: Task 1 creates both platforms; Task 6 verifies Android locally and documents iOS constraint.
- Offline fixtures: Task 2.
- Asset strategy: Task 4 and Task 6 use procedural Flutter visuals and no network assets.
- Vertical Fresh Feed: Task 4.
- Add-to-cart: Tasks 3 and 4.
- Product detail sheet: Task 5.
- Cart sheet and demo checkout: Tasks 3 and 5.
- `dropEndsAt` countdown: Task 2.
- `soilScore` badge: Task 4.
- `bundleProductIds`: Tasks 2 and 5.
- Gesture/navigation behavior: Tasks 4 and 5 keep feed state mounted and use modal sheets.
- Tests: Tasks 2, 3, 4, and 5.
- Local verification: Task 6.

Placeholder scan:

- No `TBD`, `TODO`, `implement later`, or unspecified test targets remain.

Type consistency:

- `Product.dropEndsAt`, `Product.bundleProductIds`, `ProductPalette`, `CartStore`, and `formatDropCountdown` are named consistently across tasks.
