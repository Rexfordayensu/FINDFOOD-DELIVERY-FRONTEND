import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/providers.dart';
import 'cart_screen.dart';

// Unsplash food images per cuisine
const _cuisineImages = {
  'ghanaian':  'https://images.unsplash.com/photo-1604329760661-e71dc83f8f26?w=800&q=80',
  'local':     'https://images.unsplash.com/photo-1604329760661-e71dc83f8f26?w=800&q=80',
  'pizza':     'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&q=80',
  'italian':   'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&q=80',
  'chinese':   'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=800&q=80',
  'fast food': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&q=80',
  'burger':    'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&q=80',
  'seafood':   'https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?w=800&q=80',
  'default':   'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80',
};

String _imageFor(String cuisine) {
  final c = cuisine.toLowerCase();
  for (final k in _cuisineImages.keys) {
    if (c.contains(k)) return _cuisineImages[k]!;
  }
  return _cuisineImages['default']!;
}

// Food images per item name keywords
const _foodImages = {
  'jollof':   'https://images.unsplash.com/photo-1604329760661-e71dc83f8f26?w=400&q=80',
  'waakye':   'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&q=80',
  'banku':    'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=400&q=80',
  'rice':     'https://images.unsplash.com/photo-1516684732162-798a0062be99?w=400&q=80',
  'chicken':  'https://images.unsplash.com/photo-1567620832903-9fc6debc209f?w=400&q=80',
  'pizza':    'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400&q=80',
  'burger':   'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&q=80',
  'fish':     'https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?w=400&q=80',
  'tilapia':  'https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?w=400&q=80',
  'noodle':   'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=400&q=80',
  'soup':     'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400&q=80',
  'salad':    'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&q=80',
  'default':  'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&q=80',
};

