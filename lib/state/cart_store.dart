import 'package:flutter/foundation.dart';
import 'package:kenko_shop/models/cart_item.dart';
import 'package:kenko_shop/models/product.dart';

class CartStore extends ChangeNotifier {
  final Map<String, CartItem> _itemsByProductId = {};
  bool _checkoutComplete = false;

  List<CartItem> get items =>
      List<CartItem>.unmodifiable(_itemsByProductId.values);

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
    final existingItem = _itemsByProductId[product.id];
    _itemsByProductId[product.id] = existingItem == null
        ? CartItem(product: product, quantity: 1)
        : existingItem.copyWith(quantity: existingItem.quantity + 1);
    _checkoutComplete = false;
    notifyListeners();
  }

  void increment(String productId) {
    final existingItem = _itemsByProductId[productId];
    if (existingItem == null) {
      return;
    }

    _itemsByProductId[productId] = existingItem.copyWith(
      quantity: existingItem.quantity + 1,
    );
    notifyListeners();
  }

  void decrement(String productId) {
    final existingItem = _itemsByProductId[productId];
    if (existingItem == null) {
      return;
    }

    if (existingItem.quantity <= 1) {
      _itemsByProductId.remove(productId);
    } else {
      _itemsByProductId[productId] = existingItem.copyWith(
        quantity: existingItem.quantity - 1,
      );
    }
    notifyListeners();
  }

  void remove(String productId) {
    final removedItem = _itemsByProductId.remove(productId);
    if (removedItem == null) {
      return;
    }

    notifyListeners();
  }

  void checkoutDemo() {
    _itemsByProductId.clear();
    _checkoutComplete = true;
    notifyListeners();
  }
}
