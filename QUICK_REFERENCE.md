# Email OTP Verification - Quick Reference & Testing Guide

## Files Overview

### Core Components
| File | Purpose | Key Classes |
|------|---------|------------|
| `lib/services/otp_provider.dart` | OTP state & timers | `OtpProvider` |
| `lib/services/api_service.dart` | API methods | `verifyEmail()`, `resendOtp()` |
| `lib/services/providers.dart` | Auth state | `AuthProvider` (extended) |
| `lib/widgets/otp_input_widget.dart` | OTP input UI | `OtpInputWidget` |
| `lib/screens/auth/email_verification_screen.dart` | Verification UI | `EmailVerificationScreen` |
| `lib/screens/restaurant/restaurant_pending_approval_screen.dart` | Approval waiting | `RestaurantPendingApprovalScreen` |
| `lib/main.dart` | App entry point | Deep link handler |

## API Integration

### Verify Email Endpoint
```
POST /auth/verify-email
Content-Type: application/json

{
  "email": "user@example.com",
  "otp": "123456"
}

Response 200:
{
  "message": "Email verified successfully",
  "is_verified": true,
  "is_approved": false,
  "role": "customer"
}

Response 4xx:
{
  "detail": "Invalid OTP"
}
```

### Resend OTP Endpoint
```
POST /auth/resend-otp
Content-Type: application/json

{
  "email": "user@example.com"
}

Response 200:
{
  "message": "OTP sent successfully"
}

Response 4xx:
{
  "detail": "Please wait 45 seconds"
}
```

## Testing Scenarios

### Scenario 1: New Customer Registration
```
1. Open app → Login Screen
2. Click "Sign Up" tab
3. Select "Customer" role
4. Fill in: Name, Email, Password
5. Click "Sign Up"
   ↓ Navigate to Email Verification Screen
6. Enter OTP from email
7. Click "Verify Email"
   ↓ Success
   ↓ Navigate to Food Feed Screen
```

### Scenario 2: New Rider Registration
```
1. Open app → Login Screen
2. Click "Sign Up" tab
3. Select "Rider" role
4. Fill in: Name, Email, Password
5. Click "Sign Up"
   ↓ Navigate to Email Verification Screen
6. Enter OTP from email
7. Click "Verify Email"
   ↓ Success
   ↓ Navigate to Rider Dashboard
```

### Scenario 3: New Restaurant Registration
```
1. Open app → Login Screen
2. Click "Sign Up" tab
3. Select "Restaurant" role
4. Fill in: Name, Email, Password, Cuisine, Address
5. Click "Sign Up"
   ↓ Navigate to Email Verification Screen
6. Enter OTP from email
7. Click "Verify Email"
   ↓ Success
   ↓ Navigate to Pending Approval Screen
   ↓ Show "Awaiting approval" message
```

### Scenario 4: Login with Unverified Email
```
1. Open app → Login Screen
2. Enter email & password for unverified account
3. Click "Sign In"
   ↓ Backend returns 403: Email not verified
   ↓ Navigate to Email Verification Screen
4. Enter OTP from email
5. Click "Verify Email"
   ↓ Success
   ↓ Navigate to appropriate home screen
```

### Scenario 5: Invalid OTP
```
1. On Email Verification Screen
2. Enter incorrect 6-digit code
3. Click "Verify Email"
   ↓ Error: "Invalid OTP"
   ↓ Stay on verification screen
   ↓ User can retry
```

### Scenario 6: Expired OTP
```
1. On Email Verification Screen
2. Wait for 10-minute countdown to reach 00:00
   ↓ "OTP expires in: 00:00" displayed
   ↓ Error message shown: "Verification code expired"
   ↓ Verify button disabled
3. Click "Resend Code" (after 2-minute cooldown)
   ↓ New OTP sent
   ↓ Countdown resets to 10:00
```