String _foodImageFor(String name) {
  final n = name.toLowerCase();
  for (final k in _foodImages.keys) {
    if (n.contains(k)) return _foodImages[k]!;
  }
  return _foodImages['default']!;
}

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
  void initState() { super.initState(); _load(); }

  // Demo items shown when restaurant has no real menu yet
  List<MenuItem> _demoItemsFor(String cuisine) {
    final c = cuisine.toLowerCase();
    if (c.contains('pizza') || c.contains('italian')) {
      return [
        MenuItem(id: -1, name: 'Margherita Pizza', description: 'Classic tomato sauce, mozzarella and fresh basil', price: 8000, isAvailable: true, restaurantId: widget.restaurant.id),
        MenuItem(id: -2, name: 'Pepperoni Pizza', description: 'Loaded with premium pepperoni slices', price: 9500, isAvailable: true, restaurantId: widget.restaurant.id),
        MenuItem(id: -3, name: 'BBQ Chicken Pizza', description: 'Smoky BBQ sauce, grilled chicken, onions', price: 10000, isAvailable: true, restaurantId: widget.restaurant.id),
        MenuItem(id: -4, name: 'Garlic Bread', description: 'Toasted bread with garlic butter and herbs', price: 3500, isAvailable: true, restaurantId: widget.restaurant.id),
      ];
    } else if (c.contains('burger') || c.contains('fast food')) {
      return [
        MenuItem(id: -1, name: 'Classic Burger', description: 'Beef patty, lettuce, tomato, pickles and our signature sauce', price: 7500, isAvailable: true, restaurantId: widget.restaurant.id),
        MenuItem(id: -2, name: 'Crispy Chicken Burger', description: 'Fried chicken fillet with coleslaw and mayo', price: 8000, isAvailable: true, restaurantId: widget.restaurant.id),
        MenuItem(id: -3, name: 'Cheese Fries', description: 'Crispy fries loaded with melted cheddar', price: 4000, isAvailable: true, restaurantId: widget.restaurant.id),
        MenuItem(id: -4, name: 'Milkshake', description: 'Creamy vanilla, chocolate or strawberry', price: 3000, isAvailable: true, restaurantId: widget.restaurant.id),
      ];
    } else if (c.contains('chinese')) {
      return [
        MenuItem(id: -1, name: 'Fried Rice', description: 'Wok-fried rice with vegetables, egg and soy sauce', price: 6500, isAvailable: true, restaurantId: widget.restaurant.id),
        MenuItem(id: -2, name: 'Sweet & Sour Chicken', description: 'Crispy chicken in tangy sweet and sour sauce', price: 9000, isAvailable: true, restaurantId: widget.restaurant.id),
        MenuItem(id: -3, name: 'Spring Rolls (6 pcs)', description: 'Crispy rolls filled with vegetables and pork', price: 4500, isAvailable: true, restaurantId: widget.restaurant.id),
        MenuItem(id: -4, name: 'Chow Mein Noodles', description: 'Stir-fried noodles with mixed vegetables', price: 7000, isAvailable: true, restaurantId: widget.restaurant.id),
      ];
    } else if (c.contains('seafood')) {
      return [
        MenuItem(id: -1, name: 'Grilled Tilapia', description: 'Fresh tilapia grilled with spices and served with banku', price: 12000, isAvailable: true, restaurantId: widget.restaurant.id),
        MenuItem(id: -2, name: 'Prawn Stir Fry', description: 'Jumbo prawns with garlic butter and vegetables', price: 15000, isAvailable: true, restaurantId: widget.restaurant.id),
        MenuItem(id: -3, name: 'Fried Shrimp Basket', description: 'Golden fried shrimp with dipping sauce', price: 11000, isAvailable: true, restaurantId: widget.restaurant.id),
      ];
    } else {
      // Ghanaian / local / default
      return [
        MenuItem(id: -1, name: 'Jollof Rice + Chicken', description: 'Smoky party jollof with grilled chicken and fried plantain', price: 6000, isAvailable: true, restaurantId: widget.restaurant.id),
        MenuItem(id: -2, name: 'Waakye Special', description: 'Rice and beans with spaghetti, boiled egg and shito', price: 5500, isAvailable: true, restaurantId: widget.restaurant.id),
        MenuItem(id: -3, name: 'Banku + Tilapia', description: 'Fermented corn dough with grilled tilapia and pepper sauce', price: 7000, isAvailable: true, restaurantId: widget.restaurant.id),
        MenuItem(id: -4, name: 'Fufu + Light Soup', description: 'Pounded fufu served with goat light soup', price: 6500, isAvailable: true, restaurantId: widget.restaurant.id),
        MenuItem(id: -5, name: 'Kelewele', description: 'Spiced fried plantain cubes — the perfect side', price: 2500, isAvailable: true, restaurantId: widget.restaurant.id),
      ];
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      List<MenuItem> items = [];
      // Only call API for real restaurants (positive IDs)
      if (widget.restaurant.id > 0) {
        items = await ApiService.getMenu(widget.restaurant.id);
      }
      // Always show demo items if menu is empty
      if (items.isEmpty) {
        items = _demoItemsFor(widget.restaurant.cuisineType);
      }
      setState(() => _menu = items);
    } catch (e) {
      // On error, still show demo items so screen isn't blank
      setState(() => _menu = _demoItemsFor(widget.restaurant.cuisineType));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _addToCart(MenuItem item) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.restaurantId != null &&
        cart.restaurantId != widget.restaurant.id &&
        cart.items.isNotEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.card(context),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text('Start new cart?',
              style: TextStyle(color: AppColors.textPrimary(context),
                  fontWeight: FontWeight.w700)),
          content: Text(
            'Your cart has items from ${cart.restaurantName}. '
            'Adding from ${widget.restaurant.name} will clear it.',
            style: TextStyle(color: AppColors.textSecondary(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: AppColors.textHint(context))),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                cart.addItem(item, widget.restaurant.id,
                    widget.restaurant.name);
                _showAddedSnack(item.name);
              },
              child: const Text('Clear & add',
                  style: TextStyle(color: AppTheme.accent,
                      fontWeight: FontWeight.w700)),
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
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 1),
      content: Row(
        children: [
          const Icon(Icons.shopping_basket_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text('$name added to basket',
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cart    = Provider.of<CartProvider>(context);
    final r       = widget.restaurant;
    final bg      = AppColors.bg(context);
    final textPri = AppColors.textPrimary(context);
    final textSec = AppColors.textSecondary(context);
    final textHint= AppColors.textHint(context);
    final border  = AppColors.border(context);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // ── Hero image app bar ─────────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.bg(context),
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CartScreen())),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shopping_basket_rounded,
                            color: Colors.white, size: 20),
                      ),
                      if (cart.itemCount > 0)
                        Positioned(
                          top: 4, right: 4,
                          child: Container(
                            width: 16, height: 16,
                            decoration: const BoxDecoration(
                                color: AppTheme.accent,
                                shape: BoxShape.circle),
                            child: Center(
                              child: Text('${cart.itemCount}',
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
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _imageFor(r.cuisineType),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surface(context),
                      child: const Icon(Icons.restaurant_rounded,
                          size: 64, color: AppTheme.accent),
                    ),
                  ),
                  // Gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Restaurant info ────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: bg,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(r.name,
                            style: TextStyle(
                                color: textPri,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: r.isActive
                              ? AppTheme.success.withValues(alpha: 0.12)
                              : AppColors.surface(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: r.isActive
                                ? AppTheme.success.withValues(alpha: 0.4)
                                : border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6, height: 6,
                              decoration: BoxDecoration(
                                color: r.isActive
                                    ? AppTheme.success : textHint,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              r.isActive ? 'Open now' : 'Closed',
                              style: TextStyle(
                                color: r.isActive
                                    ? AppTheme.success : textHint,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(r.cuisineType,
                      style: TextStyle(color: textSec, fontSize: 14)),
                  const SizedBox(height: 12),

                  // Stats row
                  Row(
                    children: [
                      _statChip(Icons.star_rounded,
                          '4.8 (120+)', AppTheme.accent),
                      const SizedBox(width: 10),
                      _statChip(Icons.access_time_rounded,
                          '25–35 min', textHint),
                      const SizedBox(width: 10),
                      _statChip(Icons.location_on_outlined,
                          r.address, textHint, shrink: true),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Tags
                  Row(
                    children: [
                      _tag('Free delivery', AppTheme.success),
                      const SizedBox(width: 8),
                      _tag('Min GH₵ 20', textHint),
                      const SizedBox(width: 8),
                      _tag('Avg 25 min', AppTheme.accent),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: border, height: 1),
                  const SizedBox(height: 4),

                  // Menu title
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('Menu',
                        style: TextStyle(
                            color: textPri,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ),

          // ── Menu items ────────────────────────────────────
          if (_loading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppTheme.accent),
                    const SizedBox(height: 14),
                    Text('Loading menu...',
                        style: TextStyle(color: textSec)),
                  ],
                ),
              ),
            )
          else if (_error.isNotEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 48, color: textHint),
                    const SizedBox(height: 12),
                    Text('Failed to load menu',
                        style: TextStyle(color: textPri,
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(_error,
                        style: TextStyle(color: textSec, fontSize: 13),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: _load,
                        child: const Text('Retry')),
                  ],
                ),
              ),
            )
          else if (_menu.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.no_food_outlined, size: 56, color: textHint),
                    const SizedBox(height: 16),
                    Text('No items yet',
                        style: TextStyle(color: textPri,
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text("This restaurant hasn't added menu items.",
                        style: TextStyle(color: textSec)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _MenuItemCard(
                    item: _menu[i],
                    onAdd: () => _addToCart(_menu[i]),
                  ),
                  childCount: _menu.length,
                ),
              ),
            ),
        ],
      ),

      // ── Sticky basket bar ──────────────────────────────────
      bottomNavigationBar: cart.items.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CartScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accent.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${cart.itemCount}',
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('View basket',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16)),
                        ),
                        const Icon(Icons.shopping_basket_rounded,
                            color: Colors.black, size: 20),
                        const SizedBox(width: 8),
                        Text(cart.displayTotal,
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _statChip(IconData icon, String label, Color color,
      {bool shrink = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        shrink
            ? Flexible(
                child: Text(label,
                    style: TextStyle(color: color, fontSize: 12),
                    overflow: TextOverflow.ellipsis))
            : Text(label,
                style: TextStyle(color: color, fontSize: 12,
                    fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(label,
          style: TextStyle(color: color,
              fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ─── MENU ITEM CARD WITH QTY CONTROLS ───────────────────────────────────────
class _MenuItemCard extends StatefulWidget {
  final MenuItem item;
  final VoidCallback onAdd;
  const _MenuItemCard({required this.item, required this.onAdd});

  @override
  State<_MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<_MenuItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceCtrl;
  late Animation<double>   _bounceAnim;
  int _qty = 0; // local quantity on this card

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _bounceAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 0.92), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.0),  weight: 30),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _bounceCtrl.dispose(); super.dispose(); }

  void _increment() {
    widget.onAdd();
    setState(() => _qty++);
    _bounceCtrl.forward(from: 0);
  }

  void _decrement() {
    if (_qty <= 0) return;
    setState(() => _qty--);
    // Remove one from cart via provider
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.decreaseItem(widget.item.id);
  }

  @override
  Widget build(BuildContext context) {
    final item    = widget.item;
    final bg      = AppColors.card(context);
    final border  = AppColors.border(context);
    final textPri = AppColors.textPrimary(context);
    final textSec = AppColors.textSecondary(context);
    final textHint= AppColors.textHint(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _qty > 0
            ? AppTheme.accent.withValues(alpha: 0.04)
            : bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _qty > 0
              ? AppTheme.accent.withValues(alpha: 0.35)
              : border,
          width: _qty > 0 ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _qty > 0
                ? AppTheme.accent.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: _qty > 0 ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // ── Food image ────────────────────────────────
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: SizedBox(
                  width: 100, height: 100,
                  child: Image.network(
                    // Real restaurant-uploaded photo takes priority;
                    // falls back to a keyword-matched stock photo if none set
                    item.imageUrl != null
                        ? '${ApiService.baseUrl}${item.imageUrl}'
                        : _foodImageFor(item.name),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surface(context),
                      child: Icon(Icons.fastfood_rounded,
                          size: 30, color: textHint),
                    ),
                    loadingBuilder: (_, child, prog) {
                      if (prog == null) return child;
                      return Container(
                        color: AppColors.surface(context),
                        child: const Center(
                          child: SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: AppTheme.accent, strokeWidth: 2),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ── Info ──────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: TextStyle(
                              color: textPri,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      if (item.description != null &&
                          item.description!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(item.description!,
                            style: TextStyle(
                                color: textSec,
                                fontSize: 11,
                                height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.displayPrice,
                              style: const TextStyle(
                                  color: AppTheme.accent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800)),

                          // ── +/- qty controls or basket button ──
                          if (!item.isAvailable)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: textHint.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('Sold out',
                                  style: TextStyle(
                                      color: textHint,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            )
                          else if (_qty == 0)
                            // Initial basket button
                            ScaleTransition(
                              scale: _bounceAnim,
                              child: GestureDetector(
                                onTap: _increment,
                                child: Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.accent.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                      Icons.shopping_basket_rounded,
                                      color: Colors.black, size: 20),
                                ),
                              ),
                            )
                          else
                            // +/- stepper
                            ScaleTransition(
                              scale: _bounceAnim,
                              child: Row(
                                children: [
                                  _QtyBtn(
                                    icon: Icons.remove_rounded,
                                    onTap: _decrement,
                                    filled: false,
                                  ),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    transitionBuilder: (child, anim) =>
                                        ScaleTransition(scale: anim, child: child),
                                    child: Container(
                                      key: ValueKey(_qty),
                                      width: 34,
                                      alignment: Alignment.center,
                                      child: Text('$_qty',
                                          style: const TextStyle(
                                              color: AppTheme.accent,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900)),
                                    ),
                                  ),
                                  _QtyBtn(
                                    icon: Icons.add_rounded,
                                    onTap: _increment,
                                    filled: true,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Subtotal strip when qty > 0
          if (_qty > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$_qty × ${item.displayPrice}',
                      style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 12)),
                  Text(
                    'GH₵ ${(item.price * _qty / 100).toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── QTY BUTTON ───────────────────────────────────────────────────────────────
class _QtyBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  const _QtyBtn({required this.icon, required this.onTap, required this.filled});

  @override
  State<_QtyBtn> createState() => _QtyBtnState();
}

class _QtyBtnState extends State<_QtyBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.85).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: widget.filled
                ? AppTheme.accent
                : AppTheme.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: widget.filled
                ? null
                : Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
          ),
          child: Icon(widget.icon,
              color: widget.filled ? Colors.black : AppTheme.accent,
              size: 18),
        ),
      ),
    );
  }
}