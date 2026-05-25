import 'package:flutter/material.dart';
import 'package:kenko_shop/app/theme.dart';
import 'package:kenko_shop/state/cart_store.dart';

class CartSheet extends StatelessWidget {
  const CartSheet({required this.cartStore, super.key});

  final CartStore cartStore;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cartStore,
      builder: (context, child) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.58,
          minChildSize: 0.28,
          maxChildSize: 0.88,
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
                  18,
                  24,
                  28 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                children: [
                  const Center(child: _SheetHandle()),
                  Text(
                    'Your fresh cart',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: KenkoColors.rawBlack,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (cartStore.checkoutComplete)
                    Text(
                      'Demo order packed. No payment was processed.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        color: KenkoColors.rawBlack.withValues(alpha: 0.72),
                      ),
                    )
                  else if (cartStore.isEmpty)
                    Text(
                      'Your basket is ready for the next fresh drop.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        color: KenkoColors.rawBlack.withValues(alpha: 0.72),
                      ),
                    )
                  else ...[
                    for (final item in cartStore.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: KenkoColors.rawBlack,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.product.price.toStringAsFixed(0)} VND / ${item.product.unit}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: KenkoColors.rawBlack
                                              .withValues(alpha: 0.62),
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Decrease ${item.product.name}',
                              color: KenkoColors.rawBlack,
                              onPressed: () =>
                                  cartStore.decrement(item.product.id),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            SizedBox(
                              width: 28,
                              child: Text(
                                '${item.quantity}',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: KenkoColors.rawBlack,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Increase ${item.product.name}',
                              color: KenkoColors.rawBlack,
                              onPressed: () =>
                                  cartStore.increment(item.product.id),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ),
                    const Divider(color: KenkoColors.rawBlack),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Subtotal',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: KenkoColors.rawBlack,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            '${cartStore.subtotal.toStringAsFixed(0)} VND',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: KenkoColors.rawBlack,
                                  fontWeight: FontWeight.w900,
                                ),
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
