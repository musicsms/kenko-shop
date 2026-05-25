import 'package:flutter/material.dart';
import 'package:kenko_shop/app/theme.dart';
import 'package:kenko_shop/data/sample_products.dart';
import 'package:kenko_shop/models/product.dart';

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
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.38,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: KenkoColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              24,
              10,
              24,
              28 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            children: [
              const Center(child: _SheetHandle()),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: KenkoColors.rawBlack,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close detail',
                    color: KenkoColors.rawBlack,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${product.price.toStringAsFixed(0)} VND / ${product.unit}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: product.palette.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Taste & use',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: KenkoColors.rawBlack,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                product.caption,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 15,
                  color: KenkoColors.rawBlack.withValues(alpha: 0.72),
                  height: 1.32,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                product.origin.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: KenkoColors.moss,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.origin.story,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 15,
                  color: KenkoColors.rawBlack.withValues(alpha: 0.72),
                  height: 1.32,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _DetailBadge(label: 'Soil ${product.soilScore}'),
                  _DetailBadge(label: product.harvestLabel),
                  for (final tag in product.nutritionTags)
                    _DetailBadge(label: '${tag.label}: ${tag.value}'),
                ],
              ),
              const SizedBox(height: 26),
              Text(
                'Suggested bundle',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: KenkoColors.rawBlack,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              if (bundleProducts.isEmpty)
                Text(
                  'No bundle picks for this drop yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: KenkoColors.rawBlack.withValues(alpha: 0.64),
                  ),
                )
              else
                for (final bundleProduct in bundleProducts)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: product.palette.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            bundleProduct.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontSize: 15,
                                  color: KenkoColors.rawBlack,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: 26),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Add to cart'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 5,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: KenkoColors.rawBlack.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _DetailBadge extends StatelessWidget {
  const _DetailBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KenkoColors.rawBlack.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: KenkoColors.rawBlack,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
