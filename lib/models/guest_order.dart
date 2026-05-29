class GuestOrderItem {
  const GuestOrderItem({required this.productSlug, required this.quantity});

  final String productSlug;
  final int quantity;

  Map<String, dynamic> toJson() {
    return {'product_slug': productSlug, 'quantity': quantity};
  }
}

class GuestOrderRequest {
  GuestOrderRequest({
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required List<GuestOrderItem> items,
    this.note,
  }) : items = List<GuestOrderItem>.unmodifiable(items);

  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final List<GuestOrderItem> items;
  final String? note;
}
