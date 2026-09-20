import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';
import '../../services/api_service.dart';
import '../../services/providers.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.returnRoute = '/home',
    this.pendingAction,
    this.pendingParameters,
  });

  final String returnRoute;
  final String? pendingAction;
  final Map<String, dynamic>? pendingParameters;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginKey = GlobalKey<FormState>();
  final _signupKey = GlobalKey<FormState>();

  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _signupName = TextEditingController();
  final _signupEmail = TextEditingController();
  final _signupPass = TextEditingController();
  final _resetEmail = TextEditingController();
  final _cuisineController = TextEditingController();
  final _addressController = TextEditingController();

  bool _obscureLogin = true;
  bool _obscureSignup = true;
  bool _isLoading = false;
  bool _isRequestingOtp = false;
  bool _useOtpLogin = false;
  int _tabIndex = 0;
  String _signupRole = 'customer';

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

      if (otpRequiredFromResponse(data)) {
        context.go(
          '/email-verification?email=${Uri.encodeComponent(_loginEmail.text.trim())}&role=${Uri.encodeComponent('')}&mode=${Uri.encodeComponent('login')}',
        );
        return;
      }

      await Provider.of<AuthProvider>(context, listen: false).login(
        token: data['access_token'],
        userId: data['user_id'],
        role: data['role'],
        email: data['email']?.toString() ?? _loginEmail.text.trim(),
      );

      if (!mounted) return;
      context.go(_routeAfterLogin(data['role']));
    } on EmailNotVerifiedException {
      if (!mounted) return;
      context.go(
        '/email-verification?email=${Uri.encodeComponent(_loginEmail.text.trim())}&role=${Uri.encodeComponent('')}&mode=${Uri.encodeComponent('login')}',
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _requestOtp() async {
    final email = _loginEmail.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Enter a valid email');
      return;
    }

    setState(() => _isRequestingOtp = true);
    try {
      await ApiService.requestLoginOtp(email: email);
      if (!mounted) return;

      context.go(
        '/email-verification?email=${Uri.encodeComponent(email)}&role=${Uri.encodeComponent('')}&mode=${Uri.encodeComponent('login')}',
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isRequestingOtp = false);
    }
  }

  // ── REGISTER ──────────────────────────────────────────────────────────────
  Future<void> _register(TextEditingController cuisineController,
      TextEditingController addressController) async {
    // 1. Basic form validation (Email, Password, Name)
    if (!_signupKey.currentState!.validate()) return;

    // 2. Strict validation: Ensure restaurant users supplied their details
    if (_signupRole == 'restaurant') {
      if (cuisineController.text.trim().isEmpty ||
          addressController.text.trim().isEmpty) {
        _showError(
            'Cuisine Type and Store Address are required for restaurants!');
        return; // Halt registration here
      }
    }

    setState(() => _isLoading = true);

    final registrationEmail = _signupEmail.text.trim();
    final registrationRole = _signupRole;

    try {
      // 3. Make the API call with all required fields
      final data = await ApiService.register(
        name: _signupName.text.trim(),
        email: registrationEmail,
        password: _signupPass.text.trim(),
        role: registrationRole,
        cuisineType: registrationRole == 'restaurant'
            ? cuisineController.text.trim()
            : '',
        address: registrationRole == 'restaurant'
            ? addressController.text.trim()
            : '',
      );
      if (!mounted) return;

      final otpRequired = otpRequiredFromResponse(data);
      _showSuccess(otpRequired
          ? 'Account created! Please verify your email.'
          : 'Account created successfully.');

      // Clear form
      _signupName.clear();
      _signupEmail.clear();
      _signupPass.clear();
      cuisineController.clear();
      addressController.clear();

      if (!mounted) return;
      if (otpRequired) {
        context.go(
          '/email-verification?email=${Uri.encodeComponent(registrationEmail)}&role=${Uri.encodeComponent(registrationRole)}&mode=${Uri.encodeComponent('registration')}',
        );
      } else {
        setState(() {
          _tabIndex = 0;
          _tabController.animateTo(0);
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _routeForRole(String role) {
    switch (role) {
      case 'admin':
        return '/admin';
      case 'restaurant':
        return '/restaurant/orders';
      case 'rider':
        return '/rider';
      default:
        return '/';
    }
  }

  String _routeAfterLogin(String role) {
    final requested = widget.returnRoute;
    if (role == 'customer' && requested.isNotEmpty && requested != '/home') {
      return requested;
    }
    return _routeForRole(role);
  }

  // ── FORGOT PASSWORD ───────────────────────────────────────────────────────
  void _showForgotPassword() {
    context.push('/forgot-password');
  }

  // ── GOOGLE SIGN IN ───────────────────────────────────────────────────────
  Future<void> _googleSignIn() async {
    try {
      if (!mounted) return;
      await context.push(
        '/google-oauth?returnTo=${Uri.encodeComponent(widget.returnRoute)}',
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(feature,
            style: TextStyle(color: AppColors.textPrimary(context))),
        content: Text('This feature is coming soon.',
            style: TextStyle(color: AppColors.textSecondary(context))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK')),
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
    final bg = AppColors.bg(context);
    final surf = AppColors.surface(context);
    final textPri = AppColors.textPrimary(context);
    final textSec = AppColors.textSecondary(context);
    final textHint = AppColors.textHint(context);
    final border = AppColors.border(context);

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
                    width: 68,
                    height: 68,
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
                          letterSpacing: 0.5)),
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
                            textHint: textHint,
                            border: border,
                            surf: surf)
                        : _buildSignupForm(
                            key: const ValueKey('signup'),
                            surf: surf,
                            border: border),
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
                        surf: surf,
                        border: border,
                        textPri: textPri,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SocialBtn(
                        label: 'Apple',
                        icon: Icons.apple_rounded,
                        color: textPri,
                        onTap: () => _showComingSoon('Apple Sign-In'),
                        surf: surf,
                        border: border,
                        textPri: textPri,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SocialBtn(
                        label: 'Facebook',
                        icon: Icons.facebook_rounded,
                        color: const Color(0xFF1877F2),
                        onTap: () => _showComingSoon('Facebook Sign-In'),
                        surf: surf,
                        border: border,
                        textPri: textPri,
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
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
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
          if (!_useOtpLogin) ...[
            AppTextField(
              controller: _loginPassword,
              hint: 'Password',
              prefixIcon: Icons.lock_outline_rounded,
              obscure: _obscureLogin,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureLogin ? Icons.visibility_off : Icons.visibility,
                  color: textHint,
                  size: 20,
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
          ] else ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _useOtpLogin = false),
                child: const Text('Use password instead',
                    style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          PrimaryButton(
            label: _useOtpLogin ? 'Continue' : 'Sign in',
            isLoading: _useOtpLogin ? _isRequestingOtp : _isLoading,
            onPressed: _useOtpLogin ? _requestOtp : _login,
          ),
          const SizedBox(height: 12),
          if (!_useOtpLogin)
            TextButton(
              onPressed: () => setState(() => _useOtpLogin = true),
              child: const Text('Login using OTP',
                  style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text("Don't have an account? ",
                style: TextStyle(
                    color: AppColors.textSecondary(context), fontSize: 13)),
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
              _roleChip('Customer', 'customer', Icons.person_outline),
              _roleChip('Restaurant', 'restaurant', Icons.storefront_outlined),
              _roleChip('Rider', 'rider', Icons.electric_bike_outlined),
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
              controller: _cuisineController,
              hint: 'Cuisine Type e.g. local, Italian, Chinese, Fast Food',
              prefixIcon: Icons.restaurant_menu_outlined,
              validator: (v) {
                if (_signupRole == 'restaurant' &&
                    (v == null || v.trim().isEmpty)) {
                  return 'Cuisine type is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _addressController,
              hint: 'Restaurant Address',
              prefixIcon: Icons.location_on_outlined,
              validator: (v) {
                if (_signupRole == 'restaurant' &&
                    (v == null || v.trim().isEmpty)) {
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
                color: AppColors.textHint(context),
                size: 20,
              ),
              onPressed: () => setState(() => _obscureSignup = !_obscureSignup),
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
                  style: TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
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
            Icon(icon,
                size: 18,
                color: selected ? Colors.black : AppColors.textHint(context)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color:
                        selected ? Colors.black : AppColors.textHint(context))),
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
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.surf,
    required this.border,
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
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: Transform.scale(
        scale: _pressed ? 0.95 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color:
                _pressed ? widget.color.withValues(alpha: 0.08) : widget.surf,
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
      ),
    );
  }
}
  bool otpRequiredFromResponse(Map<String, dynamic> data) {
    return data['otp_required'] == true || data['two_factor'] == true;
  }

