import 'package:kenko_shop/models/guest_order.dart';
import 'package:kenko_shop/models/order_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderRepository {
  OrderRepository(this._client);

  final SupabaseClient _client;

  Future<OrderResult> createGuestOrder(GuestOrderRequest request) async {
    final response = await _client.rpc(
      'create_guest_order',
      params: buildCreateGuestOrderPayload(request),
    );

    return OrderResult.fromJson(Map<String, dynamic>.from(response as Map));
  }
}

Map<String, dynamic> buildCreateGuestOrderPayload(GuestOrderRequest request) {
  return {
    'customer_name': request.customerName.trim(),
    'customer_phone': request.customerPhone.trim(),
    'delivery_address': request.deliveryAddress.trim(),
    'note': request.note?.trim(),
    'items': request.items.map((item) => item.toJson()).toList(growable: false),
  };
}
