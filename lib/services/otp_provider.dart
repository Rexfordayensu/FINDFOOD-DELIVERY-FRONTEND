import 'dart:async';
import 'package:flutter/material.dart';

/// Provider for managing OTP verification state and countdown timers.
class OtpProvider extends ChangeNotifier {
  Timer? _expiryTimer;
  Timer? _resendTimer;

  int _otpExpirySeconds = 0;
  int _resendCooldownSeconds = 0;
  
  String? _email;
  String? _verificationErrorMessage;
  bool _isVerifying = false;
  bool _isResending = false;

  int get otpExpirySeconds => _otpExpirySeconds;
  int get resendCooldownSeconds => _resendCooldownSeconds;
  String? get email => _email;
  String? get verificationErrorMessage => _verificationErrorMessage;
  bool get isVerifying => _isVerifying;
  bool get isResending => _isResending;

  bool get canResend => _resendCooldownSeconds == 0;
  bool get otpExpired => _otpExpirySeconds == 0;

  String get otpExpiryFormatted {
    final minutes = _otpExpirySeconds ~/ 60;
    final seconds = _otpExpirySeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get resendCooldownFormatted {
    final minutes = _resendCooldownSeconds ~/ 60;
    final seconds = _resendCooldownSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Start OTP verification flow
  void startVerification(String email) {
    _email = email;
    _verificationErrorMessage = null;
    _isVerifying = false;
    _isResending = false;

    // Start timers
    startOtpExpiryTimer();
    startResendCooldownTimer();
    
    notifyListeners();
  }

  /// Start OTP expiry countdown (10 minutes = 600 seconds)
  void startOtpExpiryTimer() {
    _expiryTimer?.cancel();
    _otpExpirySeconds = 600; // 10 minutes
    notifyListeners();

    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpExpirySeconds > 0) {
        _otpExpirySeconds--;
        notifyListeners();
      } else {
        timer.cancel();
        notifyListeners();
      }
    });
  }

  /// Start resend OTP cooldown (2 minutes = 120 seconds)
  void startResendCooldownTimer() {
    _resendTimer?.cancel();
    _resendCooldownSeconds = 120; // 2 minutes
    notifyListeners();

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldownSeconds > 0) {
        _resendCooldownSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
        notifyListeners();
      }
    });
  }

  /// Set verification loading state
  void setVerifying(bool value) {
    _isVerifying = value;
    notifyListeners();
  }

  /// Set resending loading state
  void setResending(bool value) {
    _isResending = value;
    notifyListeners();
  }

  /// Set verification error message
  void setVerificationError(String? message) {
    _verificationErrorMessage = message;
    notifyListeners();
  }

  /// Clear all timers and reset state
  void resetVerification() {
    _expiryTimer?.cancel();
    _resendTimer?.cancel();
    _otpExpirySeconds = 0;
    _resendCooldownSeconds = 0;
    _email = null;
    _verificationErrorMessage = null;
    _isVerifying = false;
    _isResending = false;
    notifyListeners();
  }

  /// Handle successful resend - restart both timers
  void handleSuccessfulResend() {
    _verificationErrorMessage = null;
    _isResending = false;
    startOtpExpiryTimer();
    startResendCooldownTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }
}
