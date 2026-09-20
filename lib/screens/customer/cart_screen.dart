import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';
import '../../services/api_service.dart';
import '../../services/providers.dart';
import '../../models/models.dart';
import 'package:url_launcher/url_launcher_string.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String _selectedProvider = 'paystack';
  bool _isLoading = false;
  Timer? _paymentVerificationTimer;
  bool _hasNavigatedToTracking = false;
  bool _isDelivery = true;

  final List<PaymentProviderOption> _providers = const [
    PaymentProviderOption(value: 'paystack', label: 'Paystack'),
    PaymentProviderOption(value: 'mtn_momo', label: 'MTN Mobile Money'),
  ];

  void _startPaymentVerification(
      {required String reference, required Order order}) {
    if (_paymentVerificationTimer != null) return;

    _hasNavigatedToTracking = false;
    _paymentVerificationTimer =
        Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted || _hasNavigatedToTracking) return;

      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!auth.isLoggedIn || auth.token == null) return;

      try {
        final verification = await ApiService.verifyPayment(
          token: auth.token!,
          reference: reference,
        );

        final status = verification['status']?.toString().toLowerCase();
        if (status == 'success') {
          _paymentVerificationTimer?.cancel();
          _paymentVerificationTimer = null;
          if (!mounted) return;

          setState(() => _hasNavigatedToTracking = true);
          context.go('/order-tracking/${order.id}', extra: order);
        }
      } catch (_) {
        // Keep polling until the backend confirms payment success.
      }
    });

    Future.delayed(const Duration(minutes: 2), () {
      if (!mounted || _hasNavigatedToTracking) return;
      _paymentVerificationTimer?.cancel();
      _paymentVerificationTimer = null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Payment verification timed out. Please check your order status.')),
      );
    });
  }

  Future<void> _placeOrderAndInitializePayment() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final cart = Provider.of<CartProvider>(context, listen: false);

    if (!auth.isLoggedIn) {
      context.go(Uri(
        path: '/login',
        queryParameters: {'returnTo': Uri(path: '/cart').toString()},
      ).toString());
      return;
    }

    if (cart.restaurantId == null || cart.orderPayload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: AppTheme.danger,
        content: Text('Your cart is empty. Please add items before checkout.',
            style: TextStyle(color: Colors.white)),
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final order = await ApiService.placeOrder(
        token: auth.token!,
        restaurantId: cart.restaurantId!,
        items: cart.orderPayload,
        fulfillmentMethod: _isDelivery ? 'delivery' : 'pickup',
      );

      final init = await ApiService.initializePayment(
        token: auth.token!,
        orderId: order.id,
        provider: _selectedProvider,
      );

      if (!mounted) return;

      if (_selectedProvider == 'paystack') {
        final authorizationUrl = init['authorization_url'] as String?;
        final reference = init['reference'] as String?;

        if (authorizationUrl == null || reference == null) {
          throw Exception('Invalid payment initialization response.');
        }

        await launchUrlString(authorizationUrl,
            mode: LaunchMode.externalApplication);

        if (!mounted) return;
        _startPaymentVerification(reference: reference, order: order);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Opening checkout for reference $reference...'),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'MTN Mobile Money flow is being prepared. Please try again later.'),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      debugPrint(
          'Payment initialization error: $errorMsg | Provider: $_selectedProvider');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppTheme.danger,
        content: Text(errorMsg, style: const TextStyle(color: Colors.white)),
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: const EmptyState(
          icon: Icons.shopping_bag_outlined,
          title: 'Your cart is empty',
          subtitle: 'Add items from a restaurant to get started.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(cart.restaurantName ?? 'Cart'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Cart items ─────────────────────────────────────────
          const Text('Your order', style: AppText.heading),
          const SizedBox(height: 14),
          ...cart.items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.menuItem.name, style: AppText.title),
                          const SizedBox(height: 4),
                          Text(item.displaySubtotal,
                              style: AppText.label
                                  .copyWith(color: AppTheme.accent)),
                        ],
                      ),
                    ),
                    // Qty controls
                    Row(
                      children: [
                        _qtyBtn(
                            Icons.remove,
                            () => Provider.of<CartProvider>(context,
                                    listen: false)
                                .decreaseItem(item.menuItem.id)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text('${item.quantity}', style: AppText.title),
                        ),
                        _qtyBtn(
                            Icons.add,
                            () => Provider.of<CartProvider>(context,
                                    listen: false)
                                .addItem(item.menuItem, cart.restaurantId!,
                                    cart.restaurantName!)),
                      ],
                    ),
                  ],
                ),
              )),

          // ── Summary ────────────────────────────────────────────
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme
                          .darkBorder, // Blends perfectly with your theme palette!
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isDelivery = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isDelivery
                                    ? AppTheme.accent
                                    : Colors
                                        .transparent, // Uses your theme color highlight
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '🛵 Delivery',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _isDelivery ? Colors.white : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isDelivery = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isDelivery
                                    ? AppTheme.accent
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '🛍️ Pickup',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      !_isDelivery ? Colors.white : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _summaryRow('Subtotal', cart.displayTotal),
                const SizedBox(height: 8),
                _summaryRow('Delivery fee', 'Free'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: AppTheme.darkBorder),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: AppText.title),
                    Text(cart.displayTotal,
                        style: AppText.title.copyWith(color: AppTheme.accent)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text('Payment Method', style: AppText.heading),
          const SizedBox(height: 14),
          Row(
            children: _providers.map((provider) {
              final active = _selectedProvider == provider.value;
              return Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _selectedProvider = provider.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(
                        right: provider == _providers.last ? 0 : 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: active ? AppTheme.accentDim : AppTheme.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active ? AppTheme.accent : AppTheme.darkBorder,
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(provider.label,
                          style: TextStyle(
                            color:
                                active ? AppTheme.accent : AppTheme.textSecond,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w400,
                            fontSize: 12,
                          )),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          if (!auth.isLoggedIn)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'You need to sign in before placing an order.',
                style: TextStyle(color: AppTheme.warning, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          PrimaryButton(
            label: auth.isLoggedIn
                ? 'Place order · ${cart.displayTotal}'
                : 'Sign in to order',
            isLoading: _isLoading,
            onPressed: _placeOrderAndInitializePayment,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.darkBorder),
        ),
        child: Icon(icon, size: 16, color: AppTheme.textPrimary),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.body),
        Text(value, style: AppText.label),
      ],
    );
  }
}
