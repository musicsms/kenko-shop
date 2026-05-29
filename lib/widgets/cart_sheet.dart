import 'package:flutter/material.dart';
import 'package:kenko_shop/app/theme.dart';
import 'package:kenko_shop/data/auth_repository.dart';
import 'package:kenko_shop/models/guest_order.dart';
import 'package:kenko_shop/models/order_result.dart';
import 'package:kenko_shop/state/cart_store.dart';
import 'package:kenko_shop/widgets/auth_sheet.dart';

typedef GuestCheckoutSubmitter =
    Future<OrderResult> Function(GuestOrderRequest request);

enum _CartSheetStep { cart, accountGate, guestForm }

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

class _CartSheetState extends State<CartSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  _CartSheetStep _step = _CartSheetStep.cart;
  bool _isSubmitting = false;
  OrderResult? _orderResult;
  String? _submitError;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.cartStore,
      builder: (context, child) {
        return DraggableScrollableSheet(
          key: ValueKey('cart-sheet-$_step-${_orderResult != null}'),
          expand: false,
          initialChildSize: _initialChildSize,
          minChildSize: 0.28,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return DecoratedBox(
              decoration: const BoxDecoration(
                color: KenkoColors.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ListView(
                key: const Key('cart-sheet-scroll'),
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                  24,
                  18,
                  24,
                  84 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                children: [
                  const Center(child: _SheetHandle()),
                  Text(
                    'Your fresh cart',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: KenkoColors.rawBlack,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_orderResult != null)
                    _OrderConfirmation(
                      result: _orderResult!,
                      onCreateAccount: () => _openAuthSheet(startInSignUpMode: true),
                      onContinueShopping: () => Navigator.of(context).pop(),
                    )
                  else if (widget.cartStore.checkoutComplete)
                    const _MutedText(
                      'Demo order packed. No payment was processed.',
                    )
                  else if (widget.cartStore.isEmpty)
                    Text(
                      'Your basket is ready for the next fresh drop.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        color: KenkoColors.rawBlack.withValues(alpha: 0.72),
                      ),
                    )
                  else if (_step == _CartSheetStep.accountGate)
                    _AccountPrompt(
                      onContinueAsGuest: () {
                        setState(() {
                          _step = _CartSheetStep.guestForm;
                        });
                      },
                      onEmailAuth: () => _openAuthSheet(),
                      onOtherAuth: _showAuthComingSoon,
                    )
                  else ...[
                    if (_step == _CartSheetStep.guestForm &&
                        widget.guestCheckoutSubmitter != null) ...[
                      _CheckoutSummary(cartStore: widget.cartStore),
                      const SizedBox(height: 16),
                      _GuestCheckoutForm(
                        formKey: _formKey,
                        nameController: _nameController,
                        phoneController: _phoneController,
                        addressController: _addressController,
                        noteController: _noteController,
                        isSubmitting: _isSubmitting,
                        errorText: _submitError,
                        onSubmit: _submitGuestOrder,
                      ),
                    ] else ...[
                      for (final item in widget.cartStore.items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: KenkoColors.rawBlack,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.product.price.toStringAsFixed(0)} VND / ${item.product.unit}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: KenkoColors.rawBlack
                                                .withValues(alpha: 0.62),
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Decrease ${item.product.name}',
                                color: KenkoColors.rawBlack,
                                onPressed: () =>
                                    widget.cartStore.decrement(item.product.id),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '${item.quantity}',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: KenkoColors.rawBlack,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Increase ${item.product.name}',
                                color: KenkoColors.rawBlack,
                                onPressed: () =>
                                    widget.cartStore.increment(item.product.id),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        ),
                      const Divider(color: KenkoColors.rawBlack),
                      const SizedBox(height: 10),
                      _SubtotalRow(cartStore: widget.cartStore),
                      const SizedBox(height: 18),
                      if (widget.guestCheckoutSubmitter == null)
                        FilledButton(
                          onPressed: widget.cartStore.checkoutDemo,
                          child: const Text('Checkout Demo'),
                        )
                      else
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _step = _CartSheetStep.accountGate;
                              _submitError = null;
                            });
                          },
                          child: const Text('Checkout'),
                        ),
                    ],
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  double get _initialChildSize {
    if (_orderResult != null) {
      return 0.86;
    }

    return switch (_step) {
      _CartSheetStep.accountGate => 0.9,
      _CartSheetStep.guestForm => 0.95,
      _CartSheetStep.cart => 0.58,
    };
  }

  Future<void> _submitGuestOrder() async {
    final submitter = widget.guestCheckoutSubmitter;
    if (submitter == null || _isSubmitting) {
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final request = GuestOrderRequest(
      customerName: _nameController.text,
      customerPhone: _phoneController.text,
      deliveryAddress: _addressController.text,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text,
      items: widget.cartStore.items
          .map(
            (item) => GuestOrderItem(
              productSlug: item.product.id,
              quantity: item.quantity,
            ),
          )
          .toList(growable: false),
    );

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final result = await submitter(request);
      if (!mounted) {
        return;
      }
      setState(() {
        _orderResult = result;
        _isSubmitting = false;
      });
      widget.cartStore.checkoutDemo();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _submitError = 'Could not place order. Please try again.';
      });
    }
  }

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
}

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

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _SocialAuthButton extends StatelessWidget {
  const _SocialAuthButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: KenkoColors.rawBlack,
        side: BorderSide(color: KenkoColors.rawBlack.withValues(alpha: 0.2)),
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _CheckoutSummary extends StatelessWidget {
  const _CheckoutSummary({required this.cartStore});

  final CartStore cartStore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MutedText('${cartStore.totalQuantity} item fresh order'),
        const SizedBox(height: 10),
        _SubtotalRow(cartStore: cartStore),
      ],
    );
  }
}

