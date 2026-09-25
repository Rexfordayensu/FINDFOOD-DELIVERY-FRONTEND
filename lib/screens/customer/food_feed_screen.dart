import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/providers.dart';
import '../../services/local_customer_store.dart';
import 'menu_detail_screen.dart';
import '../../widgets/greeting_header.dart';

// ── Cuisine colors used for image-free restaurant cards ──────────────────────
const _cuisineData = {
  'ghanaian':  {
    'colors': [Color(0xFF7B1400), Color(0xFFD4380D)],
  },
  'local':     {
    'colors': [Color(0xFF7B1400), Color(0xFFD4380D)],
  },
  'pizza':     {
    'colors': [Color(0xFF0D2E6B), Color(0xFF1565C0)],
  },
  'italian':   {
    'colors': [Color(0xFF0D2E6B), Color(0xFF1565C0)],
  },
  'chinese':   {
    'colors': [Color(0xFF0A3D1F), Color(0xFF2E7D32)],
  },
  'fast food': {
    'colors': [Color(0xFF3E1A00), Color(0xFFBF5600)],
  },
  'burger':    {
    'colors': [Color(0xFF3E1A00), Color(0xFFBF5600)],
  },
  'seafood':   {
    'colors': [Color(0xFF003459), Color(0xFF0077B6)],
  },
  'default':   {
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
String? _imageFor(dynamic r) {
  String? imageUrl;

  if (r is Map) {
    imageUrl = r['banner_url']?.toString() ?? r['image_url']?.toString();
  } else if (r != null) {
    try {
        imageUrl = (r as dynamic).bannerUrl?.toString() ??
          (r as dynamic).imageUrl?.toString();
    } catch (_) {}
  }

  if (imageUrl != null && imageUrl.trim().isNotEmpty) {
    return getFullImageUrl(imageUrl);
  }
  return null;
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
  return 'https://findfooddelivery-backend.onrender.com/$url';
}

class FoodFeedScreen extends StatefulWidget {
  const FoodFeedScreen({super.key, this.initialNavIndex = 0});

  final int initialNavIndex;

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
  String _sortBy   = 'recommended';
  Set<int> _favoriteIds = {};
  List<int> _recentIds = [];
  List<String> _recentSearches = [];
  int    _navIndex = 0;

  final _filters    = ['All', 'Ghanaian', 'Fast food', 'Pizza', 'Chinese', 'Seafood'];
  final _searchCtrl = TextEditingController();

  // Stagger animation controller
  late AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _navIndex = widget.initialNavIndex;
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _restoreLocalState();
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

  Future<void> _restoreLocalState() async {
    final favorites = await LocalCustomerStore.favoriteRestaurantIds();
    final recentIds = await LocalCustomerStore.recentlyViewedIds();
    final searches = await LocalCustomerStore.recentSearches();
    if (!mounted) return;
             setState(() {
      _favoriteIds = favorites.toSet();
      _recentIds = recentIds.toList();
      _recentSearches = searches;
    });
    _applyFilter();
  }

  void _applyFilter() {
    final matching = _restaurants.where((r) {
      final ms = _search.isEmpty ||
          r.name.toLowerCase().contains(_search.toLowerCase()) ||
          r.cuisineType.toLowerCase().contains(_search.toLowerCase());
      final mf = _filter == 'All' ||
          r.cuisineType.toLowerCase().contains(_filter.toLowerCase());
      return ms && mf;
    }).toList();
    if (_sortBy == 'name') {
      matching.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_sortBy == 'available') {
      matching.sort((a, b) => (b.isActive ? 1 : 0).compareTo(a.isActive ? 1 : 0));
    } else if (_sortBy == 'recent') {
      matching.sort((a, b) => _recentPosition(a.id).compareTo(_recentPosition(b.id)));
    }
    _filtered = matching;
    if (mounted) _staggerCtrl.forward(from: 0);
  }

  int _recentPosition(int id) {
    final position = _recentIds.indexOf(id);
    return position == -1 ? _recentIds.length + 1 : position;
  }

  Future<void> _toggleFavorite(Restaurant restaurant) async {
    await LocalCustomerStore.toggleFavorite(restaurant.id);
    if (!mounted) return;
    setState(() {
      if (!_favoriteIds.add(restaurant.id)) _favoriteIds.remove(restaurant.id);
    });
  }

  Future<void> _rememberViewed(Restaurant restaurant) async {
    await LocalCustomerStore.addRecentlyViewed(restaurant.id);
    if (!mounted) return;
    setState(() {
      _recentIds.remove(restaurant.id);
      _recentIds.insert(0, restaurant.id);
    });
  }

  Future<void> _rememberSearch(String value) async {
    final query = value.trim();
    if (query.length < 2) return;
    await LocalCustomerStore.addSearch(query);
    if (!mounted) return;
    setState(() {
      _recentSearches.removeWhere(
          (item) => item.toLowerCase() == query.toLowerCase());
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 8) _recentSearches.removeLast();
    });
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
              recentSearches: _recentSearches,
              onSearch: (v) {
                setState(() { _search = v; _applyFilter(); });
                _rememberSearch(v);
              },
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
                                          Expanded(
                                            child: Text('All restaurants',
                                                style: TextStyle(
                                                  color: textPri,
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w700)),
                                          ),
                                          _SortButton(
                                            selected: _sortBy,
                                            onChanged: (value) => setState(() {
                                              _sortBy = value;
                                              _applyFilter();
                                            }),
                                          ),
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
                                        isFavorite: _favoriteIds.contains(r.id),
                                        onFavorite: () => _toggleFavorite(r),
                                      onTap: r.id < 0
                                          ? () {
                                            _rememberViewed(r);
                                            _showComingSoon(context, r);
                                          }
                                          : () {
                                            _rememberViewed(r);
                                            Navigator.push(context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                  MenuDetailScreen(restaurant: r)));
                                          },
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
          switch (i) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/search');
              break;
            case 2:
              context.go('/cart');
              break;
            case 3:
              context.go('/orders');
              break;
            case 4:
              if (auth.isLoggedIn) {
                _showProfileSheet(context, auth, themeP);
              } else {
                context.go('/login');
              }
              break;
          }
          if (i >= 0 && i <= 3) {
            setState(() => _navIndex = i);
          }
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
              onTap: () async {
                Navigator.pop(ctx);
                if (!await confirmLogout(context) || !mounted) return;
                await auth.logout();
                if (!mounted) return;
                showLogoutSuccess(context);
                context.go('/');
              },
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
  final List<String> recentSearches;
  final ValueChanged<String> onSearch;

  const _Header({
    required this.auth, required this.cart, required this.themeP,
    required this.textPri, required this.textSec, required this.textHint,
    required this.surf, required this.border,
    required this.searchCtrl, required this.recentSearches,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg(context),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]),
                child: const Icon(Icons.fastfood_rounded,
                  color: Colors.black, size: 19),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FINDFOOD',
                      style: TextStyle(color: textPri,
                        fontFamily: 'Georgia',
                        fontWeight: FontWeight.w700, fontSize: 14,
                        letterSpacing: 0.6)),
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
                onTap: () => context.go('/cart'),
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
                    context.go('/login');
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
              padding: const EdgeInsets.only(top: 12, bottom: 0),
            ),
          const SizedBox(height: 10),
          // Animated search bar
          _AnimatedSearchBar(
            controller: searchCtrl,
            textPri: textPri, textHint: textHint,
            surf: surf, border: border,
            onChanged: onSearch,
          ),
          if (recentSearches.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 26,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recentSearches.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () {
                    searchCtrl.text = recentSearches[i];
                    onSearch(recentSearches[i]);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: surf.withValues(alpha: 0.62),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: border.withValues(alpha: 0.7)),
                    ),
                    child: Text(recentSearches[i],
                        style: TextStyle(color: textSec, fontSize: 11)),
                  ),
                ),
              ),
            ),
          ],
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
      height: 44,
      decoration: BoxDecoration(
        color: widget.surf.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _focused
              ? AppTheme.accent
              : widget.border.withValues(alpha: 0.72),
          width: _focused ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          if (_focused)
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.14),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
        ],
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
                color: active
                  ? AppTheme.accent.withValues(alpha: 0.92)
                  : surf.withValues(alpha: 0.68),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                    ? AppTheme.accent
                    : border.withValues(alpha: 0.7)),
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

