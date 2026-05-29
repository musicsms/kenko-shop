import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  const AuthRepository(this._auth);

  final GoTrueClient _auth;

  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUpWithEmail(String email, String password) async {
    await _auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
