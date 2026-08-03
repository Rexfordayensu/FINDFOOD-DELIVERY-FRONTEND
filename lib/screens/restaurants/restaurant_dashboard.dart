import 'dart:async';
import 'dart:typed_data';
import 'package:findfood_app/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/providers.dart';
import '../customer/food_feed_screen.dart';
import 'package:findfood_app/screens/chat_screen.dart';
import 'package:http/http.dart' as http;

class RestaurantDashboard extends StatefulWidget {
  const RestaurantDashboard({super.key, required String token});
  @override
  State<RestaurantDashboard> createState() => _RestaurantDashboardState();
}

class _RestaurantDashboardState extends State<RestaurantDashboard> {
  int _selectedIndex = 0;

Future<void> _uploadRestaurantBanner(int restaurantId) async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
  );

  if (picked == null) return;

  try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiService.baseUrl}/restaurants/$restaurantId/upload-banner'),
    );
    
    // Add auth token header if your endpoints require authentication
   // request.headers['Authorization'] = 'Bearer ${widget.token}';

    request.files.add(await http.MultipartFile.fromPath('file', picked.path));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restaurant banner updated successfully! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      // Refresh dashboard state if needed
      setState(() {});
    } else {
      throw Exception('Upload failed with status: ${response.statusCode}');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to upload banner: $e'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}

  // ── Approval gate state ────────────────────────────────────────────────
  bool _checking = true;
  bool _isApproved = false;
  String _restaurantName = '';
  int _restaurantId = 0;
  String _checkError = '';

  @override
  void initState() {
    super.initState();
    _checkApproval();
  }

  Future<void> _checkApproval() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;
    setState(() { _checking = true; _checkError = ''; });
    try {
      final restaurant = await ApiService.getMyRestaurant(auth.token!);
      setState(() {
        _isApproved = restaurant.isApproved;
        _restaurantName = restaurant.name;
        _restaurantId = restaurant.id;
      });
    } catch (e) {
      setState(() => _checkError = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Still checking approval status — show a loading screen ──────────
    if (_checking) {
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.accent),
        ),
      );
    }

    // ── Failed to check status (e.g. no network) ─────────────────────────
    if (_checkError.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_rounded,
                    size: 48, color: AppColors.textHint(context)),
                const SizedBox(height: 16),
                Text('Couldn\'t verify your account',
                    style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(_checkError,
                    style: TextStyle(color: AppColors.textSecondary(context)),
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                    onPressed: _checkApproval, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    // ── Restaurant exists but hasn't been approved by admin yet ──────────
    if (!_isApproved) {
      return _PendingApprovalScreen(
        restaurantName: _restaurantName,
        onRefresh: _checkApproval,
      );
    }

    // ── Approved! Show the real dashboard ────────────────────────────────
    final pages = [
      const _OrdersPage(),
      const _MenuManagerPage(),
      const _EarningsPage(),
      _SettingsPage(restaurantId: _restaurantId)
    ];

    return Scaffold(
  body: IndexedStack(
    index: _selectedIndex,
    children: pages,
  ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          border: Border(top: BorderSide(color: AppColors.border(context))),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long_rounded),
                label: 'Orders'),
            BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_outlined),
                activeIcon: Icon(Icons.menu_book_rounded),
                label: 'Menu'),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart_rounded),
                label: 'Earnings'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings_rounded),
                label: 'Settings'),
          ],
        ),
      ),
    );
  }
}

// ─── PENDING APPROVAL SCREEN ──────────────────────────────────────────────────
// Shown to restaurant owners whose account has been created but not yet
// approved by an admin. Blocks all dashboard access until approved.
class _PendingApprovalScreen extends StatelessWidget {
  final String restaurantName;
  final VoidCallback onRefresh;

