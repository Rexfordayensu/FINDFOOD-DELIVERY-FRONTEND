import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/providers.dart';
import 'cart_screen.dart';

class MenuDetailScreen extends StatefulWidget {
  final Restaurant restaurant;
  const MenuDetailScreen({super.key, required this.restaurant});

  @override
  State<MenuDetailScreen> createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends State<MenuDetailScreen> {
  List<MenuItem> _menu  = [];
  bool   _loading = true;
  String _error   = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final items = await ApiService.getMenu(widget.restaurant.id);
      setState(() => _menu = items);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _addToCart(MenuItem item) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    // Warn if cart has items from a different restaurant
    if (cart.restaurantId != null &&
        cart.restaurantId != widget.restaurant.id &&
        cart.items.isNotEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Start new cart?',
              style: TextStyle(color: AppTheme.textPrimary)),
          content: Text(
            'Your cart has items from ${cart.restaurantName}. '
            'Adding from ${widget.restaurant.name} will clear it.',
            style: TextStyle(color: AppTheme.textSecond),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: AppTheme.textHint)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                cart.addItem(item, widget.restaurant.id, widget.restaurant.name);
                _showAddedSnack(item.name);
              },
              child: const Text('Clear & add',
                  style: TextStyle(color: AppTheme.accent)),
            ),
          ],
        ),
      );
      return;
    }

    cart.addItem(item, widget.restaurant.id, widget.restaurant.name);
    _showAddedSnack(item.name);
  }

  void _showAddedSnack(String name) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppTheme.success,
      duration: const Duration(seconds: 1),
      content: Text('$name added to cart',
          style: const TextStyle(color: Colors.white)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final r    = widget.restaurant;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            backgroundColor: AppTheme.black,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: AppTheme.textPrimary),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppTheme.surface,
                child: Center(
                  child: Icon(Icons.storefront_rounded,
                      size: 64, color: AppTheme.textHint),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(r.name,
                            style: AppText.heading, overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: r.isActive
                              ? AppTheme.success.withValues(alpha: 0.12)
                              : AppTheme.textHint.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          r.isActive ? 'Open' : 'Closed',
                          style: TextStyle(
                            color: r.isActive ? AppTheme.success : AppTheme.textHint,
                            fontSize: 12, fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(r.cuisineType, style: AppText.body),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14, color: AppTheme.textHint),
                      const SizedBox(width: 4),
                      Text(r.address, style: AppText.caption),
                      const SizedBox(width: 14),
                      const Icon(Icons.star_rounded,
                          size: 14, color: AppTheme.accent),
                      const SizedBox(width: 3),
                      const Text('4.8',
                          style: TextStyle(
                              color: AppTheme.accent, fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 14),
                      Icon(Icons.access_time_rounded,
                          size: 14, color: AppTheme.textHint),
                      const SizedBox(width: 3),
                      const Text('25–35 min', style: AppText.caption),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppTheme.darkBorder),
                  const SectionHeader(title: 'Menu'),
                ],
              ),
            ),
          ),

          if (_loading)
            const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(color: AppTheme.accent)),
            )
          else if (_error.isNotEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.wifi_off_rounded,
                title: 'Failed to load menu',
                subtitle: _error,
                actionLabel: 'Retry',
                onAction: _load,
              ),
            )
          else if (_menu.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(
                icon: Icons.no_food_outlined,
                title: 'No items yet',
                subtitle: 'This restaurant hasn\'t added menu items.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final m = _menu[i];
                    return MenuItemCard(
                      name: m.name,
                      description: m.description,
                      price: m.displayPrice,
                      isAvailable: m.isAvailable,
                      onAdd: () => _addToCart(m),
                    );
                  },
                  childCount: _menu.length,
                ),
              ),
            ),
        ],
      ),

      // ── Sticky cart bar ─────────────────────────────────────────
      bottomNavigationBar: cart.items.isNotEmpty
          ? SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CartScreen())),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.black?.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${cart.itemCount}',
                            style: TextStyle(
                                color: AppTheme.black, fontWeight: FontWeight.w800)),
                      ),
                      const Text('View cart'),
                      Text(cart.displayTotal,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}