import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../services/api_service.dart';
import '../../services/providers.dart';
import '../../models/models.dart';
import '../auth/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  int _pendingCount = 0;
  bool _loadingCount = true;

  final _navItems = [
    {'icon': Icons.grid_view_rounded,           'label': 'Overview'},
    {'icon': Icons.storefront_outlined,          'label': 'Approvals'},
    {'icon': Icons.electric_bike_outlined,       'label': 'Riders'},
    {'icon': Icons.people_outline_rounded,       'label': 'Users'},
    {'icon': Icons.settings_outlined,            'label': 'Settings'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final restaurants = await ApiService.getPendingRestaurants(token: auth.token);
      if (mounted) {
        setState(() {
          _pendingCount = restaurants.length;
          _loadingCount = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingCount = false);
    }
  }

  void _updatePendingCount() {
    _loadPendingCount();
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0: return _OverviewPage(pendingCount: _pendingCount);
      case 1: return _ApprovalsPage(onApprovalChanged: _updatePendingCount);
      case 2: return const _RiderDeskPage();
      case 3: return const _UsersPage();
      case 4: return const _AdminSettingsPage();
      default: return _OverviewPage(pendingCount: _pendingCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide     = MediaQuery.of(context).size.width > 700;
    final theme      = Provider.of<ThemeProvider>(context);
    final bg         = AppColors.bg(context);
    final surf       = AppColors.surface(context);
    final border     = AppColors.border(context);
    final textPri    = AppColors.textPrimary(context);
    final textHint   = AppColors.textHint(context);
    final auth       = Provider.of<AuthProvider>(context);

    Widget sidebar = Container(
      width: 220,
      decoration: BoxDecoration(
        color: surf,
        border: Border(right: BorderSide(color: border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Brand header ─────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.fastfood_rounded,
                      color: Colors.black, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FindFood',
                        style: TextStyle(
                            color: textPri,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 0.3)),
                    Text('Admin HQ',
                        style: TextStyle(
                            color: AppTheme.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),

          Divider(color: border, height: 1),
          const SizedBox(height: 10),

          // ── Nav items ────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: List.generate(_navItems.length, (i) {
                  final item   = _navItems[i];
                  final active = _selectedIndex == i;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedIndex = i);
                      if (!isWide) Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: active
                            ? AppTheme.accent.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: active
                            ? Border.all(
                                color: AppTheme.accent.withOpacity(0.25))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(item['icon'] as IconData,
                              size: 18,
                              color: active
                                  ? AppTheme.accent
                                  : textHint),
                          const SizedBox(width: 12),
                          Text(item['label'] as String,
                              style: TextStyle(
                                color: active
                                    ? AppTheme.accent
                                    : textHint,
                                fontWeight: active
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                fontSize: 14,
                              )),
                          if (i == 1) ...[
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.danger.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(_pendingCount.toString(),
                                  style: const TextStyle(
                                      color: AppTheme.danger,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          Divider(color: border, height: 1),

          // ── Bottom section ───────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Theme toggle
                GestureDetector(
                  onTap: theme.toggle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          theme.isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          size: 17, color: AppTheme.accent,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          theme.isDark ? 'Light mode' : 'Dark mode',
                          style: TextStyle(
                              color: textPri,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Sign out
                GestureDetector(
                  onTap: () {
                    auth.logout();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.danger.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.logout_rounded,
                            size: 17, color: AppTheme.danger),
                        const SizedBox(width: 10),
                        const Text('Sign out',
                            style: TextStyle(
                                color: AppTheme.danger,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isWide) {
      return Scaffold(
        backgroundColor: bg,
        body: Row(
          children: [
            sidebar,
            Expanded(child: SafeArea(child: _buildPage())),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surf,
        title: Text(_navItems[_selectedIndex]['label'] as String),
        actions: [
          IconButton(
            icon: Icon(theme.isDark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
                color: AppTheme.accent),
            onPressed: theme.toggle,
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: surf,
        child: sidebar,
      ),
      body: SafeArea(child: _buildPage()),
    );
  }
}

// ─── OVERVIEW ─────────────────────────────────────────────────────────────────
class _OverviewPage extends StatelessWidget {
  final int pendingCount;
  
  const _OverviewPage({this.pendingCount = 0});

  @override
  Widget build(BuildContext context) {
    final textPri = AppColors.textPrimary(context);
    final textSec = AppColors.textSecondary(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Overview',
                      style: TextStyle(
                          color: textPri,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 2),
                  Text('Sunday, June 21 · Live data',
                      style: TextStyle(color: textSec, fontSize: 13)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(
                          color: AppTheme.success,
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    const Text('All systems online',
                        style: TextStyle(
                            color: AppTheme.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Stat cards
          LayoutBuilder(builder: (ctx, constraints) {
            final w = (constraints.maxWidth - 42) / 4;
            return Row(
              children: [
                _statCard(context, 'Total Orders', '1,284',
                    '+12% today', Icons.receipt_long_rounded,
                    AppTheme.accent, w),
                const SizedBox(width: 14),
                _statCard(context, 'Active Riders', '34',
                    '6 on delivery', Icons.electric_bike_rounded,
                    AppTheme.success, w),
                const SizedBox(width: 14),
                _statCard(context, 'Restaurants', '58',
                    '${pendingCount} pending', Icons.storefront_rounded,
                    AppTheme.warning, w),
                const SizedBox(width: 14),
                _statCard(context, 'Revenue Today', 'GH₵ 12,440',
                    '+18% vs yesterday', Icons.payments_rounded,
                    const Color(0xFF8B5CF6), w),
              ],
            );
          }),
          const SizedBox(height: 28),

          // Recent activity
          Text('Recent activity',
              style: TextStyle(
                  color: textPri,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          ...[
            ('Order #2841 placed', 'customer@test.com', '2 min ago',
                Icons.receipt_outlined, AppTheme.accent),
            ('New rider registered', 'rider@test.com', '15 min ago',
                Icons.electric_bike_outlined, AppTheme.success),
            ('Restaurant applied', 'Kofi\'s Kitchen', '1 hr ago',
                Icons.storefront_outlined, AppTheme.warning),
            ('Payment received', 'GH₵ 83.00', '2 hr ago',
                Icons.payments_outlined, AppTheme.success),
          ].map((r) => _activityRow(
              context, r.$1, r.$2, r.$3, r.$4, r.$5)),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext ctx, String label, String value,
      String sub, IconData icon, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card(ctx),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(ctx)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Icon(Icons.trending_up_rounded,
                  color: AppTheme.success, size: 16),
            ],
          ),
          const SizedBox(height: 14),
          Text(value,
              style: TextStyle(
                  color: AppColors.textPrimary(ctx),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: AppColors.textSecondary(ctx),
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(sub,
              style: const TextStyle(
                  color: AppTheme.success,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _activityRow(BuildContext ctx, String title, String sub,
      String time, IconData icon, Color color) {
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
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: AppColors.textPrimary(ctx),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(sub,
                    style: TextStyle(
                        color: AppColors.textSecondary(ctx),
                        fontSize: 12)),
              ],
            ),
          ),
          Text(time,
              style: TextStyle(
                  color: AppColors.textHint(ctx), fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── APPROVALS ────────────────────────────────────────────────────────────────
class _ApprovalsPage extends StatefulWidget {
  final VoidCallback? onApprovalChanged;
  
  const _ApprovalsPage({this.onApprovalChanged});

  @override
  State<_ApprovalsPage> createState() => _ApprovalsPageState();
}

class _ApprovalsPageState extends State<_ApprovalsPage> {
  List<Restaurant> _pending = [];
  bool _loading = true;
  String _error = '';
  Set<int> _approvingIds = {};
  Set<int> _rejectingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final restaurants = await ApiService.getPendingRestaurants(token: auth.token);
      if (!mounted) return;
      setState(() => _pending = restaurants);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(Restaurant restaurant) async {
    setState(() => _approvingIds.add(restaurant.id));
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.approveRestaurant(
        restaurantId: restaurant.id,
        token: auth.token ?? '',
      );
      if (!mounted) return;
      setState(() => _pending.removeWhere((r) => r.id == restaurant.id));
      widget.onApprovalChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${restaurant.name} approved!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _approvingIds.remove(restaurant.id));
    }
  }

  Future<void> _reject(Restaurant restaurant) async {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Application?'),
        content: Text('Are you sure you want to reject ${restaurant.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectRestaurant(restaurant);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectRestaurant(Restaurant restaurant) async {
    setState(() => _rejectingIds.add(restaurant.id));
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.rejectRestaurant(
        restaurantId: restaurant.id,
        token: auth.token ?? '',
      );
      if (!mounted) return;
      setState(() => _pending.removeWhere((r) => r.id == restaurant.id));
      widget.onApprovalChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${restaurant.name} rejected.'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _rejectingIds.remove(restaurant.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPri = AppColors.textPrimary(context);
    final textSec = AppColors.textSecondary(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error, style: TextStyle(color: AppColors.textSecondary(context))),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Restaurant Approvals',
              style: TextStyle(
                  color: textPri, fontSize: 26,
                  fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text('Review and approve new restaurant registrations',
              style: TextStyle(color: textSec, fontSize: 13)),
          const SizedBox(height: 24),
          if (_pending.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Text('No pending restaurants to review.',
                  style: TextStyle(color: AppColors.textSecondary(context))),
            )
          else
            ..._pending.map((restaurant) => _approvalCard(
                context,
                restaurant,
                () => _approve(restaurant),
                () => _reject(restaurant),
                _approvingIds.contains(restaurant.id),
                _rejectingIds.contains(restaurant.id),
              )),
        ],
      ),
    );
  }

  Widget _approvalCard(
    BuildContext ctx,
    Restaurant restaurant,
    VoidCallback onApprove,
    VoidCallback onReject,
    bool isApproving,
    bool isRejecting,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card(ctx),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(ctx)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.warning.withOpacity(0.2)),
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: AppTheme.warning, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(restaurant.name,
                        style: TextStyle(
                            color: AppColors.textPrimary(ctx),
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    Text('${restaurant.cuisineType} · ${restaurant.address}',
                        style: TextStyle(
                            color: AppColors.textSecondary(ctx),
                            fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.warning.withOpacity(0.3)),
                ),
                child: Text('Pending',
                    style: TextStyle(
                        color: AppTheme.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 60),
            child: Row(
              children: [
                Icon(Icons.email_outlined,
                    size: 13, color: AppColors.textHint(ctx)),
                const SizedBox(width: 4),
                Text(restaurant.email,
                    style: TextStyle(
                        color: AppColors.textHint(ctx), fontSize: 12)),
                const Spacer(),
                Icon(Icons.location_on_outlined,
                    size: 13, color: AppColors.textHint(ctx)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(restaurant.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColors.textHint(ctx), fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: isApproving ? null : onApprove,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isApproving)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(AppTheme.success),
                            ),
                          )
                        else
                          const Icon(Icons.check_rounded,
                              color: AppTheme.success, size: 16),
                        const SizedBox(width: 6),
                        Text(isApproving ? 'Approving...' : 'Approve',
                            style: const TextStyle(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: isRejecting ? null : onReject,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.danger.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isRejecting)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(AppTheme.danger),
                            ),
                          )
                        else
                          const Icon(Icons.close_rounded,
                              color: AppTheme.danger, size: 16),
                        const SizedBox(width: 6),
                        Text(isRejecting ? 'Rejecting...' : 'Reject',
                            style: const TextStyle(
                                color: AppTheme.danger,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── RIDERS ───────────────────────────────────────────────────────────────────
class _RiderDeskPage extends StatelessWidget {
  const _RiderDeskPage();

  @override
  Widget build(BuildContext context) {
    final textPri = AppColors.textPrimary(context);
    final textSec = AppColors.textSecondary(context);
    final riders = [
      ('Kwame Asante', 'On delivery · #2841', AppTheme.accent, '7 today'),
      ('Ama Owusu',    'Available',            AppTheme.success, '5 today'),
      ('Kojo Mensah',  'Offline',              AppColors.textHint(context), '0 today'),
      ('Abena Sarpong','Available',            AppTheme.success, '9 today'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rider Fleet',
              style: TextStyle(
                  color: textPri, fontSize: 26,
                  fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text('${riders.length} registered riders',
              style: TextStyle(color: textSec, fontSize: 13)),
          const SizedBox(height: 24),
          ...riders.map((r) => _riderCard(
              context, r.$1, r.$2, r.$3, r.$4)),
        ],
      ),
    );
  }

  Widget _riderCard(BuildContext ctx, String name, String status,
      Color color, String deliveries) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(ctx),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(ctx)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.12),
            child: Text(name[0],
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        color: AppColors.textPrimary(ctx),
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(status,
                        style: TextStyle(color: color, fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface(ctx),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border(ctx)),
            ),
            child: Column(
              children: [
                Text(deliveries,
                    style: TextStyle(
                        color: AppColors.textPrimary(ctx),
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                Text('deliveries',
                    style: TextStyle(
                        color: AppColors.textHint(ctx),
                        fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── USERS ────────────────────────────────────────────────────────────────────
class _UsersPage extends StatefulWidget {
  const _UsersPage();

  @override
  State<_UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<_UsersPage> {
  List<AppUser> _users = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final users = await ApiService.getUsers(token: auth.token);
      if (!mounted) return;
      setState(() => _users = users);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return AppTheme.danger;
      case 'restaurant':
        return AppTheme.warning;
      case 'rider':
        return AppTheme.accent;
      default:
        return AppTheme.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPri = AppColors.textPrimary(context);
    final textSec = AppColors.textSecondary(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error, style: TextStyle(color: AppColors.textSecondary(context))),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('All Users',
                      style: TextStyle(
                          color: textPri, fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5)),
                  Text('${_users.length} registered accounts',
                      style: TextStyle(color: textSec, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12)),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3,
                    child: Text('Name',
                        style: TextStyle(
                            color: AppColors.textHint(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5))),
                Expanded(flex: 4,
                    child: Text('Email',
                        style: TextStyle(
                            color: AppColors.textHint(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5))),
                Expanded(flex: 2,
                    child: Text('Role',
                        style: TextStyle(
                            color: AppColors.textHint(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5))),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12)),
              border: Border(
                left: BorderSide(color: AppColors.border(context)),
                right: BorderSide(color: AppColors.border(context)),
                bottom: BorderSide(color: AppColors.border(context)),
              ),
            ),
            child: Column(
              children: _users.asMap().entries.map((entry) {
                final i = entry.key;
                final user = entry.value;
                final roleColor = _roleColor(user.role);
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: i < _users.length - 1
                        ? Border(
                            bottom: BorderSide(
                                color: AppColors.border(context)))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: roleColor.withOpacity(0.12),
                              child: Text(user.name.isNotEmpty ? user.name[0] : '?',
                                  style: TextStyle(
                                      color: roleColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(user.name,
                                  style: TextStyle(
                                      color: AppColors.textPrimary(context),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(user.email,
                            style: TextStyle(
                                color: AppColors.textSecondary(context),
                                fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(user.role,
                              style: TextStyle(
                                  color: roleColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SETTINGS ─────────────────────────────────────────────────────────────────
class _AdminSettingsPage extends StatelessWidget {
  const _AdminSettingsPage();

  @override
  Widget build(BuildContext context) {
    final textPri = AppColors.textPrimary(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings',
              style: TextStyle(
                  color: textPri, fontSize: 26,
                  fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 24),
          _section(context, 'Account', [
            _row(context, Icons.person_outline_rounded,
                'Edit profile', 'Update your admin details'),
            _row(context, Icons.lock_outline_rounded,
                'Change password', 'Update your password'),
          ]),
          const SizedBox(height: 20),
          _section(context, 'Platform', [
            _row(context, Icons.notifications_outlined,
                'Notifications', 'Manage alert preferences'),
            _row(context, Icons.policy_outlined,
                'Terms & policies', 'View platform policies'),
            _row(context, Icons.help_outline_rounded,
                'Help & support', 'Get help from our team'),
          ]),
        ],
      ),
    );
  }

  Widget _section(BuildContext ctx, String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(title,
              style: TextStyle(
                  color: AppColors.textHint(ctx),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card(ctx),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border(ctx)),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _row(BuildContext ctx, IconData icon, String label, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border(ctx)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface(ctx),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                color: AppColors.textSecondary(ctx), size: 17),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: AppColors.textPrimary(ctx),
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                Text(sub,
                    style: TextStyle(
                        color: AppColors.textHint(ctx),
                        fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              color: AppColors.textHint(ctx), size: 13),
        ],
      ),
    );
  }
}