  const _PendingApprovalScreen({
    required this.restaurantName,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded,
                    color: AppTheme.warning, size: 44),
              ),
              const SizedBox(height: 28),
              Text('Application under review',
                  style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 22, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                restaurantName.isNotEmpty
                    ? '$restaurantName is waiting for admin approval.'
                    : 'Your restaurant is waiting for admin approval.',
                style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 15, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'You\'ll get full access to your dashboard — orders, menu, '
                'and earnings — as soon as an admin approves your application.',
                style: TextStyle(
                    color: AppColors.textHint(context),
                    fontSize: 13, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded,
                      color: Colors.black, size: 18),
                  label: const Text('Check approval status'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Provider.of<AuthProvider>(context, listen: false).logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const FoodFeedScreen()),
                    (_) => false,
                  );
                },
                child: Text('Sign out',
                    style: TextStyle(
                        color: AppColors.textSecondary(context), fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ORDERS PAGE WITH REAL-TIME POLLING ──────────────────────────────────────
class _OrdersPage extends StatefulWidget {
  const _OrdersPage();
  @override
  State<_OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<_OrdersPage> {
  List<Order> _orders = [];
  bool   _loading = true;
  String _error   = '';
  String _filter  = 'all';
  Timer? _pollTimer;
  int    _newOrderCount = 0;

  final _filters = ['all', 'pending', 'preparing', 'ready', 'delivered'];

  @override
  void initState() {
    super.initState();
    _load();
    // Poll every 8 seconds for new orders
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => _poll());
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
      final orders = await ApiService.getMyOrders(auth.token!);
      setState(() => _orders = orders);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _poll() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;
    try {
      final orders = await ApiService.getMyOrders(auth.token!);
      final prevCount = _orders.where((o) => o.status == 'pending').length;
      final newCount  = orders.where((o) => o.status == 'pending').length;
      setState(() {
        _orders = orders;
        _newOrderCount = newCount;
      });
      // Notify if new pending orders arrived
      if (newCount > prevCount && mounted) {
        _showNewOrderBanner(newCount - prevCount);
      }
    } catch (_) {}
  }

  void _showNewOrderBanner(int count) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppTheme.accent,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
      content: Row(children: [
        const Icon(Icons.notifications_active_rounded,
            color: Colors.black, size: 20),
        const SizedBox(width: 10),
        Text(
          '$count new order${count > 1 ? 's' : ''} received!',
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ]),
    ));
  }

  Future<void> _updateStatus(Order order, String newStatus) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final updated = await ApiService.updateOrderStatus(
        auth.token!,
        order.id,
        newStatus,
      );
      setState(() {
        final idx = _orders.indexWhere((o) => o.id == order.id);
        if (idx != -1) _orders[idx] = updated;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text('Order #${order.id} → $newStatus ✓',
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

  List<Order> get _filtered =>
      _filter == 'all' ? _orders : _orders.where((o) => o.status == _filter).toList();

  @override
  Widget build(BuildContext context) {
    final bg     = AppColors.bg(context);
    final textPri= AppColors.textPrimary(context);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Live orders',
                            style: TextStyle(
                                color: textPri,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4)),
                        Text('Auto-refreshes every 8 seconds',
                            style: TextStyle(
                                color: AppColors.textHint(context),
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  // Live indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppTheme.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      _PulseDot(),
                      const SizedBox(width: 6),
                      const Text('Live',
                          style: TextStyle(
                              color: AppTheme.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  // Refresh button
                  GestureDetector(
                    onTap: _load,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Icon(Icons.refresh_rounded,
                          color: textPri, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // ── Stats strip ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(children: [
                _StatChip('Pending',
                    '${_orders.where((o) => o.status == 'pending').length}',
                    AppTheme.accent),
                const SizedBox(width: 8),
                _StatChip('Preparing',
                    '${_orders.where((o) => o.status == 'preparing').length}',
                    AppTheme.warning),
                const SizedBox(width: 8),
                _StatChip('Ready',
                    '${_orders.where((o) => o.status == 'ready').length}',
                    AppTheme.success),
                const SizedBox(width: 8),
                _StatChip('Today',
                    '${_orders.length}',
                    AppColors.textSecondary(context)),
              ]),
            ),

            // ── Filter chips ────────────────────────────────
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final f = _filters[i];
                  final active = _filter == f;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: active
                            ? AppTheme.accent
                            : AppColors.surface(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: active
                                ? AppTheme.accent
                                : AppColors.border(context)),
                      ),
                      child: Text(
                        f[0].toUpperCase() + f.substring(1),
                        style: TextStyle(
                          color: active
                              ? Colors.black
                              : AppColors.textSecondary(context),
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Orders list ─────────────────────────────────
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
                      : _filtered.isEmpty
                          ? EmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: _filter == 'all'
                                  ? 'No orders yet'
                                  : 'No $_filter orders',
                              subtitle: _filter == 'all'
                                  ? 'New orders appear here automatically'
                                  : 'Switch filters to see other orders',
                            )
                          : RefreshIndicator(
                              color: AppTheme.accent,
                              onRefresh: _load,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    20, 4, 20, 100),
                                itemCount: _filtered.length,
                                itemBuilder: (_, i) =>
                                    _OrderCard(
                                      order: _filtered[i],
                                      onUpdateStatus: _updateStatus,
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

// ─── ORDER CARD ───────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final Order order;
  final Future<void> Function(Order, String) onUpdateStatus;

  const _OrderCard({required this.order, required this.onUpdateStatus});

  @override
  Widget build(BuildContext context) {
    final isPending   = order.status == 'pending';
    final isPreparing = order.status == 'preparing';
    final isReady     = order.status == 'ready';
    final isDone      = order.status == 'delivered';

    String? actionLabel;
    String? nextStatus;
    Color?  actionColor;

    if (isPending) {
      actionLabel = '🍳  Start preparing';
      nextStatus  = 'preparing';
      actionColor = AppTheme.warning;
    } else if (isPreparing) {
      actionLabel = '✅  Mark ready for pickup';
      nextStatus  = 'ready';
      actionColor = AppTheme.success;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? AppTheme.accent.withValues(alpha: 0.5)
              : AppColors.border(context),
          width: isPending ? 1.5 : 1,
        ),
        boxShadow: isPending
            ? [BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.1),
                blurRadius: 12, offset: const Offset(0, 4))]
            : [],
      ),
      child: Column(
        children: [
          // ── Card header ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      if (isPending)
                        Container(
                          width: 8, height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: const BoxDecoration(
                              color: AppTheme.accent,
                              shape: BoxShape.circle),
                        ),
                      Text('Order #${order.id}',
                          style: TextStyle(
                              color: AppColors.textPrimary(context),
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                    ]),
                    Row(children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              orderId: order.id,
                              otherPartyName: 'Customer', otherPartyRole: 'customer',
                            ),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.chat_bubble_outline_rounded,
                              size: 15, color: AppColors.textSecondary(context)),
                        ),
                      ),
                      StatusBadge(status: order.status),
                    ]),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(order.displayTotal,
                        style: const TextStyle(
                            color: AppTheme.accent,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    Row(children: [
                      Icon(Icons.access_time_rounded,
                          size: 13,
                          color: AppColors.textHint(context)),
                      const SizedBox(width: 4),
                      Text('Just now',
                          style: TextStyle(
                              color: AppColors.textHint(context),
                              fontSize: 12)),
                    ]),
                  ],
                ),
              ],
            ),
          ),

          // ── Action row ────────────────────────────────────
          if (actionLabel != null) ...[
            Divider(height: 1, color: AppColors.border(context)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                // Reject / cancel (only for pending)
                if (isPending) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _confirmReject(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.danger.withValues(alpha: 0.3)),
                        ),
                        child: const Center(
                          child: Text('Reject',
                              style: TextStyle(
                                  color: AppTheme.danger,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                // Main action
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () => onUpdateStatus(order, nextStatus!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: actionColor,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: actionColor!.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(actionLabel,
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                                fontSize: 13)),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ] else if (isReady) ...[
            Divider(height: 1, color: AppColors.border(context)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.success.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delivery_dining_rounded,
                        color: AppTheme.success, size: 16),
                    SizedBox(width: 8),
                    Text('Waiting for rider pickup',
                        style: TextStyle(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ],
                ),
              ),
            ),
          ] else if (isDone) ...[
            Divider(height: 1, color: AppColors.border(context)),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.success, size: 16),
                const SizedBox(width: 8),
                Text('Delivered successfully',
                    style: TextStyle(
                        color: AppColors.textHint(context),
                        fontSize: 12)),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmReject(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card(context),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Reject order #${order.id}?',
            style: TextStyle(
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.w700)),
        content: Text(
          'This will cancel the order. The customer will be notified.',
          style: TextStyle(color: AppColors.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep it',
                style: TextStyle(color: AppColors.textHint(context))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: add reject endpoint
            },
            child: const Text('Reject',
                style: TextStyle(
                    color: AppTheme.danger,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── PULSE DOT (live indicator) ───────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 7, height: 7,
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: _anim.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─── STAT CHIP ────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 16, fontWeight: FontWeight.w800)),
        Text(label,
            style: TextStyle(
                color: AppColors.textHint(context),
                fontSize: 10)),
      ]),
    );
  }
}

