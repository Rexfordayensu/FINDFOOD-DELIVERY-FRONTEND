import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/providers.dart';
import '../auth/login_screen.dart';
import 'menu_detail_screen.dart';
import 'cart_screen.dart';
import '../../widgets/greeting_header.dart';

// ── Cuisine config with real Unsplash food images ────────────────────────────
const _cuisineData = {
  'ghanaian':  {
    'image': 'https://images.unsplash.com/photo-1604329760661-e71dc83f8f26?w=800&q=80',
    'colors': [Color(0xFF7B1400), Color(0xFFD4380D)],
  },
  'local':     {
    'image': 'https://images.unsplash.com/photo-1604329760661-e71dc83f8f26?w=800&q=80',
    'colors': [Color(0xFF7B1400), Color(0xFFD4380D)],
  },
  'pizza':     {
    'image': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800&q=80',
    'colors': [Color(0xFF0D2E6B), Color(0xFF1565C0)],
  },
  'italian':   {
    'image': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800&q=80',
    'colors': [Color(0xFF0D2E6B), Color(0xFF1565C0)],
  },
  'chinese':   {
    'image': 'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=800&q=80',
    'colors': [Color(0xFF0A3D1F), Color(0xFF2E7D32)],
  },
  'fast food': {
    'image': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&q=80',
    'colors': [Color(0xFF3E1A00), Color(0xFFBF5600)],
  },
  'burger':    {
    'image': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&q=80',
    'colors': [Color(0xFF3E1A00), Color(0xFFBF5600)],
  },
  'seafood':   {
    'image': 'https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?w=800&q=80',
    'colors': [Color(0xFF003459), Color(0xFF0077B6)],
  },
  'default':   {
    'image': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80',
    'colors': [Color(0xFF1A1A2E), Color(0xFF16213E)],
  },
};

Map<String, dynamic> _cuisineFor(String c) {
  final lower = c.toLowerCase();
  for (final k in _cuisineData.keys) {
    if (lower.contains(k)) return _cuisineData[k]!;
  }
  return _cuisineData['default']!;
}
String _imageFor(dynamic r) {
  String cuisine = '';
  String? imageUrl;

  if (r is Map) {
    imageUrl = r['image_url']?.toString();
    cuisine = r['cuisine_type']?.toString() ?? '';
  } else if (r != null) {
    try {
      imageUrl = (r as dynamic).imageUrl?.toString();
      cuisine = (r as dynamic).cuisineType?.toString() ?? '';
    } catch (_) {}
  }

  // 1. Prioritize uploaded backend image
  if (imageUrl != null && imageUrl.trim().isNotEmpty) {
    return getFullImageUrl(imageUrl);
  }

  // 2. Fallback to cuisine stock photos if image_url is null/empty
  final data = _cuisineFor(cuisine);
  return data['image'] ?? _cuisineData['default']!['image']!;
}

// ── Demo data ─────────────────────────────────────────────────────────────────
final _demoRestaurants = [
  Restaurant(id: -1, name: "Mama's Kitchen",  cuisineType: 'Local Ghanaian',   address: 'Osu, Accra',         email: '', isActive: true,  isApproved: true, ownerId: 0),
  Restaurant(id: -2, name: 'Burger Republic', cuisineType: 'Fast Food',        address: 'Airport City, Accra', email: '', isActive: true,  isApproved: true, ownerId: 0),
  Restaurant(id: -3, name: 'Dragon Palace',   cuisineType: 'Chinese',          address: 'East Legon, Accra',  email: '', isActive: true,  isApproved: true, ownerId: 0),
  Restaurant(id: -4, name: "Auntie Ama's",    cuisineType: 'Local Ghanaian',   address: 'Cantonments, Accra', email: '', isActive: false, isApproved: true, ownerId: 0),
  Restaurant(id: -5, name: 'Pizzeria Roma',   cuisineType: 'Italian / Pizza',  address: 'Labone, Accra',      email: '', isActive: true,  isApproved: true, ownerId: 0),
  Restaurant(id: -6, name: 'Ocean Catch',     cuisineType: 'Seafood',          address: 'Tema, Accra',        email: '', isActive: true,  isApproved: true, ownerId: 0),
];

