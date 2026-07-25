# Email OTP Verification Flow - Implementation Guide

## Overview

This document describes the complete email OTP verification flow implementation for the FindFood Flutter app. The system handles email verification for all user types (Customer, Rider, Restaurant, Admin) with proper error handling, countdown timers, and role-based navigation.

## Architecture

### New Files Created

#### 1. **lib/services/otp_provider.dart**
- Manages OTP verification state and countdown timers
- Provides:
  - `startVerification()` - Initialize verification flow
  - `startOtpExpiryTimer()` - 10-minute countdown timer
  - `startResendCooldownTimer()` - 2-minute resend cooldown
  - `setVerifying()` - Track verification request state
  - `setResending()` - Track resend request state
  - `handleSuccessfulResend()` - Reset timers after successful resend
  - `resetVerification()` - Clear all state

#### 2. **lib/screens/auth/email_verification_screen.dart**
- Main UI for email verification
- Features:
  - App logo and branding
  - Email display
  - OTP input widget
  - Countdown timers (OTP expiry and resend)
  - Verify button with loading state
  - Resend OTP button with cooldown
  - Error message display
  - Success animation
  - Role-based navigation after verification

#### 3. **lib/screens/restaurant/restaurant_pending_approval_screen.dart**
- Screen shown to restaurants after email verification
- Explains that restaurant is pending admin approval
- Shows estimated approval time (24-48 hours)
- Provides logout button to return to login

#### 4. **lib/widgets/otp_input_widget.dart**
- Custom 6-digit OTP input widget
- Features:
  - Individual boxes for each digit
  - Auto-focus on first box
  - Auto-move to next box on digit entry
  - Support for pasting entire 6-digit OTP
  - Clear button to reset input
  - Responsive design
  - Dark/light mode support

### Modified Files

#### 1. **lib/services/api_service.dart**
- Added `EmailNotVerifiedException` class for 403 errors
- Added `verifyEmail()` method - POST /auth/verify-email
- Added `resendOtp()` method - POST /auth/resend-otp
- Modified `login()` to throw `EmailNotVerifiedException` on 403

#### 2. **lib/services/providers.dart**
- Extended `AuthProvider` with:
  - `_email` - User's email address
  - `_isEmailVerified` - Email verification status
  - `_isRestaurantApproved` - Restaurant approval status
  - `setEmailVerified()` - Update verification status
  - `setRestaurantApproved()` - Update approval status
  - `setEmail()` - Store email address

#### 3. **lib/screens/auth/login_screen.dart**
- Modified `_login()` to handle `EmailNotVerifiedException`
- Redirects to `EmailVerificationScreen` on 403
- Prefills email address
- Modified `_register()` to navigate to verification screen instead of auto-logging in
- Clears form after successful registration

#### 4. **lib/main.dart**
- Added `OtpProvider` to MultiProvider
- Added deep link handling placeholder
- Converted `FindFoodApp` to StatefulWidget for deep link support

## User Flows

### Registration Flow
```
User Registration
    ↓
Registration Success
    ↓
Navigate to Email Verification Screen
    ├─ Pre-fill email
    ├─ Display role
    └─ Start timers
```

### Login Flow (Unverified Email)
```
User Login
    ↓
403 Response: Email Not Verified
    ↓
Navigate to Email Verification Screen
    ├─ Pre-fill email
    ├─ Role determined from verification response
    └─ Start timers
```

### Verification Success Flow (Customer/Rider)
```
Email Verification Success
    ↓
Store email verification status
    ↓
Navigate to home screen
    ├─ Customer → Food Feed Screen
    └─ Rider → Rider Dashboard
```

### Verification Success Flow (Restaurant)
```
Email Verification Success
    ↓
Store email verification status
    ↓
Display Pending Approval Screen
    ├─ Explain approval process
    ├─ Show estimated time
    └─ Provide logout option
```

## Countdown Timers

### OTP Expiry Timer
- Duration: 10 minutes (600 seconds)
- Format: MM:SS (e.g., 09:59)
- Display: "OTP expires in: [MM:SS]"
- On expiry:
  - Display: "Verification code expired. Please request a new code."
  - Disable Verify button
  - User must click Resend to get new OTP

### Resend Cooldown Timer
- Duration: 2 minutes (120 seconds)
- Format: MM:SS (e.g., 02:00)
- Display: "Resend available in [MM:SS]"
- On expiry:
  - Enable Resend button
  - Display: "Didn't receive the code?"
  - User can click Resend button