class _SortButton extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _SortButton({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: selected,
      onSelected: onChanged,
      tooltip: 'Sort restaurants',
      padding: EdgeInsets.zero,
      icon: Icon(Icons.tune_rounded,
          color: AppColors.textSecondary(context), size: 19),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'recommended', child: Text('Recommended')),
        PopupMenuItem(value: 'recent', child: Text('Recently viewed')),
        PopupMenuItem(value: 'available', child: Text('Open first')),
        PopupMenuItem(value: 'name', child: Text('Name A-Z')),
      ],
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
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final bool isDemo;

  const _RestaurantCard({
    required this.restaurant,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
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
    final colors   = data['colors'] as List<Color>;
    final card    = AppColors.card(context);
    final border  = AppColors.border(context);
    final textPri = AppColors.textPrimary(context);
    final textSec = AppColors.textSecondary(context);
    final textHint= AppColors.textHint(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
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
                color: card.withValues(alpha: 0.84),
                borderRadius: BorderRadius.circular(22),
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
                        height: _hovered ? 166 : 156,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(22)),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(22)),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Real food image
                              if (_imageFor(r) != null)
                                Image.network(
                                  _imageFor(r)!,
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
                                )
                              else
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: colors),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.add_a_photo_outlined,
                                        color: Colors.white70, size: 34),
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.onFavorite != null)
                              GestureDetector(
                                onTap: widget.onFavorite,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    widget.isFavorite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: widget.isFavorite
                                        ? AppTheme.accent
                                        : Colors.white,
                                    size: 17,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            AnimatedContainer(
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
                          ],
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(r.name,
                                  style: TextStyle(
                                      color: textPri,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.1),
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
                        const SizedBox(height: 11),
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
                        const SizedBox(height: 12),
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
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: widget.onTap,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(14),
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