// ── Main screen ───────────────────────────────────────────────────────────────
String getFullImageUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  return 'http://localhost:8000$url';
}

class FoodFeedScreen extends StatefulWidget {
  const FoodFeedScreen({super.key});
  @override
  State<FoodFeedScreen> createState() => _FoodFeedScreenState();
}

class _FoodFeedScreenState extends State<FoodFeedScreen>
    with TickerProviderStateMixin {
  List<Restaurant> _restaurants = [];
  List<Restaurant> _filtered    = [];
  bool   _loading  = true;
  String _error    = '';
  String _search   = '';
  String _filter   = 'All';
  int    _navIndex = 0;

  final _filters    = ['All', 'Ghanaian', 'Fast food', 'Pizza', 'Chinese', 'Seafood'];
  final _searchCtrl = TextEditingController();

  // Stagger animation controller
  late AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _load();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final list = await ApiService.getRestaurants();
      final ids  = list.map((r) => r.id).toSet();
      final extra = _demoRestaurants.where((d) => !ids.contains(d.id)).toList();
      setState(() { _restaurants = [...list, ...extra]; _applyFilter(); });
      _staggerCtrl.forward(from: 0);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    _filtered = _restaurants.where((r) {
      final ms = _search.isEmpty ||
          r.name.toLowerCase().contains(_search.toLowerCase()) ||
          r.cuisineType.toLowerCase().contains(_search.toLowerCase());
      final mf = _filter == 'All' ||
          r.cuisineType.toLowerCase().contains(_filter.toLowerCase());
      return ms && mf;
    }).toList();
    if (mounted) _staggerCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final auth    = Provider.of<AuthProvider>(context);
    final cart    = Provider.of<CartProvider>(context);
    final themeP  = Provider.of<ThemeProvider>(context);
    final bg      = AppColors.bg(context);
    final surf    = AppColors.surface(context);
    final border  = AppColors.border(context);
    final textPri = AppColors.textPrimary(context);
    final textSec = AppColors.textSecondary(context);
    final textHint= AppColors.textHint(context);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ────────────────────────────────────────
            _Header(
              auth: auth, cart: cart, themeP: themeP,
              textPri: textPri, textSec: textSec,
              textHint: textHint, surf: surf, border: border,
              searchCtrl: _searchCtrl,
              onSearch: (v) => setState(() { _search = v; _applyFilter(); }),
            ),

            // ── FILTER CHIPS ──────────────────────────────────
            _FilterRow(
              filters: _filters, selected: _filter,
              surf: surf, border: border,
              textSec: textSec,
              onSelect: (f) => setState(() { _filter = f; _applyFilter(); }),
            ),
            const SizedBox(height: 8),

            // ── BODY ──────────────────────────────────────────
            Expanded(
              child: _loading
                  ? _LoadingShimmer(bg: surf, border: border)
                  : _error.isNotEmpty
                      ? EmptyState(
                          icon: Icons.wifi_off_rounded,
                          title: 'Connection failed',
                          subtitle: _error,
                          actionLabel: 'Retry',
                          onAction: _load,
                        )
                      : _filtered.isEmpty
                          ? EmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'Nothing found',
                              subtitle: 'Try different filters.',
                              actionLabel: 'Clear',
                              onAction: () => setState(() {
                                _filter = 'All'; _search = '';
                                _searchCtrl.clear(); _applyFilter();
                              }),
                            )
                          : RefreshIndicator(
                              color: AppTheme.accent,
                              onRefresh: _load,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                                itemCount: _filtered.length + 1,
                                itemBuilder: (_, i) {
                                  if (i == 0) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 14),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('All restaurants',
                                              style: TextStyle(
                                                  color: textPri,
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w700)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppTheme.accent.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                                '${_filtered.length} places',
                                                style: const TextStyle(
                                                    color: AppTheme.accent,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700)),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  final r   = _filtered[i - 1];
                                  final del = Duration(milliseconds: 80 * (i - 1));
                                  return _AnimatedCard(
                                    key: ValueKey(r.id),
                                    delay: del,
                                    ctrl: _staggerCtrl,
                                    child: _RestaurantCard(
                                      restaurant: r,
                                      isDemo: r.id < 0,
                                      onTap: r.id < 0
                                          ? () => _showComingSoon(context, r)
                                          : () => Navigator.push(context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      MenuDetailScreen(restaurant: r))),
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),

      // ── BOTTOM NAV ────────────────────────────────────────────
      bottomNavigationBar: _BottomNav(
        index: _navIndex,
        cartCount: cart.itemCount,
        onTap: (i) {
          if (i == 2) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CartScreen()));
            return;
          }
          if (i == 4) {
            if (auth.isLoggedIn) {
              _showProfileSheet(context, auth, themeP);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(
                    returnRoute: '/home',
                    pendingAction: 'browse_menu',
                  ),
                ),
              );
            }
            return;
          }
          setState(() => _navIndex = i);
        },
        textHint: textHint,
        surf: surf,
        border: border,
      ),
    );
  }

  void _showComingSoon(BuildContext context, Restaurant r) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront_rounded,
                  color: AppTheme.accent, size: 32),
            ),
            const SizedBox(height: 16),
            Text(r.name,
                style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'This restaurant is coming soon\nto FINDFOOD. Check back shortly!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showProfileSheet(BuildContext ctx, AuthProvider auth,
      ThemeProvider themeP) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.card(ctx),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border(ctx),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 34,
              backgroundColor: AppTheme.accentDim,
              child: Text(
                (auth.role ?? 'U')[0].toUpperCase(),
                style: const TextStyle(color: AppTheme.accent,
                    fontSize: 26, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 12),
            Text(auth.role?.toUpperCase() ?? 'USER',
                style: TextStyle(color: AppColors.textPrimary(ctx),
                    fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(auth.role ?? '',
                  style: const TextStyle(color: AppTheme.accent,
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 28),
            // Theme toggle
            _SheetBtn(
              icon: themeP.isDark
                  ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              label: themeP.isDark ? 'Switch to light mode' : 'Switch to dark mode',
              color: AppTheme.accent,
              onTap: () { Navigator.pop(ctx); themeP.toggle(); },
            ),
            const SizedBox(height: 10),
            _SheetBtn(
              icon: Icons.logout_rounded,
              label: 'Sign out',
              color: AppTheme.danger,
              onTap: () { Navigator.pop(ctx); auth.logout(); },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── HEADER ───────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final AuthProvider auth;
  final CartProvider cart;
  final ThemeProvider themeP;
  final Color textPri, textSec, textHint, surf, border;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;

  const _Header({
    required this.auth, required this.cart, required this.themeP,
    required this.textPri, required this.textSec, required this.textHint,
    required this.surf, required this.border,
    required this.searchCtrl, required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg(context),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.fastfood_rounded,
                    color: Colors.black, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FINDFOOD',
                      style: TextStyle(color: textPri,
                          fontWeight: FontWeight.w900, fontSize: 16,
                          letterSpacing: 0.4)),
                  Row(children: [
                    const Icon(Icons.location_on_rounded,
                        color: AppTheme.accent, size: 11),
                    const SizedBox(width: 2),
                    Text('East Legon, Accra',
                        style: TextStyle(color: textSec, fontSize: 11)),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        color: textHint, size: 14),
                  ]),
                ],
              ),
              const Spacer(),
              _IconBtn(
                icon: themeP.isDark
                    ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                color: textPri, bg: surf, border: border,
                onTap: themeP.toggle, tooltip: 'Toggle theme',
              ),
              const SizedBox(width: 8),
              _IconBtn(
                icon: Icons.shopping_bag_outlined,
                color: textPri, bg: surf, border: border,
                badge: cart.itemCount,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CartScreen())),
                tooltip: 'Cart',
              ),
              const SizedBox(width: 8),
              _IconBtn(
                icon: auth.isLoggedIn
                    ? Icons.account_circle_rounded : Icons.login_rounded,
                color: auth.isLoggedIn ? AppTheme.accent : textPri,
                bg: auth.isLoggedIn ? AppTheme.accentDim : surf,
                border: auth.isLoggedIn
                    ? AppTheme.accent.withValues(alpha: 0.3) : border,
                onTap: () {
                  if (!auth.isLoggedIn) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(
                          returnRoute: '/home',
                          pendingAction: 'sign_in',
                        ),
                      ),
                    );
                  }
                },
                tooltip: auth.isLoggedIn ? 'Profile' : 'Sign in',
              ),
            ],
          ),
          // Personalized greeting — only shown when signed in
          if (auth.isLoggedIn && (auth.name ?? '').isNotEmpty)
            GreetingHeader(
              name: auth.name!,
              role: auth.role ?? 'customer',
              padding: const EdgeInsets.only(top: 14, bottom: 2),
            ),
          const SizedBox(height: 12),
          // Animated search bar
          _AnimatedSearchBar(
            controller: searchCtrl,
            textPri: textPri, textHint: textHint,
            surf: surf, border: border,
            onChanged: onSearch,
          ),
        ],
      ),
    );
  }
}

