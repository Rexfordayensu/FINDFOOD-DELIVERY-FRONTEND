import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/customer/payment_success_screen.dart';
import 'api_service.dart';
import 'providers.dart';

String? extractPaymentReference(Uri uri) {
  return uri.queryParameters['reference'] ?? uri.queryParameters['trxref'];
}

Future<void> verifyPaymentAndRedirect({
  required BuildContext context,
  required String reference,
  required VoidCallback onSuccess,
}) async {
  final auth = Provider.of<AuthProvider>(context, listen: false);
  if (!auth.isLoggedIn || auth.token == null) {
    onSuccess();
    return;
  }

  try {
    final verification = await ApiService.verifyPayment(
      token: auth.token!,
      reference: reference,
    );

    final status = verification['status']?.toString().toLowerCase();
    if (status == 'success') {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment verified successfully.')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()),
      );
      onSuccess();
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment verification status: ${verification['status'] ?? 'unknown'}')),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unable to verify payment: ${e.toString()}')),
    );
  }
}
