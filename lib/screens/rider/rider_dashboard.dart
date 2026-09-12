import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/providers.dart';


class RiderDashboard extends StatefulWidget {
  const RiderDashboard({super.key});

  @override
  State<RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends State<RiderDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _AvailableDeliveriesPage(),
      const _MyDeliveriesPage(),
      const _RiderEarningsPage(),
      const _RiderSettingsPage(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.cardBorder ?? Colors.grey)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore_rounded),
              label: 'Available',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.electric_bike_outlined),
              activeIcon: Icon(Icons.electric_bike_rounded),
              label: 'My Deliveries',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payments_outlined),
              activeIcon: Icon(Icons.payments_rounded),
              label: 'Earnings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── AVAILABLE DELIVERIES PAGE ────────────────────────────────────────────────
class _AvailableDeliveriesPage extends StatefulWidget {
  const _AvailableDeliveriesPage();

  @override
  State<_AvailableDeliveriesPage> createState() =>
      _AvailableDeliveriesPageState();
}

class _AvailableDeliveriesPageState extends State<_AvailableDeliveriesPage> {
  List<Order> _orders  = [];
  bool   _loading      = true;
  bool   _isOnline     = true;
  String _error        = '';
  Timer? _pollTimer;
  int    _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
    // Poll every 6 seconds for new available jobs
    _pollTimer = Timer.periodic(
        const Duration(seconds: 6), (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;
    setState(() { _loading = true; _error = ''; });
    try {
      final response = await ApiService.getAvailableDeliveries(auth.token!);
      if (!mounted) return;
      setState(() {
        _orders = response;
        _previousCount = response.length;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // Silent background refresh — no loading spinner, just updates the list
  Future<void> _poll() async {
    if (!_isOnline) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;
    try {
      final response = await ApiService.getAvailableDeliveries(auth.token!);
      if (!mounted) return;
      if (response.length > _previousCount) {
        // New job appeared — notify rider
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          content: const Row(
            children: [
              Icon(Icons.notifications_active_rounded,
                  color: Colors.black, size: 18),
              SizedBox(width: 8),
              Text('New delivery available!',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.w700)),
            ],
          ),
        ));
      }
      setState(() {
        _orders = response;
        _previousCount = response.length;
      });
    } catch (_) {
      // Silent fail on background poll
    }
  }

  Future<void> _acceptDelivery(Order order) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await ApiService.updateOrderStatus(
  auth.token!,
  order.id,
  'out_for_delivery', // Just pass the raw string values!
);
      if (!mounted) return;
      setState(() => _orders.removeWhere((o) => o.id == order.id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppTheme.success,
        content: Text('Delivery #${order.id} accepted! Head to pickup.',
            style: const TextStyle(color: Colors.white)),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppTheme.danger,
        content: Text(e.toString().replaceAll('Exception: ', ''),
            style: const TextStyle(color: Colors.white)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Available jobs', style: AppText.display),
                      SizedBox(height: 2),
                      Text('Tap a job to accept it',
                          style: AppText.body),
                    ],
                  ),
                  // Online / Offline toggle
                  GestureDetector(
                    onTap: () => setState(() => _isOnline = !_isOnline),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isOnline
                            ? AppTheme.success.withValues(alpha: 0.12)
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isOnline
                              ? AppTheme.success.withValues(alpha: 0.5)
                              : AppTheme.cardBorder  ?? Colors.grey,
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: _isOnline
                                  ? AppTheme.success
                                  : AppTheme.textHint,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              color: _isOnline
                                  ? AppTheme.success
                                  : AppTheme.textHint,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Stats strip ─────────────────────────────────────
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _statPill(Icons.electric_bike_rounded,
                      '${_orders.length}', 'Available'),
                  _statPill(Icons.check_circle_outline_rounded,
                      '7', 'Completed today'),
                  _statPill(Icons.payments_outlined,
                      'GH₵ 84', 'Earned today'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Orders ─────────────────────────────────────────
            Expanded(
              child: !_isOnline
                  ? const EmptyState(
                      icon: Icons.electric_bike_outlined,
                      title: 'You\'re offline',
                      subtitle:
                          'Go online to start seeing available deliveries.',
                    )
                  : _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.accent))
                      : _error.isNotEmpty
                          ? EmptyState(
                              icon: Icons.wifi_off_rounded,
                              title: 'Connection failed',
                              subtitle: _error,
                              actionLabel: 'Retry',
                              onAction: _load,
                            )
                          : _orders.isEmpty
                              ? const EmptyState(
                                  icon: Icons.inbox_outlined,
                                  title: 'No deliveries right now',
                                  subtitle:
                                      'Stay online — new jobs appear as orders come in.',
                                )
                              : RefreshIndicator(
                                  color: AppTheme.accent,
                                  onRefresh: _load,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 4, 20, 100),
                                    itemCount: _orders.length,
                                    itemBuilder: (_, i) =>
                                        _deliveryCard(_orders[i]),
                                  ),
                                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statPill(IconData icon, String value, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder  ?? Colors.grey),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accent, size: 20),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              Text(label, style: AppText.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _deliveryCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          // ── Route info ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    // Wrap the Order ID and Chat icon together
    Row(
      children: [
        Text('Order #${order.id}', style: AppText.title),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: AppTheme.accent),
          constraints: const BoxConstraints(), // Keeps the button compact
          padding: EdgeInsets.zero,
          onPressed: () {
            context.push('/order-chat/${order.id}', extra: order);
          },
        ),
      ],
    ),
    Text(order.displayTotal,
        style: AppText.title
            .copyWith(color: AppTheme.accent)),
  ],
),
                const SizedBox(height: 14),

                // Pickup
                Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.storefront_rounded,
                          color: AppTheme.accent, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pickup',
                              style: TextStyle(
                                  color: AppTheme.textHint,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500)),
                          Text('Restaurant location',
                              style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),

                // Line connector
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Container(
                    width: 2, height: 20,
                    color: AppTheme.cardBorder,
                  ),
                ),

                // Dropoff
                Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.home_rounded,
                          color: AppTheme.success, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dropoff',
                              style: TextStyle(
                                  color: AppTheme.textHint,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500)),
                          Text('Customer address',
                              style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 12, color: AppTheme.textHint),
                          const SizedBox(width: 4),
                          Text('~15 min',
                              style: TextStyle(
                                  color: AppTheme.textHint, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppTheme.cardBorder),

          // ── Accept button ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => _acceptDelivery(order),
                icon: Icon(Icons.electric_bike_rounded,
                    color: AppTheme.black, size: 18),
                label: const Text('Accept delivery'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── MY DELIVERIES PAGE ───────────────────────────────────────────────────────
class _MyDeliveriesPage extends StatefulWidget {
  const _MyDeliveriesPage();

  @override
  State<_MyDeliveriesPage> createState() => _MyDeliveriesPageState();
}

class _MyDeliveriesPageState extends State<_MyDeliveriesPage> {
  List<Order> _orders = [];
  bool   _loading = true;
  String _error   = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;
    setState(() { _loading = true; _error = ''; });
    try {
      final orders = await ApiService.getMyOrders(auth.token!);
      if (!mounted) return;
      setState(() => _orders = orders);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _markDelivered(Order order) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
    await ApiService.updateOrderStatus(
  auth.token!,
  order.id,
  'delivered',
);
      if (!mounted) return;
      setState(() {
        final idx = _orders.indexWhere((o) => o.id == order.id);
        if (idx != -1) _orders[idx] = _orders[idx].copyWith(status: 'delivered');
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: AppTheme.success,
        content: Text('Order marked as delivered! 🎉',
            style: TextStyle(color: Colors.white)),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppTheme.danger,
        content: Text(e.toString().replaceAll('Exception: ', ''),
            style: const TextStyle(color: Colors.white)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Text('My deliveries', style: AppText.display),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.accent))
                  : _error.isNotEmpty
                      ? EmptyState(
                          icon: Icons.wifi_off_rounded,
                          title: 'Failed to load',
                          subtitle: _error,
                          actionLabel: 'Retry',
                          onAction: _load,
                        )
                      : _orders.isEmpty
                          ? const EmptyState(
                              icon: Icons.electric_bike_outlined,
                              title: 'No deliveries yet',
                              subtitle:
                                  'Accept a job from Available tab to get started.',
                            )
                          : RefreshIndicator(
                              color: AppTheme.accent,
                              onRefresh: _load,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    20, 0, 20, 100),
                                itemCount: _orders.length,
                                itemBuilder: (_, i) =>
                                    _myDeliveryCard(_orders[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _myDeliveryCard(Order order) {
    final isActive = order.status == 'out_for_delivery';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppTheme.accent.withValues(alpha: 0.4)
              : AppTheme.cardBorder  ?? Colors.grey,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order #${order.id}', style: AppText.title),
              StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(order.displayTotal,
              style: AppText.label.copyWith(color: AppTheme.accent)),
          if (isActive) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: () => _markDelivered(order),
                icon: Icon(Icons.check_rounded,
                    color: AppTheme.black, size: 18),
                label: const Text('Mark as delivered'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── RIDER EARNINGS PAGE ──────────────────────────────────────────────────────
class _RiderEarningsPage extends StatelessWidget {
  const _RiderEarningsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Earnings', style: AppText.display),
              const SizedBox(height: 20),

              // Balance card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.accentDim,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.accent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total earned today',
                        style: AppText.label),
                    const SizedBox(height: 6),
                    const Text('GH₵ 84.00',
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        )),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.local_shipping_outlined,
                            color: AppTheme.textSecond, size: 14),
                        const SizedBox(width: 6),
                        Text('7 deliveries completed',
                            style: AppText.caption
                                .copyWith(color: AppTheme.textSecond)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  _miniStat('This week', 'GH₵ 420'),
                  const SizedBox(width: 14),
                  _miniStat('This month', 'GH₵ 1,840'),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Recent deliveries', style: AppText.heading),
              const SizedBox(height: 14),

              ...[
                ('Order #2841', 'GH₵ 12.00', 'Delivered'),
                ('Order #2839', 'GH₵ 15.00', 'Delivered'),
                ('Order #2836', 'GH₵ 10.00', 'Delivered'),
              ].map((r) => _recentRow(r.$1, r.$2, r.$3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder ?? Colors.grey),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.caption),
            const SizedBox(height: 4),
            Text(value, style: AppText.title),
          ],
        ),
      ),
    );
  }

  Widget _recentRow(String id, String amount, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder ?? Colors.grey),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(id, style: AppText.label),
          StatusBadge(status: status.toLowerCase()),
          Text(amount,
              style: AppText.label.copyWith(
                  color: AppTheme.accent, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─── RIDER SETTINGS / PROFILE PAGE ───────────────────────────────────────────
class _RiderSettingsPage extends StatelessWidget {
  const _RiderSettingsPage();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Profile', style: AppText.display),
              const SizedBox(height: 24),

              // Avatar row
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppTheme.accentDim,
                    child: Text(
                      (auth.name ?? 'R')[0].toUpperCase(),
                      style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 24,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(auth.name ?? 'Rider',
                          style: AppText.heading),
                      const Text('Active rider',
                          style: TextStyle(
                              color: AppTheme.success,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              _settingsRow(Icons.person_outline_rounded, 'Edit profile'),
              _settingsRow(Icons.notifications_outlined, 'Notifications'),
              _settingsRow(Icons.help_outline_rounded, 'Help & support'),
              _settingsRow(Icons.lock_outline_rounded, 'Change password'),
              const Spacer(),
              GhostButton(
                label: 'Sign out',
                onPressed: () {
                  auth.logout();
                    context.go('/');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsRow(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder ?? Colors.grey),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textHint, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: AppText.title)),
          Icon(Icons.arrow_forward_ios_rounded,
              color: AppTheme.textHint, size: 14),
        ],
      ),
    );
  }
}