// ─── MENU MANAGER PAGE ────────────────────────────────────────────────────────
class _MenuManagerPage extends StatefulWidget {
  const _MenuManagerPage();
  @override
  State<_MenuManagerPage> createState() => _MenuManagerPageState();
}

class _MenuManagerPageState extends State<_MenuManagerPage> {
  List<MenuItem> _items = [];
  bool   _loading  = true;
  String _error    = '';
  int?   _restaurantId; // Fetched dynamically — no more hardcoding!
  final Set<int> _processingIds = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;
    setState(() { _loading = true; _error = ''; });
    try {
      // Step 1: resolve the logged-in owner's actual restaurant
      final restaurant = await ApiService.getMyRestaurant(auth.token!);
      _restaurantId = restaurant.id;

      // Step 2: load that restaurant's menu
      final items = await ApiService.getMenu(_restaurantId!);
      setState(() => _items = items);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── ADD ───────────────────────────────────────────────────────────────────
  void _showAddSheet() {
    final auth     = Provider.of<AuthProvider>(context, listen: false);
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl= TextEditingController();
    bool saving    = false;
    Uint8List? pickedBytes;
    String? pickedFilename;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border(ctx),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Add menu item',
                  style: TextStyle(
                      color: AppColors.textPrimary(ctx),
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),

              // ── Photo picker ──────────────────────────────
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (picked == null) return;
                  final bytes = await picked.readAsBytes();
                  set(() {
                    pickedBytes = bytes;
                    pickedFilename = picked.name;
                  });
                },
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface(ctx),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.border(ctx), style: BorderStyle.solid),
                  ),
                  child: pickedBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(pickedBytes!, fit: BoxFit.cover,
                              width: double.infinity),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                color: AppColors.textHint(ctx), size: 32),
                            const SizedBox(height: 8),
                            Text('Tap to add a food photo',
                                style: TextStyle(
                                    color: AppColors.textHint(ctx), fontSize: 13)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              AppTextField(
                  controller: nameCtrl, hint: 'Item name',
                  prefixIcon: Icons.fastfood_outlined),
              const SizedBox(height: 12),
              AppTextField(
                  controller: descCtrl, hint: 'Description (optional)',
                  prefixIcon: Icons.notes_rounded, maxLines: 2),
              const SizedBox(height: 12),
              AppTextField(
                  controller: priceCtrl,
                  hint: 'Price in pesewas (e.g. 4500 = GH₵ 45)',
                  prefixIcon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Add to menu',
                isLoading: saving,
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty ||
                      priceCtrl.text.trim().isEmpty) {
                    return;
                  }
                  set(() => saving = true);
                  try {
                    // 1. Create the menu item first
                    var item = await ApiService.addMenuItem(
                      token: auth.token!,
                      restaurantId: _restaurantId!,
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim().isEmpty
                          ? null : descCtrl.text.trim(),
                      price: int.parse(priceCtrl.text.trim()),
                    );

                    // 2. If a photo was picked, upload it now that we have the item ID
                    if (pickedBytes != null) {
                      item = await ApiService.uploadMenuItemImage(
                        token: auth.token!,
                        restaurantId: _restaurantId!,
                        itemId: item.id,
                        imageBytes: pickedBytes!,
                        filename: pickedFilename ?? 'photo.jpg',
                      );
                    }

                    if (!mounted) return;
                    Navigator.pop(ctx);
                    setState(() => _items.insert(0, item));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      backgroundColor: AppTheme.success,
                      content: Text('Item added!',
                          style: TextStyle(color: Colors.white)),
                    ));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: AppTheme.danger,
                      content: Text(e.toString().replaceAll('Exception: ', ''),
                          style: const TextStyle(color: Colors.white)),
                    ));
                  } finally {
                    set(() => saving = false);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── EDIT ──────────────────────────────────────────────────────────────────
  void _showEditSheet(MenuItem item) {
    final auth     = Provider.of<AuthProvider>(context, listen: false);
    final nameCtrl = TextEditingController(text: item.name);
    final descCtrl = TextEditingController(text: item.description ?? '');
    final priceCtrl= TextEditingController(text: item.price.toString());
    bool saving    = false;
    bool removingImage = false;
    Uint8List? pickedBytes;
    String? pickedFilename;
    String? currentImageUrl = item.imageUrl; // tracks local state after remove

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border(ctx),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Edit menu item',
                      style: TextStyle(
                          color: AppColors.textPrimary(ctx),
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(ctx);
                      _confirmDelete(item);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: AppTheme.danger, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Photo picker with existing/removed/new preview ──
              Stack(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                      );
                      if (picked == null) return;
                      final bytes = await picked.readAsBytes();
                      set(() {
                        pickedBytes = bytes;
                        pickedFilename = picked.name;
                        removingImage = false;
                      });
                    },
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surface(ctx),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border(ctx)),
                      ),
                      child: pickedBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(pickedBytes!,
                                  fit: BoxFit.cover, width: double.infinity),
                            )
                          : (currentImageUrl != null && !removingImage)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    '${ApiService.baseUrl}$currentImageUrl',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Icon(Icons.broken_image_outlined,
                                          color: AppColors.textHint(ctx)),
                                    ),
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined,
                                        color: AppColors.textHint(ctx), size: 32),
                                    const SizedBox(height: 8),
                                    Text('Tap to add a food photo',
                                        style: TextStyle(
                                            color: AppColors.textHint(ctx),
                                            fontSize: 13)),
                                  ],
                                ),
                    ),
                  ),
                  // Remove button — only shown when there's an image to clear
                  if (pickedBytes != null ||
                      (currentImageUrl != null && !removingImage))
                    Positioned(
                      top: 8, right: 8,
                      child: GestureDetector(
                        onTap: () {
                          set(() {
                            pickedBytes = null;
                            pickedFilename = null;
                            removingImage = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              AppTextField(
                  controller: nameCtrl, hint: 'Item name',
                  prefixIcon: Icons.fastfood_outlined),
              const SizedBox(height: 12),
              AppTextField(
                  controller: descCtrl, hint: 'Description (optional)',
                  prefixIcon: Icons.notes_rounded, maxLines: 2),
              const SizedBox(height: 12),
              AppTextField(
                  controller: priceCtrl,
                  hint: 'Price in pesewas',
                  prefixIcon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Save changes',
                isLoading: saving,
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty ||
                      priceCtrl.text.trim().isEmpty) {
                    return;
                  }
                  set(() => saving = true);
                  try {
                    var updated = await ApiService.updateMenuItem(
                      token: auth.token!,
                      restaurantId: _restaurantId!,
                      itemId: item.id,
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim().isEmpty
                          ? null : descCtrl.text.trim(),
                      price: int.tryParse(priceCtrl.text.trim()) ?? 0,
                    );

                    // New photo picked → upload it
                    if (pickedBytes != null) {
                      updated = await ApiService.uploadMenuItemImage(
                        token: auth.token!,
                        restaurantId: _restaurantId!,
                        itemId: item.id,
                        imageBytes: pickedBytes!,
                        filename: pickedFilename ?? 'photo.jpg',
                      );
                    }
                    // User explicitly removed the photo, no new one picked
                    else if (removingImage && item.imageUrl != null) {
                      await ApiService.removeMenuItemImage(
                        token: auth.token!,
                        restaurantId: _restaurantId!,
                        itemId: item.id,
                      );
                    }

                    if (!mounted) return;
                    Navigator.pop(ctx);
                    setState(() {
                      final idx = _items.indexWhere((m) => m.id == item.id);
                      if (idx != -1) _items[idx] = updated;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      backgroundColor: AppTheme.success,
                      content: Text('Item updated!',
                          style: TextStyle(color: Colors.white)),
                    ));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: AppTheme.danger,
                      content: Text(e.toString().replaceAll('Exception: ', ''),
                          style: const TextStyle(color: Colors.white)),
                    ));
                  } finally {
                    set(() => saving = false);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<void> _confirmDelete(MenuItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete ${item.name}?',
            style: TextStyle(color: AppColors.textPrimary(ctx))),
        content: Text('This will permanently remove it from your menu.',
            style: TextStyle(color: AppColors.textSecondary(ctx))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _processingIds.add(item.id));
    try {
      await ApiService.deleteMenuItem(
        auth.token!,
        item.id,
      );
      setState(() => _items.removeWhere((m) => m.id == item.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: AppTheme.danger,
        content: Text('Item deleted',
            style: TextStyle(color: Colors.white)),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppTheme.danger,
        content: Text(e.toString().replaceAll('Exception: ', ''),
            style: const TextStyle(color: Colors.white)),
      ));
    } finally {
      if (mounted) setState(() => _processingIds.remove(item.id));
    }
  }

  // ── TOGGLE AVAILABILITY ──────────────────────────────────────────────────
  Future<void> _toggleAvailability(MenuItem item) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _processingIds.add(item.id));
    try {
      final updated = await ApiService.toggleMenuItemAvailability(
        token: auth.token!,
        restaurantId: _restaurantId!,
        itemId: item.id,
      );
      setState(() {
        final idx = _items.indexWhere((m) => m.id == item.id);
        if (idx != -1) _items[idx] = updated as MenuItem;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppTheme.danger,
        content: Text(e.toString().replaceAll('Exception: ', ''),
            style: const TextStyle(color: Colors.white)),
      ));
    } finally {
      if (mounted) setState(() => _processingIds.remove(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Menu',
                      style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontSize: 24, fontWeight: FontWeight.w800)),
                  GestureDetector(
                    onTap: _showAddSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(children: [
                        Icon(Icons.add_rounded, color: Colors.black, size: 18),
                        SizedBox(width: 4),
                        Text('Add item',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700, fontSize: 13)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                  : _error.isNotEmpty
                      ? EmptyState(
                          icon: Icons.wifi_off_rounded,
                          title: 'Failed to load',
                          subtitle: _error,
                          actionLabel: 'Retry',
                          onAction: _load)
                      : _items.isEmpty
                          ? EmptyState(
                              icon: Icons.menu_book_outlined,
                              title: 'No items yet',
                              subtitle: 'Add your first dish.',
                              actionLabel: 'Add item',
                              onAction: _showAddSheet)
                          : RefreshIndicator(
                              color: AppTheme.accent,
                              onRefresh: _load,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                                itemCount: _items.length,
                                itemBuilder: (_, i) {
                                  final m = _items[i];
                                  final processing = _processingIds.contains(m.id);
                                  return _ManagedMenuItemCard(
                                    item: m,
                                    processing: processing,
                                    onEdit: () => _showEditSheet(m),
                                    onToggle: () => _toggleAvailability(m),
                                    onDelete: () => _confirmDelete(m),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── MANAGED MENU ITEM CARD (with edit/delete/toggle) ──────────────────────
class _ManagedMenuItemCard extends StatelessWidget {
  final MenuItem item;
  final bool processing;
  final VoidCallback onEdit, onToggle, onDelete;

  const _ManagedMenuItemCard({
    required this.item,
    required this.processing,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isAvailable
              ? AppColors.border(context)
              : AppTheme.danger.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          // Image — shows uploaded photo, falls back to icon placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 56, height: 56,
              color: AppColors.surface(context),
              child: item.imageUrl != null
                  ? Image.network(
                      item.fullImageUrl(ApiService.baseUrl)!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                          Icons.fastfood_rounded,
                          color: AppColors.textHint(context), size: 24),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                color: AppTheme.accent, strokeWidth: 2),
                          ),
                        );
                      },
                    )
                  : Icon(Icons.fastfood_rounded,
                      color: AppColors.textHint(context), size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontSize: 14, fontWeight: FontWeight.w700)),
                if (item.description != null && item.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(item.description!,
                        style: TextStyle(
                            color: AppColors.textSecondary(context), fontSize: 12),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                const SizedBox(height: 4),
                Text(item.displayPrice,
                    style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          // Actions column
          Column(
            children: [
              // Availability toggle
              GestureDetector(
                onTap: processing ? null : onToggle,
                child: processing
                    ? const SizedBox(
                        width: 36, height: 20,
                        child: Center(
                          child: SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(
                                color: AppTheme.accent, strokeWidth: 2),
                          ),
                        ),
                      )
                    : Container(
                        width: 36, height: 20,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: item.isAvailable
                              ? AppTheme.success
                              : AppColors.border(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          alignment: item.isAvailable
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            width: 16, height: 16,
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.edit_outlined,
                          color: AppColors.textSecondary(context), size: 15),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: processing ? null : onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: AppTheme.danger, size: 15),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── EARNINGS / ANALYTICS PAGE (live data) ────────────────────────────────────
class _EarningsPage extends StatefulWidget {
  const _EarningsPage();
  @override
  State<_EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<_EarningsPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String _error = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;
    setState(() { _loading = true; _error = ''; });
    try {
      final data = await ApiService.getRestaurantAnalytics(auth.token!);
      setState(() => _data = data);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPri = AppColors.textPrimary(context);
    final textSec = AppColors.textSecondary(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.accent,
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Earnings & Analytics',
                        style: TextStyle(
                            color: textPri, fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded,
                          color: AppTheme.accent),
                      onPressed: _load,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator(
                        color: AppTheme.accent)),
                  )
                else if (_error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.wifi_off_rounded,
                            size: 44, color: AppColors.textHint(context)),
                        const SizedBox(height: 10),
                        Text(_error,
                            style: TextStyle(color: textSec),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 14),
                        ElevatedButton(
                            onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  )
                else ...[
                  // ── Revenue hero card ──────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.accent.withValues(alpha: 0.15),
                          AppTheme.accent.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: AppTheme.accent.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total revenue',
                            style: TextStyle(
                                color: textSec, fontSize: 13)),
                        const SizedBox(height: 6),
                        Text(
                          'GH₵ ${((_data?['total_revenue'] ?? 0) / 100).toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: AppTheme.accent,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.receipt_long_rounded,
                                size: 14, color: textSec),
                            const SizedBox(width: 5),
                            Text(
                              '${_data?['delivered_orders'] ?? 0} delivered orders',
                              style: TextStyle(color: textSec, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Stat row ────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _miniStat(context, 'Total orders',
                            '${_data?['total_orders'] ?? 0}',
                            Icons.shopping_bag_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _miniStat(context, 'Avg order value',
                            'GH₵ ${((_data?['avg_order_value'] ?? 0) / 100).toStringAsFixed(2)}',
                            Icons.trending_up_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── 7-day revenue bar chart ──────────────────────
                  Text('Last 7 days',
                      style: TextStyle(
                          color: textPri, fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  _RevenueBarChart(
                    data: (_data?['daily_revenue'] as List<dynamic>?)
                            ?.cast<Map<String, dynamic>>() ??
                        [],
                  ),
                  const SizedBox(height: 24),

                  // ── Top items ─────────────────────────────────
                  Text('Best sellers',
                      style: TextStyle(
                          color: textPri, fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  if ((_data?['top_items'] as List?)?.isEmpty ?? true)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text('No sales data yet',
                          style: TextStyle(color: textSec)),
                    )
                  else
                    ...List.generate(
                      (_data!['top_items'] as List).length,
                      (i) {
                        final item = _data!['top_items'][i];
                        final maxCount = (_data!['top_items'][0]['count'] as int);
                        final ratio = maxCount > 0
                            ? (item['count'] as int) / maxCount
                            : 0.0;
                        return _bestSellerRow(
                            context, i + 1, item['name'], item['count'], ratio);
                      },
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStat(BuildContext ctx, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(ctx),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(ctx)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.accent, size: 18),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  color: AppColors.textPrimary(ctx),
                  fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: AppColors.textHint(ctx), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _bestSellerRow(
      BuildContext ctx, int rank, String name, int count, double ratio) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(ctx),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(ctx)),
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: rank == 1
                  ? AppTheme.accent.withValues(alpha: 0.15)
                  : AppColors.surface(ctx),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$rank',
                  style: TextStyle(
                      color: rank == 1
                          ? AppTheme.accent
                          : AppColors.textHint(ctx),
                      fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        color: AppColors.textPrimary(ctx),
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 5,
                    backgroundColor: AppColors.surface(ctx),
                    valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('$count sold',
              style: TextStyle(
                  color: AppColors.textSecondary(ctx), fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── SIMPLE REVENUE BAR CHART (no external deps) ──────────────────────────────
class _RevenueBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _RevenueBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Text('No revenue data yet',
            style: TextStyle(color: AppColors.textSecondary(context))),
      );
    }

    final maxRevenue = data
        .map((d) => (d['revenue'] as num).toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((d) {
          final revenue = (d['revenue'] as num).toDouble();
          final ratio   = maxRevenue > 0 ? revenue / maxRevenue : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: ratio),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => Container(
                      height: 90 * v,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(d['day'] ?? '',
                      style: TextStyle(
                          color: AppColors.textHint(context), fontSize: 10)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── SETTINGS PAGE ────────────────────────────────────────────────────────────
class _SettingsPage extends StatefulWidget {
  final int restaurantId;
  const _SettingsPage({Key? key, required this.restaurantId}) : super(key: key);
  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {

  bool _isOpen = true;

Future<void> _uploadRestaurantBanner(int restaurantId) async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
  );

  if (picked == null) return;

  try {
    // Matches http://127.0.0.1:8000/3/upload-banner
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiService.baseUrl}/$restaurantId/upload-banner'),
    );

    final bytes = await picked.readAsBytes();

    request.files.add(
      http.MultipartFile.fromBytes(
        'file', // Matches the required 'file' parameter in Swagger
        bytes,
        filename: picked.name,
      ),
    );

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Banner updated successfully! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      throw Exception('Upload failed with status: ${response.statusCode}');
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to upload banner: $e'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 24,
                  fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 24),

             // Banner Upload Button
// Banner Upload Button
ElevatedButton.icon(
  onPressed: () {
    if (widget.restaurantId > 0) {
  _uploadRestaurantBanner(widget.restaurantId);
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Loading restaurant info...')),
  );
}
  },
  icon: const Icon(Icons.add_a_photo_rounded),
  label: const Text("Upload image for your store"),
  style: ElevatedButton.styleFrom(
    minimumSize: const Size(double.infinity, 48),
  ),
),
              const SizedBox(height: 16),

              // Kitchen toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kitchen status',
                            style: TextStyle(
                                color: AppColors.textPrimary(context),
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                        Text(
                          _isOpen
                              ? 'Accepting orders'
                              : 'Closed for orders',
                          style: TextStyle(
                              color: _isOpen
                                  ? AppTheme.success
                                  : AppColors.textHint(context),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isOpen,
                    onChanged: (v) => setState(() => _isOpen = v),
                    activeThumbColor: AppTheme.accent,
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              _row(context, Icons.storefront_outlined, 'Restaurant profile',
                  'Edit your restaurant details'),
              _row(context, Icons.notifications_outlined, 'Notifications',
                  'Manage alert preferences'),
              _row(context, Icons.lock_outline_rounded, 'Change password',
                  'Update your password'),
              const Spacer(),
              GhostButton(
                label: 'Sign out',
                onPressed: () {
                  auth.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FoodFeedScreen()),
                    (_) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext ctx, IconData icon,
      String label, String sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(ctx),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(ctx)),
      ),
      child: Row(children: [
        Icon(icon, color: AppColors.textHint(ctx), size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: AppColors.textPrimary(ctx),
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              Text(sub,
                  style: TextStyle(
                      color: AppColors.textHint(ctx), fontSize: 12)),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_ios_rounded,
            color: AppColors.textHint(ctx), size: 13),
      ]),
    );
  }
}