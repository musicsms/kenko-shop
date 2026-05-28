import 'package:flutter/material.dart';
import 'package:kenko_shop/app/theme.dart';
import 'package:kenko_shop/models/guest_order.dart';
import 'package:kenko_shop/models/order_result.dart';
import 'package:kenko_shop/state/cart_store.dart';

typedef GuestCheckoutSubmitter =
    Future<OrderResult> Function(GuestOrderRequest request);

class CartSheet extends StatefulWidget {
  const CartSheet({
    required this.cartStore,
    this.guestCheckoutSubmitter,
    super.key,
  });

  final CartStore cartStore;
  final GuestCheckoutSubmitter? guestCheckoutSubmitter;

  @override
  State<CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<CartSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  bool _showGuestForm = false;
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
          key: ValueKey(_showGuestForm),
          expand: false,
          initialChildSize: _showGuestForm ? 0.88 : 0.58,
          minChildSize: 0.28,
          maxChildSize: 0.95,
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
                  28 + MediaQuery.viewPaddingOf(context).bottom,
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
                    _OrderConfirmation(result: _orderResult!)
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
                  else ...[
                    if (_showGuestForm &&
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
                              _showGuestForm = true;
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

class _OrderConfirmation extends StatelessWidget {
  const _OrderConfirmation({required this.result});

  final OrderResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order ${result.orderCode} confirmed',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: KenkoColors.rawBlack,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        _MutedText(
          'Status: ${result.status}\nTotal: ${result.total.toStringAsFixed(0)} VND',
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
