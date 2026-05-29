import 'package:flutter/material.dart';
import 'package:kenko_shop/app/theme.dart';
import 'package:kenko_shop/data/sample_products.dart';
import 'package:kenko_shop/models/product.dart';
import 'package:kenko_shop/state/cart_store.dart';
import 'package:kenko_shop/widgets/product_detail_sheet.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({required this.cartStore, super.key});

  final CartStore cartStore;

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedCategory;

  static final _allCategories = List<String>.unmodifiable(
    sampleProducts.map((p) => p.category).toSet().toList()..sort(),
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> get _filtered {
    final q = _query.toLowerCase();
    return sampleProducts.where((p) {
      final matchCat =
          _selectedCategory == null || p.category == _selectedCategory;
      final matchQ = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
      return matchCat && matchQ;
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [KenkoColors.rawBlack, Color(0xFF0D1F10), KenkoColors.rawBlack],
          ),
        ),
        child: SafeArea(
          child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                key: const Key('browse-search-field'),
                controller: _searchController,
                style: const TextStyle(
                  color: KenkoColors.cream,
                  fontWeight: FontWeight.w700,
                ),
                cursorColor: KenkoColors.harvest,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(
                    color: KenkoColors.cream.withValues(alpha: 0.42),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: KenkoColors.cream.withValues(alpha: 0.6),
                  ),
                  filled: true,
                  fillColor: KenkoColors.rawBlack.withValues(alpha: 0.6),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: KenkoColors.cream.withValues(alpha: 0.18),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: KenkoColors.harvest,
                      width: 1.6,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CategoryChip(
                    chipKey: const Key('browse-chip-All'),
                    label: 'All',
                    isSelected: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                  ..._allCategories.map(
                    (cat) => _CategoryChip(
                      chipKey: Key('browse-chip-$cat'),
                      label: cat,
                      isSelected: _selectedCategory == cat,
                      onTap: () => setState(() => _selectedCategory = cat),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth =
                      (constraints.maxWidth - 16 * 2 - 12) / 2;
                  final cardHeight = cardWidth / 0.82;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _filtered.map((product) => SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: _ProductBrowseCard(
                          product: product,
                          onAdd: () => widget.cartStore.add(product),
                          onTap: () => _openDetail(product),
                        ),
                      )).toList(growable: false),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  void _openDetail(Product product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductDetailSheet(
        product: product,
        onAdd: () => widget.cartStore.add(product),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.chipKey,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final Key chipKey;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        key: chipKey,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? KenkoColors.moss : KenkoColors.rawBlack,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? KenkoColors.moss
                  : KenkoColors.cream.withValues(alpha: 0.22),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? KenkoColors.cream : KenkoColors.cream.withValues(alpha: 0.72),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductBrowseCard extends StatelessWidget {
  const _ProductBrowseCard({
    required this.product,
    required this.onAdd,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onAdd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              product.palette.background,
              Color.lerp(
                product.palette.background,
                product.palette.primary,
                0.28,
              )!,
            ],
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.isLimitedDrop) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: KenkoColors.flash,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'DROP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: product.palette.secondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.price.toStringAsFixed(0)} VND',
                    style: TextStyle(
                      color: product.palette.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.unit,
                    style: TextStyle(
                      color: product.palette.secondary.withValues(alpha: 0.62),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: GestureDetector(
                key: Key('browse-add-${product.id}'),
                onTap: onAdd,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: KenkoColors.harvest,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: KenkoColors.rawBlack,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
