import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthStoreBase extends ChangeNotifier {
  bool get isSignedIn;
  String? get userEmail;
}

class AuthStore extends AuthStoreBase {
  AuthStore(SupabaseClient client) {
    final auth = client.auth;
    _isSignedIn = auth.currentUser != null;
    _userEmail = auth.currentUser?.email;
    _subscription = auth.onAuthStateChange.listen((state) {
      _isSignedIn = state.session != null;
      _userEmail = state.session?.user.email;
      notifyListeners();
    });
  }

  StreamSubscription<AuthState>? _subscription;
  bool _isSignedIn = false;
  String? _userEmail;

  @override
  bool get isSignedIn => _isSignedIn;

  @override
  String? get userEmail => _userEmail;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
