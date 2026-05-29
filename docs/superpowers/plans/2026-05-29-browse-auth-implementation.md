# Browse Tab + Auth Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the Browse tab (search + category filter + product grid) and optional email/password auth (Supabase) wired into the existing checkout flow and a new You profile tab.

**Architecture:** All new code lives in `.worktrees/kenko-fresh-impl/`. New files follow the existing layer split: `data/` for repos, `state/` for ChangeNotifier stores, `screens/` for full-screen tabs, `widgets/` for sheets. Auth uses an abstract `AuthStoreBase` so widget tests can inject a fake without Supabase. All new constructor params in existing screens are optional so no existing tests break.

**Tech Stack:** Flutter 3.41.9 / Dart 3.11.5, `supabase_flutter: ^2.12.4` (GoTrueClient already in pubspec), `ChangeNotifier`, Material 3, existing `KenkoColors` theme.

> **Working directory for all commands:** `.worktrees/kenko-fresh-impl/`

---

## File Structure

New files:
- `lib/data/auth_repository.dart` — thin Supabase auth wrapper (sign-in, sign-up, sign-out)
- `lib/state/auth_store.dart` — `AuthStoreBase` abstract + `AuthStore` concrete (listens to Supabase auth stream)
- `lib/widgets/auth_sheet.dart` — bottom sheet with email/password form, toggle sign-in/sign-up
- `lib/screens/browse_screen.dart` — search bar + category chips + 2-column product grid
- `lib/screens/you_screen.dart` — signed-in profile view vs. signed-out prompt
- `test/screens/browse_screen_test.dart` — widget tests for filter and search
- `test/screens/you_screen_test.dart` — widget tests for signed-in/out states

Modified files:
- `lib/app/kenko_app.dart` — instantiate AuthStore + AuthRepository, pass to FreshFeedScreen
- `lib/screens/fresh_feed_screen.dart` — accept optional auth deps, wire tab 1 → BrowseScreen, tab 3 → YouScreen, pass authRepository to CartSheet
- `lib/widgets/cart_sheet.dart` — add optional `authRepository`, wire "Continue with email" and "Create account to track" to AuthSheet

---

## Task 1: AuthRepository + AuthStore

**Files:**
- Create: `lib/data/auth_repository.dart`
- Create: `lib/state/auth_store.dart`

- [ ] **Step 1: Create `lib/data/auth_repository.dart`**

```dart
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
```

- [ ] **Step 2: Create `lib/state/auth_store.dart`**

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthStoreBase extends ChangeNotifier {
  bool get isSignedIn;
  String? get userEmail;
}

