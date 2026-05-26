class OrderResult {
  const OrderResult({
    required this.orderId,
    required this.orderCode,
    required this.total,
    required this.status,
  });

  factory OrderResult.fromJson(Map<String, dynamic> json) {
    return OrderResult(
      orderId: json['order_id'] as String,
      orderCode: json['order_code'] as String,
      total: (json['total'] as num).toInt(),
      status: json['status'] as String,
    );
  }

  final String orderId;
  final String orderCode;
  final int total;
  final String status;
}
