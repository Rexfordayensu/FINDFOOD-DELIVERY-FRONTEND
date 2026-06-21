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

class FoodFeedScreen extends StatefulWidget {
  const FoodFeedScreen({super.key});

  @override
  State<FoodFeedScreen> createState() => _FoodFeedScreenState();
}

class _FoodFeedScreenState extends State<FoodFeedScreen> {
  List<Restaurant> _restaurants = [];
  List<Restaurant> _filtered    = [];
  bool   _loading = true;
  String _error   = '';
  String _search  = '';
  String _filter  = 'All';

  final _filters = ['All', 'Ghanaian', 'Fast food', 'Pizza', 'Chinese'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final list = await ApiService.getRestaurants();
      setState(() { _restaurants = list; _applyFilter(); });
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
  }

  @override
  Widget build(BuildContext context) {
    final auth       = Provider.of<AuthProvider>(context);
    final cart       = Provider.of<CartProvider>(context);
    final themeP     = Provider.of<ThemeProvider>(context);
    final bgColor    = AppColors.bg(context);
    final surfColor  = AppColors.surface(context);
    final borderColor= AppColors.border(context);
    final textPri    = AppColors.textPrimary(context);
    final textHint   = AppColors.textHint(context);

    return Scaffold(
      backgroundColor: bgColor,

      // ── Fixed top header (not a SliverAppBar) ───────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          color: bgColor,
          child: SafeArea(
            child: Column(
              children: [
                // Row 1: Brand + action icons
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Row(
                    children: [
                      // Logo
                      Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(Icons.fastfood_rounded,
                            color: Colors.black, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text('FINDFOOD',
                          style: TextStyle(
                            color: textPri,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            letterSpacing: 0.6,
                          )),
                      const Spacer(),

                      // ☀️/🌙 Theme toggle
                      _iconBtn(
                        icon: themeP.isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color: textPri,
                        bg: surfColor,
                        border: borderColor,
                        onTap: themeP.toggle,
                      ),
                      const SizedBox(width: 8),

                      // 🛍 Cart
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _iconBtn(
                            icon: Icons.shopping_bag_outlined,
                            color: textPri,
                            bg: surfColor,
                            border: borderColor,
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (_) => const CartScreen())),
                          ),
                          if (cart.itemCount > 0)
                            Positioned(
                              top: -4, right: -4,
                              child: Container(
                                width: 17, height: 17,
                                decoration: const BoxDecoration(
                                    color: AppTheme.accent,
                                    shape: BoxShape.circle),
                                child: Center(
                                  child: Text('${cart.itemCount}',
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800)),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),

                      // 👤 Login / logout
                      _iconBtn(
                        icon: auth.isLoggedIn
                            ? Icons.person_rounded
                            : Icons.login_rounded,
                        color: auth.isLoggedIn
                            ? AppTheme.accent : textPri,
                        bg: auth.isLoggedIn
                            ? AppTheme.accentDim : surfColor,
                        border: auth.isLoggedIn
                            ? AppTheme.accent.withOpacity(0.3) : borderColor,
                        onTap: () {
                          if (auth.isLoggedIn) {
                            auth.logout();
                          } else {
                            Navigator.push(context, MaterialPageRoute(
                                builder: (_) => const LoginScreen()));
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Row 2: Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    style: TextStyle(color: textPri, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search restaurants or dishes...',
                      hintStyle: TextStyle(color: textHint, fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: textHint, size: 20),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 0),
                      filled: true,
                      fillColor: surfColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppTheme.accent, width: 1.5),
                      ),
                    ),
                    onChanged: (v) =>
                        setState(() { _search = v; _applyFilter(); }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // ── Body ────────────────────────────────────────────────
      body: Column(
        children: [
          // Cuisine filter chips
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f      = _filters[i];
                final active = _filter == f;
                return GestureDetector(
                  onTap: () =>
                      setState(() { _filter = f; _applyFilter(); }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 5),
                    decoration: BoxDecoration(
                      color: active ? AppTheme.accent : surfColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: active
                              ? AppTheme.accent : borderColor),
                    ),
                    child: Text(f,
                        style: TextStyle(
                          color: active ? Colors.black : textHint,
                          fontWeight: active
                              ? FontWeight.w700 : FontWeight.w400,
                          fontSize: 13,
                        )),
                  ),
                );
              },
            ),
          ),

          // Restaurant list
          Expanded(
            child: _loading
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
                    : _filtered.isEmpty
                        ? const EmptyState(
                            icon: Icons.storefront_outlined,
                            title: 'No restaurants found',
                            subtitle:
                                'Try adjusting your search or filters.',
                          )
                        : RefreshIndicator(
                            color: AppTheme.accent,
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 8, 16, 80),
                              itemCount: _filtered.length,
                              itemBuilder: (_, i) {
                                final r = _filtered[i];
                                return RestaurantCard(
                                  name: r.name,
                                  cuisine: r.cuisineType,
                                  address: r.address,
                                  isActive: r.isActive,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MenuDetailScreen(
                                          restaurant: r),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  // Reusable icon button
  Widget _iconBtn({
    required IconData icon,
    required Color color,
    required Color bg,
    required Color border,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Icon(icon, color: color, size: 19),
      ),
    );
  }
}