import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int  _step    = 0; // 0=email, 1=token+pass, 2=success
  bool _loading = false;

  final _emailCtrl   = TextEditingController();
  final _tokenCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;

  final _emailKey = GlobalKey<FormState>();
  final _resetKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_emailKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApiService.forgotPassword(_emailCtrl.text.trim());
      if (!mounted) return;
      setState(() => _step = 1);
      _snack('Reset code sent! Check your uvicorn terminal.', AppTheme.success);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceAll('Exception: ', ''), AppTheme.danger);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_resetKey.currentState!.validate()) return;
    if (_passCtrl.text != _confirmCtrl.text) {
      _snack('Passwords do not match', AppTheme.danger);
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService.resetPassword(
          _tokenCtrl.text.trim(), _passCtrl.text.trim());
      if (!mounted) return;
      setState(() => _step = 2);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceAll('Exception: ', ''), AppTheme.danger);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Text(msg, style: const TextStyle(color: Colors.white)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bg      = AppColors.bg(context);
    final textPri = AppColors.textPrimary(context);
    final textSec = AppColors.textSecondary(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textPri, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Forgot password',
            style: TextStyle(
                color: textPri, fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, anim) => SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(1, 0), end: Offset.zero)
                  .animate(CurvedAnimation(
                      parent: anim, curve: Curves.easeOutCubic)),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: _step == 0
                ? _StepEmail(
                    key: const ValueKey('s0'),
                    ctrl: _emailCtrl,
                    formKey: _emailKey,
                    loading: _loading,
                    textSec: textSec,
                    onSubmit: _sendReset,
                  )
                : _step == 1
                    ? _StepReset(
                        key: const ValueKey('s1'),
                        email: _emailCtrl.text.trim(),
                        tokenCtrl: _tokenCtrl,
                        passCtrl: _passCtrl,
                        confirmCtrl: _confirmCtrl,
                        formKey: _resetKey,
                        loading: _loading,
                        obscure1: _obscure1,
                        obscure2: _obscure2,
                        onToggle1: () =>
                            setState(() => _obscure1 = !_obscure1),
                        onToggle2: () =>
                            setState(() => _obscure2 = !_obscure2),
                        onSubmit: _resetPassword,
                        onResend: () => setState(() => _step = 0),
                      )
                    : _StepSuccess(
                        key: const ValueKey('s2'),
                        onSignIn: () => Navigator.pop(context),
                      ),
          ),
        ),
      ),
    );
  }
}

// ── Step 0 ────────────────────────────────────────────────────────────────────
class _StepEmail extends StatelessWidget {
  final TextEditingController ctrl;
  final GlobalKey<FormState> formKey;
  final bool loading;
  final Color textSec;
  final VoidCallback onSubmit;

  const _StepEmail({
    super.key,
    required this.ctrl,
    required this.formKey,
    required this.loading,
    required this.textSec,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.lock_reset_rounded,
                color: AppTheme.accent, size: 34),
          ),
          const SizedBox(height: 24),
          Text('Reset your password',
              style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4)),
          const SizedBox(height: 8),
          Text(
            "Enter the email linked to your account. "
            "We'll print a reset code to the uvicorn terminal (dev mode).",
            style: TextStyle(color: textSec, fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 32),
          AppTextField(
            controller: ctrl,
            hint: 'Email address',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email required';
              final re = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
              if (!re.hasMatch(v.trim())) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Send reset code',
            isLoading: loading,
            icon: Icons.send_rounded,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

// ── Step 1 ────────────────────────────────────────────────────────────────────
class _StepReset extends StatelessWidget {
  final String email;
  final TextEditingController tokenCtrl, passCtrl, confirmCtrl;
  final GlobalKey<FormState> formKey;
  final bool loading, obscure1, obscure2;
  final VoidCallback onToggle1, onToggle2, onSubmit, onResend;

  const _StepReset({
    super.key,
    required this.email,
    required this.tokenCtrl,
    required this.passCtrl,
    required this.confirmCtrl,
    required this.formKey,
    required this.loading,
    required this.obscure1,
    required this.obscure2,
    required this.onToggle1,
    required this.onToggle2,
    required this.onSubmit,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final textSec  = AppColors.textSecondary(context);
    final textHint = AppColors.textHint(context);
    final textPri  = AppColors.textPrimary(context);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.mark_email_read_outlined,
                color: AppTheme.success, size: 34),
          ),
          const SizedBox(height: 24),
          Text('Check your terminal',
              style: TextStyle(
                  color: textPri,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4)),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(color: textSec, fontSize: 14, height: 1.6),
              children: [
                const TextSpan(text: 'A reset code was printed in your '),
                const TextSpan(
                  text: 'uvicorn terminal',
                  style: TextStyle(
                      color: AppTheme.accent, fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: ' for '),
                TextSpan(
                  text: email,
                  style: TextStyle(
                      color: textPri, fontWeight: FontWeight.w600),
                ),
                const TextSpan(text: '. Paste it below.'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Info box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal_rounded,
                    color: AppTheme.accent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Look for "PASSWORD RESET TOKEN" in your uvicorn terminal',
                    style: TextStyle(
                        color: textPri, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppTextField(
            controller: tokenCtrl,
            hint: 'Paste reset code here',
            prefixIcon: Icons.key_rounded,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Reset code required' : null,
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: passCtrl,
            hint: 'New password',
            prefixIcon: Icons.lock_outline_rounded,
            obscure: obscure1,
            suffixIcon: IconButton(
              icon: Icon(
                  obscure1 ? Icons.visibility_off : Icons.visibility,
                  color: textHint, size: 20),
              onPressed: onToggle1,
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? 'Min 6 characters' : null,
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: confirmCtrl,
            hint: 'Confirm new password',
            prefixIcon: Icons.lock_outline_rounded,
            obscure: obscure2,
            suffixIcon: IconButton(
              icon: Icon(
                  obscure2 ? Icons.visibility_off : Icons.visibility,
                  color: textHint, size: 20),
              onPressed: onToggle2,
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? 'Min 6 characters' : null,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Reset password',
            isLoading: loading,
            icon: Icons.check_rounded,
            onPressed: onSubmit,
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: onResend,
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: textSec, fontSize: 13),
                  children: const [
                    TextSpan(text: "Didn't get a code? "),
                    TextSpan(
                      text: 'Resend',
                      style: TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 2 ────────────────────────────────────────────────────────────────────
class _StepSuccess extends StatelessWidget {
  final VoidCallback onSignIn;
  const _StepSuccess({super.key, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppTheme.success.withValues(alpha: 0.4), width: 2),
            ),
            child: const Icon(Icons.check_rounded,
                color: AppTheme.success, size: 52),
          ),
        ),
        const SizedBox(height: 28),
        Text('Password reset!',
            style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 24,
                fontWeight: FontWeight.w800),
            textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text(
          'Your password has been updated.\nSign in with your new password.',
          style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 14,
              height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        PrimaryButton(
          label: 'Sign in now',
          icon: Icons.login_rounded,
          onPressed: onSignIn,
        ),
      ],
    );
  }
}