import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kenko_shop/screens/you_screen.dart';
import 'package:kenko_shop/state/auth_store.dart';

class FakeAuthStore extends AuthStoreBase {
  FakeAuthStore({bool isSignedIn = false, String? userEmail})
      : _isSignedIn = isSignedIn,
        _userEmail = userEmail;

  bool _isSignedIn;
  String? _userEmail;

  @override
  bool get isSignedIn => _isSignedIn;

  @override
  String? get userEmail => _userEmail;

  void setAuth({required bool signedIn, String? email}) {
    _isSignedIn = signedIn;
    _userEmail = email;
    notifyListeners();
  }
}

void main() {
  testWidgets('shows sign-in prompt when signed out', (tester) async {
    final authStore = FakeAuthStore(isSignedIn: false);
    addTearDown(authStore.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: YouScreen(
          authStore: authStore,
          onSignIn: () {},
          onSignOut: () {},
        ),
      ),
    );

    expect(find.text('Track your orders'), findsOneWidget);
    expect(find.byKey(const Key('you-sign-in-button')), findsOneWidget);
    expect(find.byKey(const Key('you-email-text')), findsNothing);
  });

  testWidgets('shows email and sign-out button when signed in', (tester) async {
    final authStore = FakeAuthStore(
      isSignedIn: true,
      userEmail: 'minh@example.com',
    );
    addTearDown(authStore.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: YouScreen(
          authStore: authStore,
          onSignIn: () {},
          onSignOut: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('you-email-text')), findsOneWidget);
    expect(find.text('minh@example.com'), findsOneWidget);
    expect(find.byKey(const Key('you-sign-out-button')), findsOneWidget);
    expect(find.text('Track your orders'), findsNothing);
  });

  testWidgets('calls onSignIn when sign-in button tapped', (tester) async {
    final authStore = FakeAuthStore(isSignedIn: false);
    addTearDown(authStore.dispose);
    var signInCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: YouScreen(
          authStore: authStore,
          onSignIn: () => signInCalled = true,
          onSignOut: () {},
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('you-sign-in-button')));
    await tester.pump();

    expect(signInCalled, isTrue);
  });

  testWidgets('calls onSignOut when sign-out button tapped', (tester) async {
    final authStore = FakeAuthStore(
      isSignedIn: true,
      userEmail: 'minh@example.com',
    );
    addTearDown(authStore.dispose);
    var signOutCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: YouScreen(
          authStore: authStore,
          onSignIn: () {},
          onSignOut: () => signOutCalled = true,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('you-sign-out-button')));
    await tester.pump();

    expect(signOutCalled, isTrue);
  });

  testWidgets('updates view when auth state changes', (tester) async {
    final authStore = FakeAuthStore(isSignedIn: false);
    addTearDown(authStore.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: YouScreen(
          authStore: authStore,
          onSignIn: () {},
          onSignOut: () {},
        ),
      ),
    );

    expect(find.text('Track your orders'), findsOneWidget);

    authStore.setAuth(signedIn: true, email: 'minh@example.com');
    await tester.pump();

    expect(find.text('Track your orders'), findsNothing);
    expect(find.text('minh@example.com'), findsOneWidget);
  });
}
