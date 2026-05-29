import 'package:flutter/foundation.dart';
import 'package:kenko_shop/models/product.dart';

typedef ProductLoader = Future<List<Product>> Function();

class ProductFeedStore extends ChangeNotifier {
  ProductFeedStore(this._loader);

  final ProductLoader _loader;

  bool _isLoading = false;
  List<Product> _products = [];
  String? _errorMessage;
  bool _isDisposed = false;
  int _loadGeneration = 0;

  bool get isLoading => _isLoading;
  List<Product> get products => List<Product>.unmodifiable(_products);
  String? get errorMessage => _errorMessage;
  bool get isEmpty => !_isLoading && _products.isEmpty && _errorMessage == null;

  Future<void> load() async {
    if (_isDisposed) {
      return;
    }

    final generation = ++_loadGeneration;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final products = await _loader();
      if (!_canApply(generation)) {
        return;
      }
      _products = products;
    } catch (error) {
      if (!_canApply(generation)) {
        return;
      }
      _products = [];
      _errorMessage = error.toString();
    } finally {
      if (_canApply(generation)) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  bool _canApply(int generation) {
    return !_isDisposed && generation == _loadGeneration;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _loadGeneration += 1;
    super.dispose();
  }
}
