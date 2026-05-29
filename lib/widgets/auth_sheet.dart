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
