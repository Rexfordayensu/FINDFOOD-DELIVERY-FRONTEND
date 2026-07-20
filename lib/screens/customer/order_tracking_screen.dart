import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/providers.dart';
import '../customer/food_feed_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final Order order;
  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late Order _order;
  Timer? _pollTimer;
  

  static const _steps = [
    {'status': 'pending',          'label': 'Order placed',      'icon': Icons.receipt_long_outlined},
    {'status': 'preparing',        'label': 'Preparing food',    'icon': Icons.soup_kitchen_outlined},
    {'status': 'ready',            'label': 'Ready for pickup',  'icon': Icons.check_circle_outline},
    {'status': 'out_for_delivery', 'label': 'Rider on the way',  'icon': Icons.electric_bike_outlined},
    {'status': 'delivered',        'label': 'Delivered',         'icon': Icons.home_outlined},
  ];

  static const _statusOrder = [
    'pending', 'preparing', 'ready', 'out_for_delivery', 'delivered'
  ];

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ── Poll backend every 4s for live status updates ──────────────────────────
  void _startPolling() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      try {
        final orders = await ApiService.getMyOrders(auth.token!);
        final updated = orders.where((o) => o.id == _order.id).firstOrNull;
        if (updated != null && mounted && updated.status != _order.status) {
          setState(() => _order = updated);
          if (updated.status == 'delivered') {
            _pollTimer?.cancel();
            _showDeliveredCelebration();
          }
        }
      } catch (_) {
        // Silent — keep last known state
      }
    });
  }

  void _showDeliveredCelebration() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, v, child) =>
                  Transform.scale(scale: v, child: child),
              child: Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.celebration_rounded,
                    color: AppTheme.success, size: 44),
              ),
            ),
            const SizedBox(height: 20),
            Text('Delivered!',
                style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Enjoy your meal! How was your experience?',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary(context))),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 3),
                child: Icon(Icons.star_rounded,
                    color: AppTheme.accent, size: 32),
              )),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Back to home',
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const FoodFeedScreen()),
                (_) => false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int get _currentStep => _statusOrder.indexOf(_order.status);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${_order.id}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () =>
              Navigator.popUntil(context, (r) => r.isFirst),
        ),
        actions: [
          // Live indicator
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                      color: AppTheme.success, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Text('Live',
                    style: TextStyle(
                        color: AppTheme.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── ETA Card ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.accentDim,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.delivery_dining_rounded,
                    color: AppTheme.accent, size: 36),
                const SizedBox(height: 10),
                Text('Estimated arrival',
                    style: TextStyle(color: AppColors.textSecondary(context))),
                const SizedBox(height: 6),
                const Text('25–35 min',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    )),
                const SizedBox(height: 8),
                StatusBadge(status: _order.status),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Status steps ──────────────────────────────────
          Text('Order status',
              style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ..._steps.asMap().entries.map((entry) {
            final i      = entry.key;
            final step   = entry.value;
            final curr   = _currentStep;
            final done   = i < curr;
            final active = i == curr;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? AppTheme.success
                            : active
                                ? AppTheme.accent
                                : AppColors.surface(context),
                        border: Border.all(
                          color: done
                              ? AppTheme.success
                              : active
                                  ? AppTheme.accent
                                  : AppColors.border(context),
                        ),
                      ),
                      child: active
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(
                                  color: Colors.black, strokeWidth: 2),
                            )
                          : Icon(
                              done ? Icons.check_rounded
                                   : step['icon'] as IconData,
                              size: 18,
                              color: done
                                  ? Colors.white
                                  : AppColors.textHint(context),
                            ),
                    ),
                    if (i < _steps.length - 1)
                      Container(
                        width: 2, height: 36,
                        color: done
                            ? AppTheme.success
                            : AppColors.border(context),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['label'] as String,
                          style: TextStyle(
                            color: active
                                ? AppTheme.accent
                                : done
                                    ? AppColors.textPrimary(context)
                                    : AppColors.textHint(context),
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w400,
                            fontSize: 15,
                          ),
                        ),
                        if (active)
                          Text('In progress...',
                              style: TextStyle(
                                  color: AppColors.textHint(context),
                                  fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),

          // ── Order summary ─────────────────────────────────
          Divider(color: AppColors.border(context)),
          const SizedBox(height: 16),
          Text('Order summary',
              style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _infoRow('Order ID', '#${_order.id}'),
          _infoRow('Total', _order.displayTotal),
          _infoRow('Status', _order.status.replaceAll('_', ' ')),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary(context))),
          Text(value,
              style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}