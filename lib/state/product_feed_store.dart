import 'package:flutter/foundation.dart';
import 'package:kenko_shop/models/product.dart';

typedef ProductLoader = Future<List<Product>> Function();

class ProductFeedStore extends ChangeNotifier {
  ProductFeedStore(this._loader);

  final ProductLoader _loader;

  bool _isLoading = false;
  List<Product> _products = [];
  String? _errorMessage;

  bool get isLoading => _isLoading;
  List<Product> get products => List<Product>.unmodifiable(_products);
  String? get errorMessage => _errorMessage;
  bool get isEmpty => !_isLoading && _products.isEmpty && _errorMessage == null;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _loader();
    } catch (error) {
      _products = [];
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
