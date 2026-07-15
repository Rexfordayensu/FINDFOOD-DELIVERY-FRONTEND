import 'package:findfood_app/screens/restaurants/restaurant_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';
import '../../services/api_service.dart';
import '../../services/providers.dart';
import '../customer/food_feed_screen.dart';
import '../admin/admin_dashboard.dart';
import '../rider/rider_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginKey  = GlobalKey<FormState>();
  final _signupKey = GlobalKey<FormState>();

  final _loginEmail    = TextEditingController();
  final _loginPassword = TextEditingController();
  final _signupName    = TextEditingController();
  final _signupEmail   = TextEditingController();
  final _signupPass    = TextEditingController();
  final _signupCuisine = TextEditingController();
  final _signupAddress = TextEditingController();

  bool _obscureLogin  = true;
  bool _obscureSignup = true;
  bool _isLoading     = false;
  int  _tabIndex      = 0;
  String _signupRole  = 'customer';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() => _tabIndex = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _signupName.dispose();
    _signupEmail.dispose();
    _signupPass.dispose();
    _signupCuisine.dispose();
    _signupAddress.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_loginKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.login(
        _loginEmail.text.trim(),
        _loginPassword.text.trim(),
      );
      if (!mounted) return;

      final role = (data['role'] ?? 'customer').toString();
      final isApproved = data['is_approved'] ?? data['approved'];
      final isActive = data['is_active'] ?? data['active'];

      if (role == 'restaurant' && isApproved == false) {
        throw Exception('Your restaurant account is still pending approval.');
      }
      if (isActive == false) {
        throw Exception('This account has been deactivated.');
      }

      Provider.of<AuthProvider>(context, listen: false).login(
        token:  data['access_token'],
        userId: data['user_id'],
        role:   role,
      );

      _routeByRole(role);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    if (!_signupKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final registrationData = await ApiService.register(
        name:     _signupName.text.trim(),
        email:    _signupEmail.text.trim(),
        password: _signupPass.text.trim(),
        role:     _signupRole,
      );
      if (!mounted) return;

      if (_signupRole == 'restaurant') {
        String? token = registrationData['access_token']?.toString();
        if ((token == null || token.isEmpty) && registrationData['token'] != null) {
          token = registrationData['token'].toString();
        }

        if ((token == null || token.isEmpty)) {
          final loginData = await ApiService.login(
            _signupEmail.text.trim(),
            _signupPass.text.trim(),
          );
          token = loginData['access_token']?.toString();
        }

        if (token != null && token.isNotEmpty) {
          try {
            await ApiService.createRestaurant(
              token: token,
              name: _signupName.text.trim(),
              cuisineType: _signupCuisine.text.trim().isNotEmpty
                  ? _signupCuisine.text.trim()
                  : 'Not specified',
              address: _signupAddress.text.trim().isNotEmpty
                  ? _signupAddress.text.trim()
                  : 'Pending review',
              email: _signupEmail.text.trim(),
              password: _signupPass.text.trim(),
            );
          } catch (_) {
            // The user account exists; the approval profile will be reviewed by the admin.
          }
        }

        _showVendorDialog();
      } else {
        // Pre-fill login email so user doesn't have to retype it
        _loginEmail.text = _signupEmail.text.trim();

        _showSuccess('Account created! Sign in below ✓');

        // Clear signup fields
        _signupName.clear();
        _signupEmail.clear();
        _signupPass.clear();
        _signupCuisine.clear();
        _signupAddress.clear();

        // Switch to Sign In tab
        setState(() => _tabIndex = 0);
        _tabController.animateTo(0);
      }
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _routeByRole(String role) {
    Widget dest;
    switch (role) {
      case 'admin':      dest = const AdminDashboard();      break;
      case 'restaurant': dest = const RestaurantDashboard(); break;
      case 'rider':      dest = const RiderDashboard();      break;
      default:           dest = const FoodFeedScreen();
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => dest),
      (_) => false,
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppTheme.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Text(msg, style: const TextStyle(color: Colors.white)),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Text(msg, style: const TextStyle(color: Colors.white)),
    ));
  }

  void _showVendorDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card(context),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Application received',
            style: TextStyle(
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.w700)),
        content: Text(
          'Your restaurant application has been submitted. Our team will '
          'verify your details within 24–48 hours and activate your dashboard.',
          style: TextStyle(
              color: AppColors.textSecondary(context), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _tabController.animateTo(0);
            },
            child: const Text('Got it',
                style: TextStyle(
                    color: AppTheme.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor     = AppColors.bg(context);
    final surfColor   = AppColors.surface(context);
    final borderColor = AppColors.border(context);
    final textPri     = AppColors.textPrimary(context);
    final textSec     = AppColors.textSecondary(context);
    final textHint    = AppColors.textHint(context);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  // ── Logo ────────────────────────────────────────
                  Container(
                    width: 68, height: 68,
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.fastfood_rounded,
                        color: Colors.black, size: 34),
                  ),
                  const SizedBox(height: 14),
                  Text('FINDFOOD',
                      style: TextStyle(
                        color: textPri,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      )),
                  const SizedBox(height: 4),
                  Text('Food delivery, done fast.',
                      style: TextStyle(color: textSec, fontSize: 14)),
                  const SizedBox(height: 32),

                  // ── FIX: Custom tab switcher (replaces TabBar) ──
                  // TabBar was showing invisible text when selected
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: surfColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        _tabBtn('Sign in', 0),
                        _tabBtn('Sign up', 1),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Forms ────────────────────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _tabIndex == 0
                        ? _buildLoginForm(key: const ValueKey('login'),
                            textHint: textHint)
                        : _buildSignupForm(key: const ValueKey('signup'),
                            surfColor: surfColor,
                            borderColor: borderColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Custom tab button — text always visible ──────────────────────────────
  Widget _tabBtn(String label, int index) {
    final active = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() => _tabIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? AppTheme.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                // FIX: active → black text on yellow; inactive → theme text
                color: active
                    ? Colors.black
                    : AppColors.textSecondary(context),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Login form ───────────────────────────────────────────────────────────
  Widget _buildLoginForm({required Key key, required Color textHint}) {
    return Form(
      key: _loginKey,
      child: Column(
        key: key,
        children: [
          AppTextField(
            controller: _loginEmail,
            hint: 'Email address',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            // FIX: proper email validation with domain check
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
              if (!emailRegex.hasMatch(v.trim())) {
                return 'Enter a valid email e.g. name@gmail.com';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: _loginPassword,
            hint: 'Password',
            prefixIcon: Icons.lock_outline_rounded,
            obscure: _obscureLogin,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureLogin ? Icons.visibility_off : Icons.visibility,
                color: textHint, size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureLogin = !_obscureLogin),
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? 'Min 6 characters' : null,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text('Forgot password?',
                  style: TextStyle(color: AppTheme.accent, fontSize: 13)),
            ),
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            label: 'Sign in',
            isLoading: _isLoading,
            onPressed: _login,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Don't have an account? ",
                  style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 13)),
              GestureDetector(
                onTap: () => setState(() {
                  _tabIndex = 1;
                  _tabController.animateTo(1);
                }),
                child: const Text('Sign up',
                    style: TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Signup form ──────────────────────────────────────────────────────────
  Widget _buildSignupForm({
    required Key key,
    required Color surfColor,
    required Color borderColor,
  }) {
    return Form(
      key: _signupKey,
      child: Column(
        key: key,
        children: [
          // Role picker
          Container(
            decoration: BoxDecoration(
              color: surfColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                _roleChip('Customer',   'customer',   Icons.person_outline),
                _roleChip('Restaurant', 'restaurant', Icons.storefront_outlined),
                _roleChip('Rider',      'rider',      Icons.electric_bike_outlined),
              ],
            ),
          ),
          const SizedBox(height: 16),

          AppTextField(
            controller: _signupName,
            hint: 'Full name',
            prefixIcon: Icons.person_outline_rounded,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 14),

          AppTextField(
            controller: _signupEmail,
            hint: 'Email e.g. name@gmail.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            // FIX: strict email regex — backend rejects non-domain emails
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
              if (!emailRegex.hasMatch(v.trim())) {
                return 'Must be a valid email e.g. name@gmail.com';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          AppTextField(
            controller: _signupPass,
            hint: 'Password (min 6 characters)',
            prefixIcon: Icons.lock_outline_rounded,
            obscure: _obscureSignup,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureSignup ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textHint(context), size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureSignup = !_obscureSignup),
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? 'Min 6 characters' : null,
          ),
          const SizedBox(height: 20),

          PrimaryButton(
            label: _signupRole == 'restaurant'
                ? 'Submit application'
                : 'Create account',
            isLoading: _isLoading,
            onPressed: _register,
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Already have an account? ',
                  style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 13)),
              GestureDetector(
                onTap: () => setState(() {
                  _tabIndex = 0;
                  _tabController.animateTo(0);
                }),
                child: const Text('Sign in',
                    style: TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Role chip ────────────────────────────────────────────────────────────
  Widget _roleChip(String label, String value, IconData icon) {
    final selected = _signupRole == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _signupRole = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18,
                  color: selected
                      ? Colors.black
                      : AppColors.textHint(context)),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    // FIX: always readable — black on yellow, hint on transparent
                    color: selected
                        ? Colors.black
                        : AppColors.textHint(context),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}