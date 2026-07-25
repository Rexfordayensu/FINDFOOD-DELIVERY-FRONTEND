import 'package:findfood_app/screens/auth/email_verification_screen.dart';
import 'package:findfood_app/screens/restaurants/restaurant_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';
import '../../services/api_service.dart';
import '../../services/providers.dart';
import '../../screens/splash_screen.dart';
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
  final _resetEmail    = TextEditingController();
  final _cuisineController = TextEditingController();
  final _addressController = TextEditingController();

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
    _resetEmail.dispose();
    _cuisineController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // ── LOGIN ─────────────────────────────────────────────────────────────────
  Future<void> _login() async {
    if (!_loginKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.login(
        _loginEmail.text.trim(),
        _loginPassword.text.trim(),
      );
      if (!mounted) return;

      Provider.of<AuthProvider>(context, listen: false).login(
        token:  data['access_token'],
        userId: data['user_id'],
        role:   data['role'],
      );

      // Show splash then route by role
      _goWithSplash(_destinationFor(data['role']));
    } on EmailNotVerifiedException catch (e) {
      if (!mounted) return;
      // Navigate to email verification screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(
            email: _loginEmail.text.trim(),
            role: '', // Role will be determined after verification
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── REGISTER ──────────────────────────────────────────────────────────────
  Future<void> _register(TextEditingController cuisineController, TextEditingController addressController) async {
    // 1. Basic form validation (Email, Password, Name)
    if (!_signupKey.currentState!.validate()) return;

    // 2. Strict validation: Ensure restaurant users supplied their details
    if (_signupRole == 'restaurant') {
      if (cuisineController.text.trim().isEmpty || addressController.text.trim().isEmpty) {
        _showError('Cuisine Type and Store Address are required for restaurants!');
        return; // Halt registration here
      }
    }

    setState(() => _isLoading = true);
    
    final registrationEmail = _signupEmail.text.trim();
    final registrationRole = _signupRole;
    
    try {
      // 3. Make the API call with all required fields
      await ApiService.register(
        name:     _signupName.text.trim(),
        email:    registrationEmail,
        password: _signupPass.text.trim(),
        role:     registrationRole,
        cuisineType: registrationRole == 'restaurant' ? cuisineController.text.trim() : '',
        address: registrationRole == 'restaurant' ? addressController.text.trim() : '', 
      );
      if (!mounted) return;

      _showSuccess('Account created! Please verify your email.');
      
      // Clear form
      _signupName.clear();
      _signupEmail.clear();
      _signupPass.clear();
      cuisineController.clear();
      addressController.clear();

      // Navigate to email verification screen
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(
            email: registrationEmail,
            role: registrationRole,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Widget _destinationFor(String role) {
    switch (role) {
      case 'admin':      return const AdminDashboard();
      case 'restaurant': return RestaurantDashboard(token: Provider.of<AuthProvider>(context, listen: false).token!);
      case 'rider':      return const RiderDashboard();
      default:           return const FoodFeedScreen();
    }
  }

  void _goWithSplash(Widget destination) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => SplashScreen(destination: destination),
      ),
      (_) => false,
    );
  }

  // ── FORGOT PASSWORD ───────────────────────────────────────────────────────
  void _showForgotPassword() {
    _resetEmail.text = _loginEmail.text.trim();
    bool sending = false;
    bool sent    = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border(ctx),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (!sent) ...[
                // ── Step 1: Enter email ──────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.lock_reset_rounded,
                          color: AppTheme.accent, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reset password',
                            style: TextStyle(
                                color: AppColors.textPrimary(ctx),
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                        Text('We\'ll send a reset link to your email',
                            style: TextStyle(
                                color: AppColors.textSecondary(ctx),
                                fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text('Email address',
                    style: TextStyle(
                        color: AppColors.textSecondary(ctx),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface(ctx),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(ctx)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Icon(Icons.email_outlined,
                          color: AppColors.textHint(ctx), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _resetEmail,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(
                              color: AppColors.textPrimary(ctx),
                              fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Enter your email',
                            hintStyle: TextStyle(
                                color: AppColors.textHint(ctx)),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 14),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Send button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: sending
                        ? null
                        : () async {
                            final email = _resetEmail.text.trim();
                            if (email.isEmpty || !email.contains('@')) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: AppTheme.danger,
                                  content: Text('Enter a valid email',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              );
                              return;
                            }
                            setSheet(() => sending = true);
                            try {
                              // Call backend password reset endpoint
                              await ApiService.requestPasswordReset(email);
                              setSheet(() { sending = false; sent = true; });
                            } catch (e) {
                              setSheet(() => sending = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppTheme.danger,
                                  content: Text(
                                    e.toString().replaceAll('Exception: ', ''),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            }
                          },
                    child: sending
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 2.5))
                        : const Text('Send reset link'),
                  ),
                ),
              ] else ...[
                // ── Step 2: Confirmation ─────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mark_email_read_rounded,
                            color: AppTheme.success, size: 36),
                      ),
                      const SizedBox(height: 16),
                      Text('Check your inbox!',
                          style: TextStyle(
                              color: AppColors.textPrimary(ctx),
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(
                        'We sent a password reset link to\n${_resetEmail.text.trim()}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textSecondary(ctx),
                            fontSize: 14,
                            height: 1.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check your spam folder if you don\'t see it.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textHint(ctx), fontSize: 12),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Back to sign in'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Resend
                      GestureDetector(
                        onTap: () => setSheet(() => sent = false),
                        child: const Text('Resend email',
                            style: TextStyle(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── GOOGLE SIGN IN (UI only — needs Firebase to work fully) ───────────────
  void _googleSignIn() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card(context),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Google Sign-In',
            style: TextStyle(
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.g_mobiledata_rounded,
                  color: AppTheme.accent, size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              'To enable Google Sign-In, connect Firebase to your project.\n\n'
              'Steps:\n'
              '1. Create a Firebase project at console.firebase.google.com\n'
              '2. Add google-services.json to android/app/\n'
              '3. Run: flutter pub add firebase_auth google_sign_in',
              style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 13,
                  height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it',
                style: TextStyle(
                    color: AppTheme.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
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
          'verify your details within 24–48 hours.',
          style: TextStyle(
              color: AppColors.textSecondary(context), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _tabIndex = 0);
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

  @override
  Widget build(BuildContext context) {
    final bg      = AppColors.bg(context);
    final surf    = AppColors.surface(context);
    final textPri = AppColors.textPrimary(context);
    final textSec = AppColors.textSecondary(context);
    final textHint= AppColors.textHint(context);
    final border  = AppColors.border(context);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  // ── Logo ──────────────────────────────────
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
                          color: textPri, fontSize: 28,
                          fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text('Food delivery, done fast.',
                      style: TextStyle(color: textSec, fontSize: 14)),
                  const SizedBox(height: 32),

                  // ── Tab switcher ───────────────────────────
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: surf,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border),
                    ),
                    child: Row(children: [
                      _tabBtn('Sign in', 0, surf, textSec),
                      _tabBtn('Sign up', 1, surf, textSec),
                    ]),
                  ),
                  const SizedBox(height: 28),

                  // ── Forms ─────────────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _tabIndex == 0
                        ? _buildLoginForm(
                            key: const ValueKey('login'),
                            textHint: textHint, border: border, surf: surf)
                        : _buildSignupForm(
                            key: const ValueKey('signup'),
                            surf: surf, border: border),
                  ),

                  const SizedBox(height: 24),

                  // ── Divider ───────────────────────────────
                  Row(children: [
                    Expanded(child: Divider(color: border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or continue with',
                          style: TextStyle(color: textHint, fontSize: 12)),
                    ),
                    Expanded(child: Divider(color: border)),
                  ]),
                  const SizedBox(height: 16),

                  // ── Social buttons ────────────────────────
                  Row(children: [
                    Expanded(
                      child: _SocialBtn(
                        label: 'Google',
                        icon: Icons.g_mobiledata_rounded,
                        color: const Color(0xFFEA4335),
                        onTap: _googleSignIn,
                        surf: surf, border: border, textPri: textPri,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SocialBtn(
                        label: 'Apple',
                        icon: Icons.apple_rounded,
                        color: textPri,
                        onTap: () => _showComingSoon('Apple Sign-In'),
                        surf: surf, border: border, textPri: textPri,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SocialBtn(
                        label: 'Facebook',
                        icon: Icons.facebook_rounded,
                        color: const Color(0xFF1877F2),
                        onTap: () => _showComingSoon('Facebook Sign-In'),
                        surf: surf, border: border, textPri: textPri,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppColors.surface(context),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.border(context))),
      content: Text('$label coming soon!',
          style: TextStyle(color: AppColors.textPrimary(context))),
    ));
  }

  Widget _tabBtn(String label, int index, Color surf, Color textSec) {
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
            child: Text(label,
                style: TextStyle(
                  color: active ? Colors.black : textSec,
                  fontWeight: FontWeight.w700, fontSize: 15,
                )),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm({
    required Key key,
    required Color textHint,
    required Color border,
    required Color surf,
  }) {
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
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              final reg = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
              if (!reg.hasMatch(v.trim())) return 'Enter a valid email';
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
              onPressed: () => setState(() => _obscureLogin = !_obscureLogin),
            ),
            validator: (v) =>
               (v == null || v.length < 8) ? 'Min 8 characters' : null,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showForgotPassword,
              child: const Text('Forgot password?',
                  style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            label: 'Sign in',
            isLoading: _isLoading,
            onPressed: _login,
          ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text("Don't have an account? ",
                style: TextStyle(color: AppColors.textSecondary(context),
                    fontSize: 13)),
            GestureDetector(
              onTap: () => setState(() {
                _tabIndex = 1;
                _tabController.animateTo(1);
              }),
              child: const Text('Sign up',
                  style: TextStyle(color: AppTheme.accent,
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSignupForm({
    required Key key,
    required Color surf,
    required Color border,
  }) {
    return Form(
      key: _signupKey,
      child: Column(
        key: key,
        children: [
          // Role picker
          Container(
            decoration: BoxDecoration(
              color: surf,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(children: [
              _roleChip('Customer',   'customer',   Icons.person_outline),
              _roleChip('Restaurant', 'restaurant', Icons.storefront_outlined),
              _roleChip('Rider',      'rider',      Icons.electric_bike_outlined),
            ]),
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
            hint: 'Email address',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              final reg = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
              if (!reg.hasMatch(v.trim())) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 14),
if (_signupRole == 'restaurant') ...[
  AppTextField(
    controller: _cuisineController, // Or your local cuisine text controller
    hint: 'Cuisine Type e.g. local, Italian, Chinese, Fast Food',
    prefixIcon: Icons.restaurant_menu_outlined,
    validator: (v) {
      if (_signupRole == 'restaurant' && (v == null || v.trim().isEmpty)) {
        return 'Cuisine type is required';
      }
      return null;
    },
  ),
  const SizedBox(height: 14),
  AppTextField(
    controller: _addressController, // Or your local address text controller
    hint: 'Restaurant Address',
    prefixIcon: Icons.location_on_outlined,
    validator: (v) {
      if (_signupRole == 'restaurant' && (v == null || v.trim().isEmpty)) {
        return 'Restaurant address is required';
      }
      return null;
    },
  ),
],
          const SizedBox(height: 14),
          AppTextField(
            controller: _signupPass,
            hint: 'Password (min 8 characters)',
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
                (v == null || v.length < 8) ? 'Min 8 characters' : null,
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: _signupRole == 'restaurant'
                ? 'Submit application'
                : 'Create account',
            isLoading: _isLoading,
            onPressed: () => _register(_cuisineController, _addressController),
          ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Already have an account? ',
                style: TextStyle(
                    color: AppColors.textSecondary(context), fontSize: 13)),
            GestureDetector(
              onTap: () => setState(() {
                _tabIndex = 0;
                _tabController.animateTo(0);
              }),
              child: const Text('Sign in',
                  style: TextStyle(color: AppTheme.accent,
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ]),
        ],
      ),
    );
  }

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
          child: Column(children: [
            Icon(icon, size: 18,
                color: selected ? Colors.black : AppColors.textHint(context)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: selected
                        ? Colors.black : AppColors.textHint(context))),
          ]),
        ),
      ),
    );
  }
}

// ─── SOCIAL BUTTON ────────────────────────────────────────────────────────────
class _SocialBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color, surf, border, textPri;
  final VoidCallback onTap;

  const _SocialBtn({
    required this.label, required this.icon, required this.color,
    required this.onTap, required this.surf, required this.border,
    required this.textPri,
  });

  @override
  State<_SocialBtn> createState() => _SocialBtnState();
}

class _SocialBtnState extends State<_SocialBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()
          ..scale(_pressed ? 0.95 : 1.0),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: _pressed
              ? widget.color.withValues(alpha: 0.08)
              : widget.surf,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _pressed
                ? widget.color.withValues(alpha: 0.4)
                : widget.border,
            width: _pressed ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: widget.color, size: 24),
            const SizedBox(height: 4),
            Text(widget.label,
                style: TextStyle(
                    color: widget.textPri,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
