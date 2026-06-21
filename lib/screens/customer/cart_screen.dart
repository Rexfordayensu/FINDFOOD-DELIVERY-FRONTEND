import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';
import '../../services/api_service.dart';
import '../../services/providers.dart';
import '../auth/login_screen.dart';
import 'order_tracking_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String _provider    = 'mtn';
  final _phoneCtrl    = TextEditingController();
  bool   _isLoading   = false;

  final _providers = [
    {'id': 'mtn',       'label': 'MTN MoMo'},
    {'id': 'telecel',   'label': 'Telecel'},
    {'id': 'airteltigo','label': 'AirtelTigo'},
  ];

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkout() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final cart = Provider.of<CartProvider>(context, listen: false);

    if (!auth.isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    if (_phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: AppTheme.danger,
        content: Text('Enter your MoMo number',
            style: TextStyle(color: Colors.white)),
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Place order
      final order = await ApiService.placeOrder(
        token: auth.token!,
        restaurantId: cart.restaurantId!,
        items: cart.orderPayload,
      );

      // 2. Initiate payment
      await ApiService.initiatePayment(
        token: auth.token!,
        orderId: order.id,
        provider: _provider,
        phoneNumber: _phoneCtrl.text.trim(),
      );

      if (!mounted) return;
      cart.clearCart();

      // 3. Navigate to tracking
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order)),
        (r) => r.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppTheme.danger,
        content: Text(e.toString().replaceAll('Exception: ', ''),
            style: const TextStyle(color: Colors.white)),
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
                          style: AppText.label.copyWith(color: AppTheme.accent)),
                    ],
                  ),
                ),
                // Qty controls
                Row(
                  children: [
                    _qtyBtn(Icons.remove, () =>
                        Provider.of<CartProvider>(context, listen: false)
                            .decreaseItem(item.menuItem.id)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text('${item.quantity}',
                          style: AppText.title),
                    ),
                    _qtyBtn(Icons.add, () =>
                        Provider.of<CartProvider>(context, listen: false)
                            .addItem(item.menuItem,
                                cart.restaurantId!, cart.restaurantName!)),
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

          // ── MoMo payment ──────────────────────────────────────
          const SizedBox(height: 24),
          const Text('Pay with Mobile Money', style: AppText.heading),
          const SizedBox(height: 14),

          // Provider selector
          Row(
            children: _providers.map((p) {
              final active = _provider == p['id'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _provider = p['id']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(
                        right: p == _providers.last ? 0 : 8),
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
                      child: Text(p['label']!,
                          style: TextStyle(
                            color: active ? AppTheme.accent : AppTheme.textSecond,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                            fontSize: 12,
                          )),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _phoneCtrl,
            hint: 'MoMo number (e.g. 055 000 0000)',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
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
            onPressed: _checkout,
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
        width: 32, height: 32,
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