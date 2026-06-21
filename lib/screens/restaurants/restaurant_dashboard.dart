import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/providers.dart';

class RestaurantDashboard extends StatefulWidget {
  const RestaurantDashboard({super.key});

  @override
  State<RestaurantDashboard> createState() => _RestaurantDashboardState();
}

class _RestaurantDashboardState extends State<RestaurantDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _OrdersPage(),
      const _MenuManagerPage(),
      const _EarningsPage(),
      const _SettingsPage(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.darkBorder)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book_rounded),
              label: 'Menu',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: 'Earnings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ORDERS PAGE ──────────────────────────────────────────────────────────────
class _OrdersPage extends StatefulWidget {
  const _OrdersPage();

  @override
  State<_OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<_OrdersPage> {
  List<Order> _orders = [];
  bool   _loading = true;
  String _error   = '';
  String _filter  = 'all'; // all | pending | preparing | ready | delivered

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
      setState(() => _orders = orders);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(Order order, String newStatus) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final updated = await ApiService.updateOrderStatus(
        token: auth.token!,
        orderId: order.id,
        newStatus: newStatus,
      );
      setState(() {
        final idx = _orders.indexWhere((o) => o.id == order.id);
        if (idx != -1) _orders[idx] = updated;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppTheme.success,
        content: Text('Order #${order.id} → $newStatus',
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

  List<Order> get _filtered {
    if (_filter == 'all') return _orders;
    return _orders.where((o) => o.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Live orders', style: AppText.display),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppTheme.success.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 7, height: 7,
                          decoration: const BoxDecoration(
                            color: AppTheme.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('Kitchen open',
                            style: TextStyle(
                                color: AppTheme.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Filter chips ────────────────────────────────────
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                children: [
                  _chip('All', 'all'),
                  _chip('Pending', 'pending'),
                  _chip('Preparing', 'preparing'),
                  _chip('Ready', 'ready'),
                  _chip('Delivered', 'delivered'),
                ],
              ),
            ),

            // ── Orders list ─────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.accent))
                  : _error.isNotEmpty
                      ? EmptyState(
                          icon: Icons.wifi_off_rounded,
                          title: 'Failed to load orders',
                          subtitle: _error,
                          actionLabel: 'Retry',
                          onAction: _load,
                        )
                      : _filtered.isEmpty
                          ? const EmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: 'No orders here',
                              subtitle: 'New orders will appear automatically.',
                            )
                          : RefreshIndicator(
                              color: AppTheme.accent,
                              onRefresh: _load,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    20, 4, 20, 100),
                                itemCount: _filtered.length,
                                itemBuilder: (_, i) =>
                                    _orderCard(_filtered[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    final active = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppTheme.accent : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? AppTheme.accent : AppTheme.darkBorder),
        ),
        child: Text(label,
            style: TextStyle(
              color: active ? AppTheme.black : AppTheme.textSecond,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              fontSize: 13,
            )),
      ),
    );
  }

  Widget _orderCard(Order order) {
    // Determine next action for this restaurant
    String? nextStatus;
    String? actionLabel;
    if (order.status == 'pending') {
      nextStatus  = 'preparing';
      actionLabel = 'Start preparing';
    } else if (order.status == 'preparing') {
      nextStatus  = 'ready';
      actionLabel = 'Mark ready';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: order.status == 'pending'
              ? AppTheme.accent.withValues(alpha: 0.4)
              : AppTheme.darkBorder,
        ),
      ),
      child: Column(
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #${order.id}', style: AppText.title),
                    const SizedBox(height: 2),
                    Text(order.displayTotal,
                        style: AppText.label
                            .copyWith(color: AppTheme.accent)),
                  ],
                ),
                StatusBadge(status: order.status),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.darkBorder),

          // Action row
          if (actionLabel != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  onPressed: () => _updateStatus(order, nextStatus!),
                  child: Text(actionLabel),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.success, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    order.status == 'delivered'
                        ? 'Order completed'
                        : 'Waiting for rider pickup',
                    style: TextStyle(
                        color: AppTheme.textHint, fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
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
  List<MenuItem> _items   = [];
  bool   _loading = true;
  String _error   = '';


  static const int _restaurantId = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final items = await ApiService.getMenu(_restaurantId);
      setState(() => _items = items);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showAddItemSheet() {
    final auth       = Provider.of<AuthProvider>(context, listen: false);
    final nameCtrl   = TextEditingController();
    final descCtrl   = TextEditingController();
    final priceCtrl  = TextEditingController();
    bool  saving     = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20,
              MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textHint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Add menu item', style: AppText.heading),
              const SizedBox(height: 16),
              AppTextField(controller: nameCtrl,  hint: 'Item name',
                  prefixIcon: Icons.fastfood_outlined),
              const SizedBox(height: 12),
              AppTextField(controller: descCtrl,  hint: 'Description (optional)',
                  prefixIcon: Icons.notes_rounded, maxLines: 2),
              const SizedBox(height: 12),
              AppTextField(controller: priceCtrl, hint: 'Price in pesewas (e.g. 4500 = GH₵ 45)',
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
                  setSheet(() => saving = true);
                  try {
                    final item = await ApiService.addMenuItem(
                      token: auth.token!,
                      restaurantId: _restaurantId,
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim().isEmpty
                          ? null
                          : descCtrl.text.trim(),
                      price: int.parse(priceCtrl.text.trim()),
                    );
                    if (!mounted) return;
                    // ignore: use_build_context_synchronously
                    Navigator.pop(ctx);
                    setState(() => _items.insert(0, item));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      backgroundColor: AppTheme.success,
                      content: Text('Item added!',
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
                    setSheet(() => saving = false);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Menu', style: AppText.display),
                  GestureDetector(
                    onTap: _showAddItemSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add_rounded,
                              color: AppTheme.black, size: 18),
                          const SizedBox(width: 4),
                          Text('Add item',
                              style: TextStyle(
                                  color: AppTheme.black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.accent))
                  : _error.isNotEmpty
                      ? EmptyState(
                          icon: Icons.wifi_off_rounded,
                          title: 'Failed to load menu',
                          subtitle: _error,
                          actionLabel: 'Retry',
                          onAction: _load,
                        )
                      : _items.isEmpty
                          ? EmptyState(
                              icon: Icons.menu_book_outlined,
                              title: 'No menu items yet',
                              subtitle: 'Tap "Add item" to add your first dish.',
                              actionLabel: 'Add first item',
                              onAction: _showAddItemSheet,
                            )
                          : RefreshIndicator(
                              color: AppTheme.accent,
                              onRefresh: _load,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    20, 0, 20, 100),
                                itemCount: _items.length,
                                itemBuilder: (_, i) {
                                  final m = _items[i];
                                  return MenuItemCard(
                                    name: m.name,
                                    description: m.description,
                                    price: m.displayPrice,
                                    isAvailable: m.isAvailable,
                                    onAdd: () {},
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

// ─── EARNINGS PAGE ────────────────────────────────────────────────────────────
class _EarningsPage extends StatelessWidget {
  const _EarningsPage();

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
                    const Text('Today\'s revenue',
                        style: AppText.label),
                    const SizedBox(height: 6),
                    const Text('GH₵ 682.00',
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        )),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.trending_up_rounded,
                            color: AppTheme.success, size: 16),
                        const SizedBox(width: 4),
                        Text('+18% from yesterday',
                            style: AppText.caption
                                .copyWith(color: AppTheme.success)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _miniStat('Orders today', '14'),
                  const SizedBox(width: 14),
                  _miniStat('Avg order value', 'GH₵ 48.7'),
                ],
              ),
              const SizedBox(height: 24),
              const Text('This week', style: AppText.heading),
              const SizedBox(height: 14),
              ...[
                ('Monday',    'GH₵ 420', 11),
                ('Tuesday',   'GH₵ 580', 15),
                ('Wednesday', 'GH₵ 310', 8),
                ('Thursday',  'GH₵ 682', 14),
              ].map((row) => _weekRow(row.$1, row.$2, row.$3)),
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
          border: Border.all(color: AppTheme.darkBorder),
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

  Widget _weekRow(String day, String amount, int orders) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day, style: AppText.label),
          Text('$orders orders',
              style: AppText.caption),
          Text(amount,
              style: AppText.label.copyWith(
                  color: AppTheme.accent, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─── SETTINGS PAGE ────────────────────────────────────────────────────────────
class _SettingsPage extends StatefulWidget {
  const _SettingsPage();

  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {
  bool _isOpen = true;

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
              const Text('Settings', style: AppText.display),
              const SizedBox(height: 24),

              // Kitchen status toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Kitchen status', style: AppText.title),
                        Text(
                          _isOpen ? 'Currently accepting orders' : 'Closed for orders',
                          style: TextStyle(
                            color: _isOpen ? AppTheme.success : AppTheme.textHint,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isOpen,
                      onChanged: (v) => setState(() => _isOpen = v),
                      activeThumbColor: AppTheme.accent,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _settingsRow(Icons.storefront_outlined, 'Restaurant profile'),
              _settingsRow(Icons.notifications_outlined, 'Notifications'),
              _settingsRow(Icons.lock_outline_rounded, 'Change password'),
              const Spacer(),
              GhostButton(
                label: 'Sign out',
                onPressed: () {
                  auth.logout();
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/', (_) => false);
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
        border: Border.all(color: AppTheme.darkBorder),
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