class AuthStore extends AuthStoreBase {
  AuthStore(GoTrueClient auth) {
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
```

- [ ] **Step 3: Verify analysis passes**

Run from `.worktrees/kenko-fresh-impl/`:
```bash
flutter analyze lib/data/auth_repository.dart lib/state/auth_store.dart
```
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/data/auth_repository.dart lib/state/auth_store.dart
git commit -m "feat: add AuthRepository and AuthStore"
```

---

## Task 2: AuthSheet Widget

**Files:**
- Create: `lib/widgets/auth_sheet.dart`

- [ ] **Step 1: Create `lib/widgets/auth_sheet.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:kenko_shop/app/theme.dart';
import 'package:kenko_shop/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _AuthMode { signIn, signUp }

class AuthSheet extends StatefulWidget {
  const AuthSheet({
    required this.authRepository,
    this.startInSignUpMode = false,
    super.key,
  });

  final AuthRepository authRepository;
  final bool startInSignUpMode;

  @override
  State<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<AuthSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late _AuthMode _mode;
  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _mode = widget.startInSignUpMode ? _AuthMode.signUp : _AuthMode.signIn;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      if (_mode == _AuthMode.signIn) {
        await widget.authRepository.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await widget.authRepository.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSignIn = _mode == _AuthMode.signIn;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: KenkoColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              24,
              18,
              24,
              24 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: KenkoColors.rawBlack.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _ModeButton(
                      key: const Key('auth-mode-signin'),
                      label: 'Sign in',
                      isActive: isSignIn,
                      onTap: () => setState(() => _mode = _AuthMode.signIn),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ModeButton(
                      key: const Key('auth-mode-signup'),
                      label: 'Create account',
                      isActive: !isSignIn,
                      onTap: () => setState(() => _mode = _AuthMode.signUp),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      key: const Key('auth-email-field'),
                      controller: _emailController,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.emailAddress,
                      style: _inputTextStyle,
                      cursorColor: KenkoColors.moss,
                      decoration: _inputDecoration('Email'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Email is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('auth-password-field'),
                      controller: _passwordController,
                      enabled: !_isLoading,
                      obscureText: true,
                      style: _inputTextStyle,
                      cursorColor: KenkoColors.moss,
                      decoration: _inputDecoration('Password'),
                      validator: (v) =>
                          v == null || v.length < 6 ? 'At least 6 characters' : null,
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorText!,
                        key: const Key('auth-error-text'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('auth-submit-button'),
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isSignIn ? 'Sign in' : 'Create account'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static const _inputTextStyle = TextStyle(
    color: KenkoColors.rawBlack,
    fontWeight: FontWeight.w800,
  );

  InputDecoration _inputDecoration(String label) {
    const radius = BorderRadius.all(Radius.circular(16));
    final idleBorder = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(
        color: KenkoColors.rawBlack.withValues(alpha: 0.14),
        width: 1.4,
      ),
    );
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: KenkoColors.rawBlack.withValues(alpha: 0.62),
        fontWeight: FontWeight.w800,
      ),
      floatingLabelStyle: const TextStyle(
        color: KenkoColors.moss,
        fontWeight: FontWeight.w900,
      ),
      filled: true,
      fillColor: const Color(0xFFFFFAF0),
      enabledBorder: idleBorder,
      disabledBorder: idleBorder,
      focusedBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: KenkoColors.moss, width: 1.8),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: KenkoColors.flash, width: 1.6),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: KenkoColors.flash, width: 1.8),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.isActive,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? KenkoColors.moss : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? KenkoColors.moss
                : KenkoColors.rawBlack.withValues(alpha: 0.18),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? KenkoColors.cream : KenkoColors.rawBlack,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify analysis**

```bash
flutter analyze lib/widgets/auth_sheet.dart
```
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/auth_sheet.dart
git commit -m "feat: add AuthSheet email/password bottom sheet"
```

---

## Task 3: BrowseScreen + Tests

**Files:**
- Create: `lib/screens/browse_screen.dart`
- Create: `test/screens/browse_screen_test.dart`

- [ ] **Step 1: Write the failing tests first**

Create `test/screens/browse_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kenko_shop/data/sample_products.dart';
import 'package:kenko_shop/screens/browse_screen.dart';
import 'package:kenko_shop/state/cart_store.dart';

Future<void> pumpBrowseScreen(WidgetTester tester, CartStore cartStore) async {
  await tester.pumpWidget(
    MaterialApp(home: BrowseScreen(cartStore: cartStore)),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows all products when no filter is active', (tester) async {
    final cartStore = CartStore();
    addTearDown(cartStore.dispose);
    await pumpBrowseScreen(tester, cartStore);

    for (final product in sampleProducts) {
      expect(find.text(product.name), findsOneWidget);
    }
  });

  testWidgets('category chip hides products from other categories', (
    tester,
  ) async {
    final cartStore = CartStore();
    addTearDown(cartStore.dispose);
    await pumpBrowseScreen(tester, cartStore);

    await tester.tap(find.byKey(const Key('browse-chip-Greens')));
    await tester.pump();

    expect(find.text('Da Lat Baby Bok Choy'), findsOneWidget);
    expect(find.text('Red Dragon Fruit'), findsNothing);
    expect(find.text('Golden Soil Carrot'), findsNothing);
  });

  testWidgets('All chip restores full product list after filtering', (
    tester,
  ) async {
    final cartStore = CartStore();
    addTearDown(cartStore.dispose);
    await pumpBrowseScreen(tester, cartStore);

    await tester.tap(find.byKey(const Key('browse-chip-Greens')));
    await tester.pump();
    expect(find.text('Red Dragon Fruit'), findsNothing);

    await tester.tap(find.byKey(const Key('browse-chip-All')));
    await tester.pump();
    expect(find.text('Red Dragon Fruit'), findsOneWidget);
  });

  testWidgets('search filters products by name', (tester) async {
    final cartStore = CartStore();
    addTearDown(cartStore.dispose);
    await pumpBrowseScreen(tester, cartStore);

    await tester.enterText(find.byKey(const Key('browse-search-field')), 'carrot');
    await tester.pump();

    expect(find.text('Golden Soil Carrot'), findsOneWidget);
    expect(find.text('Da Lat Baby Bok Choy'), findsNothing);
  });

  testWidgets('add button increments cart store', (tester) async {
    final cartStore = CartStore();
    addTearDown(cartStore.dispose);
    await pumpBrowseScreen(tester, cartStore);

    expect(cartStore.totalQuantity, 0);
    await tester.tap(find.byKey(Key('browse-add-${sampleProducts.first.id}')));
    await tester.pump();

    expect(cartStore.totalQuantity, 1);
  });
}
```

- [ ] **Step 2: Run tests — expect failure**

```bash
flutter test test/screens/browse_screen_test.dart
```
Expected: FAIL — `browse_screen.dart` not found.

- [ ] **Step 3: Create `lib/screens/browse_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:kenko_shop/app/theme.dart';
import 'package:kenko_shop/data/sample_products.dart';
import 'package:kenko_shop/models/product.dart';
import 'package:kenko_shop/state/cart_store.dart';
import 'package:kenko_shop/widgets/product_detail_sheet.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({required this.cartStore, super.key});

  final CartStore cartStore;

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedCategory;

  static final _allCategories = List<String>.unmodifiable(
    sampleProducts.map((p) => p.category).toSet().toList()..sort(),
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> get _filtered {
    final q = _query.toLowerCase();
    return sampleProducts.where((p) {
      final matchCat =
          _selectedCategory == null || p.category == _selectedCategory;
      final matchQ = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
      return matchCat && matchQ;
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [KenkoColors.rawBlack, Color(0xFF0D1F10), KenkoColors.rawBlack],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                key: const Key('browse-search-field'),
                controller: _searchController,
                style: const TextStyle(
                  color: KenkoColors.cream,
                  fontWeight: FontWeight.w700,
                ),
                cursorColor: KenkoColors.harvest,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(
                    color: KenkoColors.cream.withValues(alpha: 0.42),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: KenkoColors.cream.withValues(alpha: 0.6),
                  ),
                  filled: true,
                  fillColor: KenkoColors.rawBlack.withValues(alpha: 0.6),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: KenkoColors.cream.withValues(alpha: 0.18),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: KenkoColors.harvest,
                      width: 1.6,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CategoryChip(
                    chipKey: const Key('browse-chip-All'),
                    label: 'All',
                    isSelected: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                  ..._allCategories.map(
                    (cat) => _CategoryChip(
                      chipKey: Key('browse-chip-$cat'),
                      label: cat,
                      isSelected: _selectedCategory == cat,
                      onTap: () => setState(() => _selectedCategory = cat),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final product = _filtered[index];
                  return _ProductBrowseCard(
                    product: product,
                    onAdd: () => widget.cartStore.add(product),
                    onTap: () => _openDetail(product),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(Product product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductDetailSheet(
        product: product,
        onAdd: () => widget.cartStore.add(product),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.chipKey,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final Key chipKey;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        key: chipKey,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? KenkoColors.moss : KenkoColors.rawBlack,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? KenkoColors.moss
                  : KenkoColors.cream.withValues(alpha: 0.22),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? KenkoColors.cream : KenkoColors.cream.withValues(alpha: 0.72),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductBrowseCard extends StatelessWidget {
  const _ProductBrowseCard({
    required this.product,
    required this.onAdd,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onAdd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              product.palette.background,
              Color.lerp(
                product.palette.background,
                product.palette.primary,
                0.28,
              )!,
            ],
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.isLimitedDrop) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: KenkoColors.flash,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'DROP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: product.palette.secondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.price.toStringAsFixed(0)} VND',
                    style: TextStyle(
                      color: product.palette.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.unit,
                    style: TextStyle(
                      color: product.palette.secondary.withValues(alpha: 0.62),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: GestureDetector(
                key: Key('browse-add-${product.id}'),
                onTap: onAdd,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: KenkoColors.harvest,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: KenkoColors.rawBlack,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests — expect pass**

```bash
flutter test test/screens/browse_screen_test.dart
```
Expected: All 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/browse_screen.dart test/screens/browse_screen_test.dart
git commit -m "feat: add BrowseScreen with search, filter chips, and product grid"
```

---

## Task 4: YouScreen + Tests

**Files:**
- Create: `lib/screens/you_screen.dart`
- Create: `test/screens/you_screen_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/screens/you_screen_test.dart`:

```dart
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
```

- [ ] **Step 2: Run tests — expect failure**

```bash
flutter test test/screens/you_screen_test.dart
```
Expected: FAIL — `you_screen.dart` not found.

- [ ] **Step 3: Create `lib/screens/you_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:kenko_shop/app/theme.dart';
import 'package:kenko_shop/state/auth_store.dart';

class YouScreen extends StatelessWidget {
  const YouScreen({
    required this.authStore,
    required this.onSignIn,
    required this.onSignOut,
    super.key,
  });

  final AuthStoreBase authStore;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: authStore,
      builder: (context, _) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                KenkoColors.rawBlack,
                Color(0xFF173421),
                KenkoColors.rawBlack,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 110),
                child: authStore.isSignedIn
                    ? _SignedInView(authStore: authStore, onSignOut: onSignOut)
                    : _SignedOutView(onSignIn: onSignIn),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SignedOutView extends StatelessWidget {
  const _SignedOutView({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.person_rounded, color: KenkoColors.harvest, size: 38),
        const SizedBox(height: 18),
        Text(
          'Track your orders',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: KenkoColors.cream,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Sign in to see order status and speed up checkout.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: KenkoColors.cream.withValues(alpha: 0.72),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const Key('you-sign-in-button'),
          onPressed: onSignIn,
          icon: const Icon(Icons.login_rounded),
          label: const Text('Sign in'),
        ),
      ],
    );
  }
}

class _SignedInView extends StatelessWidget {
  const _SignedInView({required this.authStore, required this.onSignOut});

  final AuthStoreBase authStore;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final email = authStore.userEmail ?? '';
    final initials = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: KenkoColors.moss,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                color: KenkoColors.cream,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          email,
          key: const Key('you-email-text'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: KenkoColors.cream,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          key: const Key('you-sign-out-button'),
          onPressed: onSignOut,
          style: OutlinedButton.styleFrom(
            foregroundColor: KenkoColors.cream,
            side: BorderSide(
              color: KenkoColors.cream.withValues(alpha: 0.4),
            ),
          ),
          child: const Text('Sign out'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run tests — expect pass**

```bash
flutter test test/screens/you_screen_test.dart
```
Expected: All 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/you_screen.dart test/screens/you_screen_test.dart
git commit -m "feat: add YouScreen with signed-in/out states"
```

---

## Task 5: Wire KenkoApp

**Files:**
- Modify: `lib/app/kenko_app.dart`

- [ ] **Step 1: Update `lib/app/kenko_app.dart`**

Replace the entire file content:

```dart
import 'package:flutter/material.dart';
import 'package:kenko_shop/app/theme.dart';
import 'package:kenko_shop/config/app_config.dart';
import 'package:kenko_shop/data/auth_repository.dart';
import 'package:kenko_shop/data/order_repository.dart';
import 'package:kenko_shop/data/product_repository.dart';
import 'package:kenko_shop/screens/fresh_feed_screen.dart';
import 'package:kenko_shop/state/auth_store.dart';
import 'package:kenko_shop/state/cart_store.dart';
import 'package:kenko_shop/state/product_feed_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KenkoApp extends StatefulWidget {
  const KenkoApp({required this.config, super.key});

  final AppConfig config;

  @override
  State<KenkoApp> createState() => _KenkoAppState();
}

class _KenkoAppState extends State<KenkoApp> {
  late final CartStore _cartStore;
  late final OrderRepository? _orderRepository;
  late final ProductRepository _productRepository;
  late final ProductFeedStore _productFeedStore;
  late final AuthStore _authStore;
  late final AuthRepository _authRepository;

  @override
  void initState() {
    super.initState();
    _cartStore = CartStore();
    _productRepository = widget.config.hasSupabaseConfig
        ? ProductRepository.remote(Supabase.instance.client)
        : ProductRepository.offline();
    _orderRepository = widget.config.hasSupabaseConfig
        ? OrderRepository(Supabase.instance.client)
        : null;
    _productFeedStore = ProductFeedStore(_productRepository.fetchProducts);
    _authStore = AuthStore(Supabase.instance.client.auth);
    _authRepository = AuthRepository(Supabase.instance.client.auth);
  }

  @override
  void dispose() {
    _productFeedStore.dispose();
    _cartStore.dispose();
    _authStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kenko Fresh',
      theme: buildKenkoTheme(),
      home: FreshFeedScreen(
        productFeedStore: _productFeedStore,
        cartStore: _cartStore,
        guestCheckoutSubmitter: _orderRepository?.createGuestOrder,
        authStore: _authStore,
        authRepository: _authRepository,
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/app/kenko_app.dart
```
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/app/kenko_app.dart
git commit -m "feat: wire AuthStore and AuthRepository into KenkoApp"
```

---

## Task 6: Wire FreshFeedScreen

**Files:**
- Modify: `lib/screens/fresh_feed_screen.dart`

- [ ] **Step 1: Update imports and constructor in `lib/screens/fresh_feed_screen.dart`**

Add these imports after the existing ones (after `product_scene.dart` import):

```dart
import 'package:kenko_shop/data/auth_repository.dart';
import 'package:kenko_shop/screens/browse_screen.dart';
import 'package:kenko_shop/screens/you_screen.dart';
import 'package:kenko_shop/state/auth_store.dart';
import 'package:kenko_shop/widgets/auth_sheet.dart';
```

- [ ] **Step 2: Add optional auth fields to `FreshFeedScreen`**

Replace the `FreshFeedScreen` class declaration (lines 13–27):

```dart
class FreshFeedScreen extends StatefulWidget {
  const FreshFeedScreen({
    required this.productFeedStore,
    required this.cartStore,
    this.guestCheckoutSubmitter,
    this.authStore,
    this.authRepository,
    super.key,
  });

  final ProductFeedStore productFeedStore;
  final CartStore cartStore;
  final GuestCheckoutSubmitter? guestCheckoutSubmitter;
  final AuthStoreBase? authStore;
  final AuthRepository? authRepository;

  @override
  State<FreshFeedScreen> createState() => _FreshFeedScreenState();
}
```

- [ ] **Step 3: Update `_buildSelectedBody` to wire Browse and You tabs**

Replace the `_buildSelectedBody` method:

```dart
Widget _buildSelectedBody(
  ProductFeedStore productFeedStore,
  List<Product> products,
) {
  return switch (_selectedTab) {
    0 => _buildFeed(productFeedStore, products),
    1 => BrowseScreen(cartStore: widget.cartStore),
    3 => _buildYouTab(),
    _ => _buildFeed(productFeedStore, products),
  };
}

Widget _buildYouTab() {
  final authStore = widget.authStore;
  final authRepository = widget.authRepository;
  if (authStore == null || authRepository == null) {
    return const _PlaceholderTab(
      key: Key('you-placeholder'),
      icon: Icons.person_rounded,
      title: 'Your Kenko',
      message: 'Saved addresses and optional sign-in can come later.',
    );
  }
  return YouScreen(
    authStore: authStore,
    onSignIn: () => _openAuthSheet(authRepository),
    onSignOut: () => unawaited(authRepository.signOut()),
  );
}

void _openAuthSheet(AuthRepository authRepository) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AuthSheet(authRepository: authRepository),
  );
}
```

- [ ] **Step 4: Pass `authRepository` to `CartSheet` in `_openCart`**

Replace the `_openCart` method:

```dart
Future<void> _openCart() {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CartSheet(
      cartStore: widget.cartStore,
      guestCheckoutSubmitter: widget.guestCheckoutSubmitter,
      authRepository: widget.authRepository,
    ),
  );
}
```

- [ ] **Step 5: Analyze**

```bash
flutter analyze lib/screens/fresh_feed_screen.dart
```
Expected: `No issues found!`

- [ ] **Step 6: Run all existing tests to confirm no regressions**

```bash
flutter test test/screens/fresh_feed_screen_test.dart
```
Expected: All tests pass (new optional params don't affect existing behavior).

- [ ] **Step 7: Commit**

```bash
git add lib/screens/fresh_feed_screen.dart
git commit -m "feat: wire Browse and You tabs in FreshFeedScreen"
```

---

## Task 7: Wire CartSheet Auth Buttons

**Files:**
- Modify: `lib/widgets/cart_sheet.dart`

- [ ] **Step 1: Add `authRepository` field and import to `CartSheet`**

Add import at top of `lib/widgets/cart_sheet.dart` (after existing imports):

```dart
import 'package:kenko_shop/data/auth_repository.dart';
import 'package:kenko_shop/widgets/auth_sheet.dart';
```

Replace `CartSheet` class declaration (the `StatefulWidget` part, lines 7–24):

```dart
class CartSheet extends StatefulWidget {
  const CartSheet({
    required this.cartStore,
    this.guestCheckoutSubmitter,
    this.authRepository,
    super.key,
  });

