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