// ─── ANIMATED SEARCH BAR ─────────────────────────────────────────────────────
class _AnimatedSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Color textPri, textHint, surf, border;
  final ValueChanged<String> onChanged;

  const _AnimatedSearchBar({
    required this.controller, required this.textPri,
    required this.textHint, required this.surf,
    required this.border, required this.onChanged,
  });

  @override
  State<_AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<_AnimatedSearchBar> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 46,
      decoration: BoxDecoration(
        color: widget.surf,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _focused ? AppTheme.accent : widget.border,
          width: _focused ? 1.5 : 1,
        ),
        boxShadow: _focused
            ? [BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.12),
                blurRadius: 12, offset: const Offset(0, 3))]
            : [],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _focused ? Icons.search_rounded : Icons.search_outlined,
              color: _focused ? AppTheme.accent : widget.textHint,
              size: 18, key: ValueKey(_focused),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Focus(
              onFocusChange: (f) => setState(() => _focused = f),
              child: TextField(
                controller: widget.controller,
                style: TextStyle(color: widget.textPri, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search restaurants or dishes...',
                  hintStyle: TextStyle(color: widget.textHint, fontSize: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                onChanged: widget.onChanged,
              ),
            ),
          ),
          if (widget.controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                widget.controller.clear();
                widget.onChanged('');
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(Icons.close_rounded,
                    color: widget.textHint, size: 15),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── FILTER ROW ───────────────────────────────────────────────────────────────
class _FilterRow extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final Color surf, border, textSec;
  final ValueChanged<String> onSelect;

  const _FilterRow({
    required this.filters, required this.selected,
    required this.surf, required this.border,
    required this.textSec, required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f      = filters[i];
          final active = selected == f;
          return GestureDetector(
            onTap: () => onSelect(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: active ? AppTheme.accent : surf,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: active ? AppTheme.accent : border),
                boxShadow: active
                    ? [BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.25),
                        blurRadius: 8, offset: const Offset(0, 3))]
                    : [],
              ),
              child: Text(f,
                  style: TextStyle(
                    color: active ? Colors.black : textSec,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 13,
                  )),
            ),
          );
        },
      ),
    );
  }
}