### Timer Reset
Both timers reset after successful resend OTP

## API Endpoints

### POST /auth/verify-email
Request:
```json
{
  "email": "user@example.com",
  "otp": "123456"
}
```

Response (200):
```json
{
  "message": "Email verified successfully",
  "is_verified": true,
  "is_approved": false,
  "role": "customer"
}
```

Response (4xx):
```json
{
  "detail": "Invalid OTP" | "OTP expired" | "Too many attempts"
}
```

### POST /auth/resend-otp
Request:
```json
{
  "email": "user@example.com"
}
```

Response (200):
```json
{
  "message": "OTP sent successfully"
}
```

Response (4xx):
```json
{
  "detail": "Please wait XX seconds"
}
```

## Security Considerations

### Never Store/Log
- OTP values
- Passwords
- Sensitive tokens

### Implemented
- ✅ Email trimming
- ✅ OTP trimming
- ✅ OTP validation (length check)
- ✅ Prevent duplicate verification requests
- ✅ Prevent duplicate resend requests
- ✅ Disable buttons during requests
- ✅ Generic error messages for network failures
- ✅ Timeout handling
- ✅ No OTP logging

## Error Handling

### Verification Errors
- Invalid OTP
- OTP expired
- Too many attempts
- Server errors
- Network timeouts

### Resend Errors
- Too many resend requests
- Server errors
- Network timeouts

### Display
- Error messages shown in UI
- User remains on verification screen
- Can retry or resend

## User Experience Features

### Loading Indicators
- Verify button shows spinner while verifying
- Resend button shows spinner while resending

### Keyboard Management
- Auto-focus first OTP input box
- Keyboard dismissed after verification success
- Auto-move between OTP boxes

### Responsive Design
- Works on all screen sizes
- Adapts to landscape orientation
- Dark/Light mode support
- ScrollView for small screens

### Success Feedback
- Success animation before navigation
- Loading state prevents accidental double-taps
- Smooth transitions between screens

## Deep Link Support (Future Enhancement)

Current placeholder for deep link handling. To implement:

1. Add `app_links` package to pubspec.yaml
2. Configure Android deep links in AndroidManifest.xml
3. Configure iOS deep links in Info.plist
4. Parse deep link URL in `_handleDeepLink()` in main.dart
5. Navigate to `EmailVerificationScreen` with pre-filled email

Example deep link: `https://findfood.com/verify-email?email=user@example.com`

## Testing Checklist

- [ ] Registration → Email Verification → Success (Customer)
- [ ] Registration → Email Verification → Success (Rider)
- [ ] Registration → Email Verification → Pending Approval (Restaurant)
- [ ] Login with unverified email → Email Verification
- [ ] OTP expiry countdown works
- [ ] Resend cooldown works
- [ ] Resend clears previous OTP
- [ ] Resend resets both timers
- [ ] Invalid OTP error handling
- [ ] Network error handling
- [ ] Timeout handling
- [ ] Dark/Light mode support
- [ ] Responsive on different screen sizes
- [ ] OTP paste from clipboard (6 digits)
- [ ] Auto-move between OTP boxes
- [ ] Clear button works
- [ ] Prevent back navigation during verification
- [ ] Loading states prevent duplicate requests

## Configuration Notes

### API Endpoint Base URL
- Currently: `http://127.0.0.1:8000`
- Update in `ApiService.baseUrl` for production

### Timer Durations
- OTP Expiry: 10 minutes (600 seconds) - Configure in `OtpProvider.startOtpExpiryTimer()`
- Resend Cooldown: 2 minutes (120 seconds) - Configure in `OtpProvider.startResendCooldownTimer()`

### Restaurant Approval
- Restaurants see pending approval screen after email verification
- Email verification (`is_verified`) is separate from admin approval (`is_approved`)
- Only admins can change `is_approved` status
- Restaurants cannot access features until `is_approved = true`

## Troubleshooting

### OTP Not Arriving
- Check backend is sending email
- Check spam folder
- Use Resend OTP button after 2-minute cooldown

### Verification Screen Not Showing
- Check email verification endpoint is accessible
- Verify API response format
- Check error logs for exceptions

### Timers Not Working
- Ensure `OtpProvider` is in MultiProvider
- Check no disposed widgets are being accessed
- Verify timers are started with `startVerification()`

### Navigation Issues
- Ensure all screen imports are correct
- Check `WillPopScope` prevents back navigation
- Verify role-based routing logic
