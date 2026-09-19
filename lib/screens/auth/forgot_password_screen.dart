import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSubmitted = false;
  String _serverMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Email is required.', AppTheme.danger);
      return;
    }

    setState(() {
      _isLoading = true;
      _serverMessage = '';
    });

    try {
    await ApiService.forgotPassword(_emailController.text.trim()); // Delete the "final message = " part
    if (!mounted) return;
    
    setState(() {
      _isSubmitted = true;
      _serverMessage = 'Password reset email sent successfully!'; // Use a hardcoded success message string
    });
    
    _showMessage('Success! Check your email.', AppTheme.success); // Use a hardcoded message string here too
    } on PasswordResetException catch (e) {
      if (!mounted) return;
      _showMessage(e.message, AppTheme.danger);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Unable to send the reset request right now. Please try again.', AppTheme.danger);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.bg(context);
    final textPri = AppColors.textPrimary(context);
    final textSec = AppColors.textSecondary(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPri, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Forgot password',
          style: TextStyle(
            color: textPri,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.lock_reset_rounded, color: AppTheme.accent, size: 34),
                ),
                const SizedBox(height: 24),
                Text(
                  _isSubmitted ? 'Check your email' : 'Reset your password',
                  style: TextStyle(
                    color: textPri,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSubmitted
                      ? _serverMessage
                      : 'Enter the email address linked to your account. We will send a password reset link if the account exists.',
                  style: TextStyle(color: textSec, fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 30),
                if (!_isSubmitted) ...[
                  AppTextField(
                    controller: _emailController,
                    hint: 'Email address',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Email is required';
                      final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
                      if (!regex.hasMatch(value.trim())) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Send reset link',
                    icon: Icons.send_rounded,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _submit,
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.success.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      _serverMessage,
                      style: TextStyle(color: textPri, fontSize: 14, height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Back to sign in',
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}