  final CartStore cartStore;
  final GuestCheckoutSubmitter? guestCheckoutSubmitter;
  final AuthRepository? authRepository;

  @override
  State<CartSheet> createState() => _CartSheetState();
}
```

- [ ] **Step 2: Replace `_showAccountComingSoon` with auth-aware methods**

In `_CartSheetState`, replace the `_showAccountComingSoon` method with these two methods:

```dart
void _openAuthSheet({bool startInSignUpMode = false}) {
  final repo = widget.authRepository;
  if (repo == null) {
    _showAuthComingSoon();
    return;
  }
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AuthSheet(
      authRepository: repo,
      startInSignUpMode: startInSignUpMode,
    ),
  );
}

void _showAuthComingSoon() {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Account sign-in coming soon.')),
  );
}
```

- [ ] **Step 3: Update `_AccountPrompt` to accept separate email and other-auth callbacks**

Replace the `_AccountPrompt` class:

```dart
class _AccountPrompt extends StatelessWidget {
  const _AccountPrompt({
    required this.onContinueAsGuest,
    required this.onEmailAuth,
    required this.onOtherAuth,
  });

  final VoidCallback onContinueAsGuest;
  final VoidCallback onEmailAuth;
  final VoidCallback onOtherAuth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: KenkoColors.rawBlack,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: KenkoColors.harvest,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user_outlined,
                        color: KenkoColors.rawBlack,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sign in for faster checkout',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: KenkoColors.cream,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Track orders, speed up verification, and keep checkout details saved.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: KenkoColors.cream.withValues(alpha: 0.76),
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _AuthButton(
          icon: Icons.phone_iphone_rounded,
          label: 'Continue with phone',
          onTap: onOtherAuth,
        ),
        const SizedBox(height: 8),
        _AuthButton(
          icon: Icons.alternate_email_rounded,
          label: 'Continue with email',
          onTap: onEmailAuth,
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          key: const Key('continue-as-guest'),
          onPressed: onContinueAsGuest,
          style: OutlinedButton.styleFrom(
            foregroundColor: KenkoColors.rawBlack,
            side: BorderSide(
              color: KenkoColors.rawBlack.withValues(alpha: 0.28),
            ),
          ),
          child: const Text('Continue as guest'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SocialAuthButton(label: 'Google', onTap: onOtherAuth),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SocialAuthButton(
                label: 'Facebook',
                onTap: onOtherAuth,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SocialAuthButton(
                label: 'Instagram',
                onTap: onOtherAuth,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Update the usage of `_AccountPrompt` in `CartSheet.build`**

Find the existing `_AccountPrompt(...)` call inside `build` (inside the `else if (_step == _CartSheetStep.accountGate)` branch) and replace it:

```dart
_AccountPrompt(
  onContinueAsGuest: () {
    setState(() {
      _step = _CartSheetStep.guestForm;
    });
  },
  onEmailAuth: () => _openAuthSheet(),
  onOtherAuth: _showAuthComingSoon,
),
```

- [ ] **Step 5: Update `_OrderConfirmation` call — wire "Create account to track"**

Find the `_OrderConfirmation(...)` call in `CartSheet.build` and replace:

```dart
_OrderConfirmation(
  result: _orderResult!,
  onCreateAccount: () => _openAuthSheet(startInSignUpMode: true),
  onContinueShopping: () => Navigator.of(context).pop(),
),
```

- [ ] **Step 6: Analyze**

```bash
flutter analyze lib/widgets/cart_sheet.dart
```
Expected: `No issues found!`

- [ ] **Step 7: Run all tests**

```bash
flutter test
```
Expected: All tests pass, including existing `fresh_feed_screen_test.dart` tests that exercise the account gate flow.

- [ ] **Step 8: Commit**

```bash
git add lib/widgets/cart_sheet.dart
git commit -m "feat: wire email auth and create-account buttons in CartSheet"
```

---

## Task 8: Final Verification

- [ ] **Step 1: Full analyze**

```bash
flutter analyze
```
Expected: `No issues found!`

- [ ] **Step 2: Full test suite**

```bash
flutter test --reporter=expanded
```
Expected: All tests pass. Zero failures.

- [ ] **Step 3: Debug build check**

```bash
flutter build apk --debug 2>&1 | tail -5
```
Expected: `Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 4: Commit final verification**

```bash
git commit --allow-empty -m "chore: verify browse + auth implementation complete"
```
