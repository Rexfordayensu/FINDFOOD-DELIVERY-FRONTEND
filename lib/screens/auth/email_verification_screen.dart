import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../services/api_service.dart';
import '../../services/providers.dart';
import '../../services/otp_provider.dart';
import '../../widgets/otp_input_widget.dart';

enum VerificationMode { registration, login }

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String role;
  final VerificationMode mode;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.role,
    this.mode = VerificationMode.registration,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with WidgetsBindingObserver {
  late TextEditingController _otpController;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
    WidgetsBinding.instance.addObserver(this);

    // Start verification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OtpProvider>(context, listen: false)
          .startVerification(widget.email);
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().length != 6) {
      _showErrorSnackBar('Please enter a valid 6-digit code');
      return;
    }

    final otpProvider = Provider.of<OtpProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    otpProvider.setVerifying(true);
    otpProvider.setVerificationError(null);

    try {
      if (widget.mode == VerificationMode.registration) {
        final response = await ApiService.verifyEmail(
          email: widget.email,
          otp: _otpController.text.trim(),
        );

        if (!mounted) return;

        // Determine role from response if available, otherwise use passed role
        final role = response['role'] as String? ?? widget.role;
        final isApproved = response['is_approved'] as bool? ?? false;

        // Update auth provider
        authProvider.setEmailVerified(true);
        authProvider.setRestaurantApproved(isApproved);
        if (role.isNotEmpty) {
          authProvider.setEmail(widget.email);
        }

        setState(() {
          _showSuccess = true;
        });

        // Navigate after delay
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;

        _navigateToNextScreen(role);
      } else {
        // Login verification: verify and perform login flow
        final data = await ApiService.verifyLoginOtp(
          email: widget.email,
          otp: _otpController.text.trim(),
        );

        if (!mounted) return;

        // Expected: access_token, refresh_token?, role, user_id, is_approved?
        final token = data['access_token'] as String?;
        final role = data['role'] as String? ?? widget.role;
        final userId = (data['user_id'] is int) ? data['user_id'] as int : int.tryParse('${data['user_id']}') ?? 0;
        final isApproved = data['is_approved'] as bool? ?? false;

        if (token == null) {
          throw Exception('Invalid login response from server');
        }

        // Login the user in the provider
        authProvider.login(
          token: token,
          userId: userId,
          role: role,
          email: widget.email,
          isEmailVerified: true,
          isRestaurantApproved: isApproved,
        );

        // Clear OTP from memory
        _otpController.clear();

        setState(() {
          _showSuccess = true;
        });

        // Navigate after short delay
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;

        _navigateToNextScreen(role);
      }
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      otpProvider.setVerificationError(errorMsg);
      _showErrorSnackBar(errorMsg);
    } finally {
      if (mounted) {
        otpProvider.setVerifying(false);
      }
    }
  }

  Future<void> _resendOtp() async {
    final otpProvider = Provider.of<OtpProvider>(context, listen: false);
    otpProvider.setResending(true);
    otpProvider.setVerificationError(null);

    try {
      if (widget.mode == VerificationMode.registration) {
        await ApiService.resendOtp(email: widget.email);
      } else {
        await ApiService.resendLoginOtp(email: widget.email);
      }

      if (!mounted) return;

      // Clear OTP input
      _otpController.clear();

      // Reset timers
      otpProvider.handleSuccessfulResend();

      _showSuccessSnackBar('A new verification code has been sent.');
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      otpProvider.setVerificationError(errorMsg);
      _showErrorSnackBar(errorMsg);
    } finally {
      if (mounted) {
        otpProvider.setResending(false);
      }
    }
  }

  void _navigateToNextScreen([String? overrideRole]) {
    final role = overrideRole ?? widget.role;
    if (widget.mode == VerificationMode.registration) {
      context.go('/login');
      return;
    }

    final route = switch (role) {
      'restaurant' => Provider.of<AuthProvider>(context, listen: false).isRestaurantApproved
          ? '/restaurant/orders'
          : '/restaurant/pending',
      'rider' => '/rider',
      'admin' => '/admin',
      _ => '/',
    };
    context.go(route);
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.danger,
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.success,
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Consumer<OtpProvider>(
          builder: (context, otpProvider, _) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // App Logo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.mail_outline_rounded,
                        size: 48,
                        color: AppTheme.accent,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                      widget.mode == VerificationMode.registration
                          ? 'Verify your email'
                          : 'Login Verification',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      widget.mode == VerificationMode.registration
                          ? "We've sent a 6-digit verification code to"
                          : "We've sent a login verification code to your email.\n\nEnter the code below to continue signing in.",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.darkTextSec
                            : AppTheme.lightTextSec,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 4),

                    // Email
                    Text(
                      widget.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accent,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Verify Button
                    OtpInputWidget(
                      controller: _otpController,
                      onChanged: (value) {},
                      enabled: !otpProvider.isVerifying && !_showSuccess,
                    ),

                    const SizedBox(height: 32),

                    // Error Message
                    if (otpProvider.verificationErrorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.danger.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppTheme.danger,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                otpProvider.verificationErrorMessage!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // OTP Expiry Countdown
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.darkCard
                            : AppTheme.lightCard,
                        border: Border.all(
                          color: otpProvider.otpExpired
                              ? AppTheme.danger.withValues(alpha: 0.3)
                              : AppTheme.accent.withValues(alpha: 0.2),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 18,
                            color: otpProvider.otpExpired
                                ? AppTheme.danger
                                : AppTheme.accent,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'OTP expires in:',
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? AppTheme.darkTextSec
                                      : AppTheme.lightTextSec,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                otpProvider.otpExpiryFormatted,
                                style: TextStyle(
                                  color: otpProvider.otpExpired
                                      ? AppTheme.danger
                                      : AppTheme.accent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (otpProvider.isVerifying ||
                                    otpProvider.otpExpired ||
                                    _showSuccess)
                            ? null
                            : _verifyOtp,
                        child: otpProvider.isVerifying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.darkBg,
                                  ),
                                ),
                              )
                            : _showSuccess
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle_rounded, size: 20),
                                      SizedBox(width: 8),
                                      Text('Verified'),
                                    ],
                                  )
                                : const Text('Verify Email'),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Resend OTP Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.darkSurface
                            : AppTheme.lightSurface,
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.darkBorder
                              : AppTheme.lightBorder,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          if (!otpProvider.canResend)
                            Text(
                              'Resend available in ${otpProvider.resendCooldownFormatted}',
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? AppTheme.darkTextSec
                                    : AppTheme.lightTextSec,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            )
                          else
                            Column(
                              children: [
                                Text(
                                  "Didn't receive the code?",
                                  style: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? AppTheme.darkTextSec
                                        : AppTheme.lightTextSec,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: OutlinedButton(
                                    onPressed: otpProvider.isResending
                                        ? null
                                        : _resendOtp,
                                    child: otpProvider.isResending
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                AppTheme.accent,
                                              ),
                                            ),
                                          )
                                        : const Text('Resend Code'),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