// ─── ANIMATED CARD WRAPPER ────────────────────────────────────────────────────
class _AnimatedCard extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final AnimationController ctrl;

  const _AnimatedCard({
    super.key,
    required this.child,
    required this.delay,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final start = (delay.inMilliseconds / 900).clamp(0.0, 0.85);
        final end   = (start + 0.35).clamp(0.0, 1.0);
        final t     = CurvedAnimation(
          parent: ctrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );
        return Transform.translate(
          offset: Offset(0, 30 * (1 - t.value)),
          child: Opacity(opacity: t.value.clamp(0.0, 1.0), child: child),
        );
      },
    );
  }
}

// ─── RESTAURANT CARD WITH HOVER ───────────────────────────────────────────────
class _RestaurantCard extends StatefulWidget {
  final Restaurant restaurant;
  final VoidCallback? onTap;
  final bool isDemo;

  const _RestaurantCard({
    required this.restaurant,
    this.onTap,
    this.isDemo = false,
  });

  @override
  State<_RestaurantCard> createState() => _RestaurantCardState();
}

class _RestaurantCardState extends State<_RestaurantCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
        CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _pressCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final r       = widget.restaurant;
    final data     = _cuisineFor(r.cuisineType);
    final imageUrl = data['image'] as String;
    final colors   = data['colors'] as List<Color>;
    final card    = AppColors.card(context);
    final border  = AppColors.border(context);
    final textPri = AppColors.textPrimary(context);
    final textSec = AppColors.textSecondary(context);
    final textHint= AppColors.textHint(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: (_) => _pressCtrl.forward(),
          onTapUp:   (_) { _pressCtrl.reverse(); widget.onTap?.call(); },
          onTapCancel: ()  => _pressCtrl.reverse(),
          child: ScaleTransition(
            scale: _scaleAnim,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: _hovered
                        ? AppTheme.accent.withValues(alpha: 0.4) : border,
                    width: _hovered ? 1.5 : 1),
                boxShadow: [
                  BoxShadow(
                    color: _hovered
                        ? AppTheme.accent.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.06),
                    blurRadius: _hovered ? 20 : 10,
                    offset: Offset(0, _hovered ? 6 : 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Banner ──────────────────────────────────
                  Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: _hovered ? 158 : 148,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(18)),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(18)),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Real food image
                              Image.network(
                                _imageFor(r), // Uses backend URL if available, else falls back to Unsplash
                                key: ValueKey(r.id),
                                fit: BoxFit.cover,
                                loadingBuilder: (_, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: colors,
                                      ),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                          color: AppTheme.accent,
                                          strokeWidth: 2),
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: colors,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.restaurant_rounded,
                                        color: Colors.white54, size: 48),
                                  ),
                                ),
                              ),
                              // Dark gradient overlay so text stays readable
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: _hovered ? 0.15 : 0.05),
                                      Colors.black.withValues(alpha: _hovered ? 0.55 : 0.35),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Status badge
                      Positioned(
                        top: 12, right: 12,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(20),
                            border: r.isActive
                                ? Border.all(
                                    color: AppTheme.success.withValues(alpha: 0.4))
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6, height: 6,
                                decoration: BoxDecoration(
                                  color: r.isActive
                                      ? AppTheme.success : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(r.isActive ? 'Open' : 'Closed',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                      // Demo badge
                      if (r.id < 0)
                        Positioned(
                          top: 12, left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Featured',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                      // Hover arrow CTA
                      if (_hovered && widget.onTap != null)
                        Positioned(
                          bottom: 12, right: 12,
                          child: AnimatedOpacity(
                            opacity: _hovered ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppTheme.accent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.black, size: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // ── Info ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(r.name,
                                  style: TextStyle(
                                      color: textPri,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.star_rounded,
                                color: AppTheme.accent, size: 14),
                            const SizedBox(width: 3),
                            const Text('4.8',
                                style: TextStyle(
                                    color: AppTheme.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                            Text(' (120+)',
                                style: TextStyle(
                                    color: textHint, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(r.cuisineType,
                            style: TextStyle(color: textSec, fontSize: 13)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded,
                                color: textHint, size: 13),
                            const SizedBox(width: 3),
                            Text('25–35 min',
                                style: TextStyle(
                                    color: textHint, fontSize: 12)),
                            const SizedBox(width: 10),
                            Icon(Icons.location_on_outlined,
                                color: textHint, size: 13),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(r.address,
                                  style: TextStyle(
                                      color: textHint, fontSize: 12),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Pills row
                        Row(
                          children: [
                            const _Pill('Free delivery', AppTheme.success),
                            const SizedBox(width: 8),
                            _Pill('Min GH₵ 20', textHint),
                          ],
                        ),
                        // CTA button — full width, always visible
                        if (widget.onTap != null) ...[
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: widget.onTap,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                color: AppTheme.accent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accent.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_basket_rounded,
                                      color: Colors.black, size: 16),
                                  SizedBox(width: 8),
                                  Text('Order now',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      )),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── PILL TAG ─────────────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(label,
          style: TextStyle(color: color,
              fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── ICON BUTTON ─────────────────────────────────────────────────────────────
class _IconBtn extends StatefulWidget {
  final IconData icon;
  final Color color, bg, border;
  final int badge;
  final VoidCallback onTap;
  final String tooltip;

  const _IconBtn({
    required this.icon, required this.color,
    required this.bg, required this.border,
    this.badge = 0,
    required this.onTap, required this.tooltip,
  });

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: _hovered
                      ? AppTheme.accent.withValues(alpha: 0.15)
                      : widget.bg,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                      color: _hovered
                          ? AppTheme.accent.withValues(alpha: 0.4)
                          : widget.border),
                ),
                child: Icon(widget.icon, color: widget.color, size: 19),
              ),
              if (widget.badge > 0)
                Positioned(
                  top: -4, right: -4,
                  child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(
                        color: AppTheme.accent, shape: BoxShape.circle),
                    child: Center(
                      child: Text('${widget.badge}',
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── BOTTOM NAV ───────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int index, cartCount;
  final ValueChanged<int> onTap;
  final Color textHint, surf, border;

  const _BottomNav({
    required this.index, required this.cartCount,
    required this.onTap, required this.textHint,
    required this.surf, required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded,          Icons.home_outlined,          'Home'),
      (Icons.search_rounded,        Icons.search_outlined,        'Search'),
      (Icons.shopping_bag_rounded,  Icons.shopping_bag_outlined,  'Cart'),
      (Icons.receipt_long_rounded,  Icons.receipt_long_outlined,  'Orders'),
      (Icons.person_rounded,        Icons.person_outline_rounded, 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
          color: surf,
          border: Border(top: BorderSide(color: border))),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final active = index == i;
              final item   = items[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.all(active ? 6 : 0),
                              decoration: BoxDecoration(
                                color: active
                                    ? AppTheme.accent.withValues(alpha: 0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                active ? item.$1 : item.$2,
                                color: active
                                    ? AppTheme.accent : textHint,
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 2),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                color: active ? AppTheme.accent : textHint,
                                fontSize: 10,
                                fontWeight: active
                                    ? FontWeight.w700 : FontWeight.w400,
                              ),
                              child: Text(item.$3),
                            ),
                          ],
                        ),
                        if (i == 2 && cartCount > 0)
                          Positioned(
                            top: 8, right: 20,
                            child: Container(
                              width: 14, height: 14,
                              decoration: const BoxDecoration(
                                  color: AppTheme.accent,
                                  shape: BoxShape.circle),
                              child: Center(
                                child: Text('$cartCount',
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── PROFILE SHEET BUTTON ─────────────────────────────────────────────────────
class _SheetBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SheetBtn({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

// ─── LOADING SHIMMER ─────────────────────────────────────────────────────────
class _LoadingShimmer extends StatefulWidget {
  final Color bg, border;
  const _LoadingShimmer({required this.bg, required this.border});

  @override
  State<_LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<_LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: widget.bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: widget.border),
          ),
          child: Column(
            children: [
              Container(
                height: 148,
                decoration: BoxDecoration(
                  color: Color.lerp(widget.bg,
                      widget.border, 0.3 + 0.3 * _anim.value),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(160, 16, widget.bg, widget.border, _anim.value),
                    const SizedBox(height: 8),
                    _shimmerBox(100, 12, widget.bg, widget.border, _anim.value),
                    const SizedBox(height: 10),
                    _shimmerBox(double.infinity, 10,
                        widget.bg, widget.border, _anim.value),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox(double w, double h,
      Color bg, Color border, double t) {
    return Container(
      width: w, height: h,
      decoration: BoxDecoration(
        color: Color.lerp(bg, border, 0.3 + 0.3 * t),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}