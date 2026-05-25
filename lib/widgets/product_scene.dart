import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kenko_shop/app/theme.dart';
import 'package:kenko_shop/models/product.dart';
import 'package:kenko_shop/models/product_palette.dart';
import 'package:kenko_shop/utils/drop_countdown.dart';
import 'package:kenko_shop/widgets/fresh_badge.dart';

class ProductScene extends StatelessWidget {
  const ProductScene({
    required this.product,
    required this.onAdd,
    required this.onOpenDetail,
    super.key,
    this.now,
  });

  final Product product;
  final VoidCallback onAdd;
  final VoidCallback onOpenDetail;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final palette = product.palette;
    final countdownLabel = product.dropEndsAt == null
        ? ''
        : formatDropCountdown(product.dropEndsAt, _countdownNow());

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.background,
            Color.lerp(palette.background, palette.primary, 0.28)!,
            palette.background,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _TexturePainter(palette)),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final markSize = math.min(
                  constraints.maxWidth * 0.72,
                  math.min(constraints.maxHeight * 0.42, 320.0),
                );

                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SceneHeader(product: product),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onOpenDetail,
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                CustomPaint(
                                  size: Size.square(markSize),
                                  painter: _ProduceMarkPainter(product),
                                ),
                                if (countdownLabel.isNotEmpty)
                                  Positioned(
                                    right: 0,
                                    bottom: markSize * 0.12,
                                    child: FreshBadge(
                                      label: countdownLabel,
                                      icon: Icons.timer_outlined,
                                      backgroundColor: palette.accent,
                                      foregroundColor: KenkoColors.rawBlack,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _ProductCopy(
                        product: product,
                        onOpenDetail: onOpenDetail,
                      ),
                      const SizedBox(height: 108),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            right: 24,
            bottom: 104,
            child: FloatingActionButton(
              key: Key('add-to-cart-${product.id}'),
              heroTag: 'add-to-cart-${product.id}',
              backgroundColor: KenkoColors.cream,
              foregroundColor: KenkoColors.rawBlack,
              tooltip: 'Add ${product.name} to cart',
              onPressed: onAdd,
              child: const Icon(Icons.add_shopping_cart),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _countdownNow() {
    return now ?? DateTime.now();
  }
}

class _SceneHeader extends StatelessWidget {
  const _SceneHeader({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        Text(
          'KENKO FRESH',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: KenkoColors.cream,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.6,
          ),
        ),
        FreshBadge(
          label: product.harvestLabel,
          icon: Icons.eco_outlined,
          backgroundColor: KenkoColors.cream,
          foregroundColor: KenkoColors.rawBlack,
        ),
      ],
    );
  }
}

class _ProductCopy extends StatelessWidget {
  const _ProductCopy({required this.product, required this.onOpenDetail});

  final Product product;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: 'Open ${product.name}',
      child: GestureDetector(
        key: Key('product-panel-${product.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onOpenDetail,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FreshBadge(
              label: 'Soil score ${product.soilScore}',
              icon: Icons.verified_outlined,
              backgroundColor: KenkoColors.soil,
              foregroundColor: KenkoColors.cream,
              borderColor: KenkoColors.cream.withValues(alpha: 0.18),
            ),
            const SizedBox(height: 14),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.displaySmall?.copyWith(
                color: KenkoColors.cream,
                fontWeight: FontWeight.w900,
                height: 0.98,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              product.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyLarge?.copyWith(
                color: KenkoColors.cream.withValues(alpha: 0.78),
                height: 1.25,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.agriculture_outlined,
                  color: product.palette.secondary.withValues(alpha: 0.86),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    product.origin.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      color: KenkoColors.cream.withValues(alpha: 0.74),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '${product.price.toStringAsFixed(0)} VND / ${product.unit}',
              style: textTheme.titleLarge?.copyWith(
                color: product.palette.accent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TexturePainter extends CustomPainter {
  const _TexturePainter(this.palette);

  final ProductPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = palette.secondary.withValues(alpha: 0.08);

    for (var i = 0; i < 9; i++) {
      final dx = size.width * ((i * 0.19) % 1.0);
      final dy = size.height * ((i * 0.31) % 1.0);
      canvas.drawCircle(Offset(dx, dy), 42 + i * 11, paint);
    }

    final dashPaint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = palette.accent.withValues(alpha: 0.14);

    for (var y = size.height * 0.18; y < size.height; y += 84) {
      for (var x = -30.0; x < size.width; x += 78) {
        canvas.drawLine(Offset(x, y), Offset(x + 24, y - 12), dashPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_TexturePainter oldDelegate) {
    return oldDelegate.palette != palette;
  }
}

class _ProduceMarkPainter extends CustomPainter {
  const _ProduceMarkPainter(this.product);

  final Product product;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final palette = product.palette;

    final glowPaint = Paint()
      ..color = palette.primary.withValues(alpha: 0.24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawCircle(center, radius * 0.72, glowPaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.04
      ..color = palette.secondary.withValues(alpha: 0.54);
    canvas.drawCircle(center, radius * 0.68, ringPaint);

    for (var i = 0; i < 8; i++) {
      final angle = (math.pi * 2 / 8) * i;
      final petalCenter =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.34;
      final rect = Rect.fromCenter(
        center: petalCenter,
        width: radius * 0.58,
        height: radius * 0.28,
      );

      canvas.save();
      canvas.translate(petalCenter.dx, petalCenter.dy);
      canvas.rotate(angle);
      canvas.translate(-petalCenter.dx, -petalCenter.dy);
      canvas.drawOval(
        rect,
        Paint()
          ..color = Color.lerp(
            palette.primary,
            palette.secondary,
            i.isEven ? 0.22 : 0.44,
          )!,
      );
      canvas.restore();
    }

    final corePaint = Paint()..color = palette.accent;
    canvas.drawCircle(center, radius * 0.22, corePaint);

    final stemPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.05
      ..strokeCap = StrokeCap.round
      ..color = KenkoColors.cream.withValues(alpha: 0.72);

    final stem = Path()
      ..moveTo(center.dx, center.dy + radius * 0.18)
      ..quadraticBezierTo(
        center.dx - radius * 0.16,
        center.dy + radius * 0.44,
        center.dx + radius * 0.08,
        center.dy + radius * 0.64,
      );
    canvas.drawPath(stem, stemPaint);
  }

  @override
  bool shouldRepaint(_ProduceMarkPainter oldDelegate) {
    return oldDelegate.product != product;
  }
}
