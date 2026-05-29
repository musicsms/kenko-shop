import 'package:flutter_test/flutter_test.dart';
import 'package:kenko_shop/data/order_repository.dart';
import 'package:kenko_shop/models/guest_order.dart';
import 'package:kenko_shop/models/order_result.dart';

void main() {
  group('buildCreateGuestOrderPayload', () {
    test('maps guest order fields and items for the checkout RPC', () {
      final request = GuestOrderRequest(
        customerName: ' Linh Tran ',
        customerPhone: ' 090 123 4567 ',
        deliveryAddress: ' 12 Nguyen Trai, District 1 ',
        note: ' Leave with reception ',
        items: [
          const GuestOrderItem(productSlug: 'bok-choy', quantity: 2),
          const GuestOrderItem(productSlug: 'dragon-fruit', quantity: 1),
        ],
      );

      final payload = buildCreateGuestOrderPayload(request);

      expect(payload['customer_name'], 'Linh Tran');
      expect(payload['customer_phone'], '090 123 4567');
      expect(payload['delivery_address'], '12 Nguyen Trai, District 1');
      expect(payload['note'], 'Leave with reception');
      expect(payload['items'], [
        {'product_slug': 'bok-choy', 'quantity': 2},
        {'product_slug': 'dragon-fruit', 'quantity': 1},
      ]);
    });

    test('does not include client-computed totals', () {
      final request = GuestOrderRequest(
        customerName: 'Linh Tran',
        customerPhone: '0901234567',
        deliveryAddress: '12 Nguyen Trai, District 1',
        note: null,
        items: [const GuestOrderItem(productSlug: 'bok-choy', quantity: 2)],
      );

      final payload = buildCreateGuestOrderPayload(request);

      expect(payload, isNot(contains('subtotal')));
      expect(payload, isNot(contains('total')));
    });
  });

  group('GuestOrderRequest', () {
    test('defensively copies items as an unmodifiable list', () {
      final items = [
        const GuestOrderItem(productSlug: 'bok-choy', quantity: 1),
      ];
      final request = GuestOrderRequest(
        customerName: 'Linh Tran',
        customerPhone: '0901234567',
        deliveryAddress: '12 Nguyen Trai, District 1',
        note: null,
        items: items,
      );

      items.add(const GuestOrderItem(productSlug: 'dragon-fruit', quantity: 2));

      expect(request.items, hasLength(1));
      expect(
        () => request.items.add(
          const GuestOrderItem(productSlug: 'purple-basil', quantity: 1),
        ),
        throwsUnsupportedError,
      );
    });
  });

  group('OrderResult', () {
    test('parses checkout RPC response fields', () {
      final result = OrderResult.fromJson({
        'order_id': '8fc68ce5-2b12-4e52-bb40-730687b9bb93',
        'order_code': 'KF-20260526-001',
        'total': 126000,
        'status': 'new',
      });

      expect(result.orderId, '8fc68ce5-2b12-4e52-bb40-730687b9bb93');
      expect(result.orderCode, 'KF-20260526-001');
      expect(result.total, 126000);
      expect(result.status, 'new');
    });
  });
}
