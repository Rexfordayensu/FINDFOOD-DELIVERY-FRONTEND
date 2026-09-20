import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';


class ResetPasswordScreen extends StatefulWidget {
  final String? token;

  const ResetPasswordScreen({super.key, this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _token = widget.token ?? extractResetTokenFromUri(Uri.base);
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final token = _token?.trim();
    if (token == null || token.isEmpty) {
      _showMessage('This reset link is invalid or missing a token.', AppTheme.danger);
      return;
    }

    final newPassword = _newPasswordController.text.trim();
    if (newPassword.isEmpty) {
      _showMessage('Please enter a new password.', AppTheme.danger);
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showMessage('Passwords do not match.', AppTheme.danger);
      return;
    }

    setState(() => _isLoading = true);

   try {
    await ApiService.resetPassword(token, newPassword);
    if (!mounted) return;
    _showMessage('Password reset successfully! Please log in.', AppTheme.success);
    await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      context.go('/login');
    } on PasswordResetException catch (e) {
      if (!mounted) return;
      _showMessage(e.message, AppTheme.danger);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Unable to reset your password. Please try again.', AppTheme.danger);
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
          'Reset password',
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
                  'Create a new password',
                  style: TextStyle(
                    color: textPri,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use a strong password with at least 8 characters and a mix of letters, numbers, and symbols.',
                  style: TextStyle(color: textSec, fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 24),
                if (_token == null || _token!.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.danger.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      'This reset link is invalid or expired. Please request a new reset link.',
                      style: TextStyle(color: textPri, fontSize: 14, height: 1.5),
                    ),
                  )
                else ...[
                  AppTextField(
                    controller: _newPasswordController,
                    hint: 'New password',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscure: _obscureNewPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textHint(context),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Password is required';
                      if (value.length < 8) return 'Use at least 8 characters';
                      if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+').hasMatch(value)) {
                        return 'Include letters and numbers';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _confirmPasswordController,
                    hint: 'Confirm new password',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscure: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textHint(context),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Please confirm your password';
                      if (value != _newPasswordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Reset password',
                    icon: Icons.check_rounded,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _submit,
                  ),
                ],
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text(
                    'Back to sign in',
                    style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
String extractResetTokenFromUri(Uri uri) {
  return uri.queryParameters['token'] ?? '';
}