### Scenario 7: Resend OTP
```
1. On Email Verification Screen
2. Wait for 2-minute resend cooldown to reach 00:00
   ↓ "Resend available in: 00:00" changes to resend button
3. Click "Resend Code"
   ↓ Loading spinner shows
   ↓ "A new verification code has been sent" message
   ↓ Previous OTP input cleared
   ↓ Both timers reset (10:00 and 02:00)
```

### Scenario 8: OTP Paste from Clipboard
```
1. On Email Verification Screen
2. Copy "123456" to clipboard
3. Long-press first OTP box
4. Select "Paste"
   ↓ All 6 boxes populate: 1|2|3|4|5|6
   ↓ Focus moves to last box
```

## Key Implementation Details

### OTP Provider State
```dart
// Access in widgets via:
context.watch<OtpProvider>()

// Key properties:
otpProvider.otpExpirySeconds       // Remaining time (seconds)
otpProvider.resendCooldownSeconds  // Resend wait time (seconds)
otpProvider.otpExpiryFormatted     // "MM:SS" format
otpProvider.canResend              // Boolean
otpProvider.isVerifying            // Loading state
otpProvider.isResending            // Loading state
```

### Auth Provider Updates
```dart
// After successful verification:
authProvider.setEmailVerified(true)
authProvider.setRestaurantApproved(isApproved)
authProvider.setEmail(userEmail)
```

### Error Messages
```dart
// Backend errors are displayed as-is:
- "Invalid OTP"
- "OTP expired"
- "Too many attempts"
- "Please wait 45 seconds"

// Generic errors shown for network issues:
- Network timeout
- Server unavailable
```

## Code Navigation

### To customize timer durations:
```dart
// File: lib/services/otp_provider.dart
// Method: startOtpExpiryTimer()
_otpExpirySeconds = 600; // Change this (in seconds)

// Method: startResendCooldownTimer()
_resendCooldownSeconds = 120; // Change this (in seconds)
```

### To customize OTP input styling:
```dart
// File: lib/widgets/otp_input_widget.dart
// Modify box dimensions, colors, fonts in build() method
```

### To change API base URL:
```dart
// File: lib/services/api_service.dart
static const String baseUrl = 'http://127.0.0.1:8000';
// Change this for production
```

## Debugging Tips

### OTP Provider Not Working
```dart
// In main.dart, verify OtpProvider is in MultiProvider:
ChangeNotifierProvider(create: (_) => OtpProvider()),

// Check provider is being accessed correctly:
context.watch<OtpProvider>()  // For rebuilds
context.read<OtpProvider>()   // For one-time reads
```

### Verification Screen Not Showing
```dart
// Check imports in login_screen.dart:
import '../../screens/auth/email_verification_screen.dart';

// Verify navigation is working:
Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (_) => EmailVerificationScreen(
      email: registrationEmail,
      role: registrationRole,
    ),
  ),
);
```

### Email Not Being Filled
```dart
// Ensure email is being passed and stored:
EmailVerificationScreen(
  email: userEmail,  // Must be non-empty
  role: userRole,
)

// Display in screen via:
Text(widget.email)  // Should show user@example.com
```

## Production Checklist

- [ ] Update `ApiService.baseUrl` to production URL
- [ ] Configure deep links (Android & iOS)
- [ ] Test all error scenarios with backend
- [ ] Verify email sending is configured
- [ ] Set timer durations appropriately
- [ ] Test dark/light mode
- [ ] Test on multiple devices/orientations
- [ ] Load test verification endpoints
- [ ] Set up monitoring for OTP endpoint
- [ ] Document OTP delivery SLA
- [ ] Test restaurant approval workflow

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| OTP not arriving | Check backend email service, check spam folder |
| Timers not counting | Ensure OtpProvider is in MultiProvider |
| Back button works during verification | Should be prevented by WillPopScope |
| OTP boxes not auto-filling on paste | Check input formatter accepts digits |
| Screen showing wrong role | Verify role is passed from registration or response |
| Can verify with empty OTP | Length validation (6 digits) should prevent |
| Resend too fast | 2-minute cooldown should prevent |