class _SubtotalRow extends StatelessWidget {
  const _SubtotalRow({required this.cartStore});

  final CartStore cartStore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Subtotal',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: KenkoColors.rawBlack,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Flexible(
          child: Text(
            '${cartStore.subtotal.toStringAsFixed(0)} VND',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: KenkoColors.rawBlack,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _GuestCheckoutForm extends StatelessWidget {
  const _GuestCheckoutForm({
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.noteController,
    required this.isSubmitting,
    required this.onSubmit,
    this.errorText,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController noteController;
  final bool isSubmitting;
  final String? errorText;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Guest checkout',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: KenkoColors.rawBlack,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          const _GuestPriorityNotice(),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('guest-name-field'),
            controller: nameController,
            enabled: !isSubmitting,
            style: _inputTextStyle,
            cursorColor: KenkoColors.moss,
            decoration: _inputDecoration('Name'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Name is required'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('guest-phone-field'),
            controller: phoneController,
            enabled: !isSubmitting,
            keyboardType: TextInputType.phone,
            style: _inputTextStyle,
            cursorColor: KenkoColors.moss,
            decoration: _inputDecoration('Phone'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Phone is required'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('guest-address-field'),
            controller: addressController,
            enabled: !isSubmitting,
            style: _inputTextStyle,
            cursorColor: KenkoColors.moss,
            decoration: _inputDecoration('Address'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Address is required'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('guest-note-field'),
            controller: noteController,
            enabled: !isSubmitting,
            style: _inputTextStyle,
            cursorColor: KenkoColors.moss,
            decoration: _inputDecoration('Note'),
            minLines: 1,
            maxLines: 3,
          ),
          if (errorText != null) ...[
            const SizedBox(height: 12),
            Text(
              errorText!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('guest-submit-order'),
            onPressed: isSubmitting ? null : onSubmit,
            child: isSubmitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit order'),
          ),
        ],
      ),
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

class _GuestPriorityNotice extends StatelessWidget {
  const _GuestPriorityNotice();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KenkoColors.harvest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KenkoColors.harvest.withValues(alpha: 0.42)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: KenkoColors.soil,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Guest orders need phone verification before packing and may be processed after signed-in customer orders.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: KenkoColors.rawBlack.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderConfirmation extends StatelessWidget {
  const _OrderConfirmation({
    required this.result,
    required this.onCreateAccount,
    required this.onContinueShopping,
  });

  final OrderResult result;
  final VoidCallback onCreateAccount;
  final VoidCallback onContinueShopping;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: KenkoColors.moss,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: KenkoColors.cream,
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Order received',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: KenkoColors.rawBlack,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFAF0),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: KenkoColors.rawBlack.withValues(alpha: 0.12),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Text(
                  'Order ${result.orderCode} confirmed',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: KenkoColors.rawBlack,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                _MutedText(
                  'Status: ${result.status}\nTotal: ${result.total.toStringAsFixed(0)} VND',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _GuestPriorityNotice(),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onCreateAccount,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Create account to track'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          key: const Key('continue-shopping'),
          onPressed: onContinueShopping,
          style: OutlinedButton.styleFrom(
            foregroundColor: KenkoColors.rawBlack,
            side: BorderSide(
              color: KenkoColors.rawBlack.withValues(alpha: 0.28),
            ),
          ),
          child: const Text('Continue shopping'),
        ),
      ],
    );
  }
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontSize: 15,
        color: KenkoColors.rawBlack.withValues(alpha: 0.72),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 5,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: KenkoColors.rawBlack.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
