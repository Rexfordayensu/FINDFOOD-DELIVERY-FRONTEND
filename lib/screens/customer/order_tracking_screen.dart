import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';

class OrderTrackingScreen extends StatelessWidget {
  final Order order;
  const OrderTrackingScreen({super.key, required this.order});

  static const _steps = [
    {'status': 'pending',          'label': 'Order placed',      'icon': Icons.receipt_long_outlined},
    {'status': 'preparing',        'label': 'Preparing food',    'icon': Icons.soup_kitchen_outlined},
    {'status': 'ready',            'label': 'Ready for pickup',  'icon': Icons.check_circle_outline},
    {'status': 'out_for_delivery', 'label': 'Rider on the way',  'icon': Icons.electric_bike_outlined},
    {'status': 'delivered',        'label': 'Delivered',         'icon': Icons.home_outlined},
  ];

    int get _currentStep {
    const statusOrder = [
      'pending', 'preparing', 'ready', 'out_for_delivery', 'delivered'
    ];
    
    final index = statusOrder.indexOf(order.status); 
    
    // Fallback to 0 (pending) if the status string doesn't match perfectly
    return index == -1 ? 0 : index;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.id}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── ETA Card ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.accentDim,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.delivery_dining_rounded,
                    color: AppTheme.accent, size: 36),
                const SizedBox(height: 10),
                const Text('Estimated arrival',
                    style: AppText.body),
                const SizedBox(height: 6),
                const Text('25–35 min',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    )),
                const SizedBox(height: 8),
                StatusBadge(status: order.status),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Status steps ──────────────────────────────────────
          const Text('Order status', style: AppText.heading),
          const SizedBox(height: 16),
          ..._steps.asMap().entries.map((entry) {
            final i     = entry.key;
            final step  = entry.value;
            final curr  = _currentStep;
            final done  = i < curr;
            final active = i == curr;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dot + line
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? AppTheme.success
                            : active
                                ? AppTheme.accent
                                : AppTheme.surface,
                        border: Border.all(
                          color: done
                              ? AppTheme.success
                              : active
                                  ? AppTheme.accent
                                  : AppTheme.darkBorder,
                        ),
                      ),
                      child: Icon(
                        done ? Icons.check_rounded : step['icon'] as IconData,
                        size: 18,
                        color: done
                            ? Colors.white
                            : active
                                ? AppTheme.black
                                : AppTheme.textHint,
                      ),
                    ),
                    if (i < _steps.length - 1)
                      Container(
                        width: 2, height: 36,
                        color: done ? AppTheme.success : AppTheme.darkBorder,
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
                                    ? AppTheme.textPrimary
                                    : AppTheme.textHint,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w400,
                            fontSize: 15,
                          ),
                        ),
                        if (active)
                          Text('In progress...',
                              style: TextStyle(
                                  color: AppTheme.textHint, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),

          // ── Order summary ─────────────────────────────────────
          const Divider(color: AppTheme.darkBorder),
          const SizedBox(height: 16),
          const Text('Order summary', style: AppText.heading),
          const SizedBox(height: 12),
          _infoRow('Order ID', '#${order.id}'),
          _infoRow('Total', order.displayTotal),
          _infoRow('Status', order.status),
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
          Text(label, style: AppText.body),
          Text(value,
              style: AppText.label.copyWith(color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}