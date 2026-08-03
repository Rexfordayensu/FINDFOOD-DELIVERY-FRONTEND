import 'package:flutter/material.dart';

import 'google_oauth_flow.dart';

class GoogleOAuthScreen extends StatefulWidget {
  const GoogleOAuthScreen({
    super.key,
    this.returnRoute = '/home',
    this.pendingAction,
    this.pendingParameters,
  });

  final String returnRoute;
  final String? pendingAction;
  final Map<String, dynamic>? pendingParameters;

  @override
  State<GoogleOAuthScreen> createState() => _GoogleOAuthScreenState();
}

class _GoogleOAuthScreenState extends State<GoogleOAuthScreen> {
  bool _isLaunchingBrowser = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openBrowser();
    });
  }

  Future<void> _openBrowser() async {
    if (!mounted) return;

    setState(() => _isLaunchingBrowser = true);

    try {
      await GoogleOAuthFlowService.startGoogleAuth(
        context: context,
        route: widget.returnRoute,
        action: widget.pendingAction,
        parameters: widget.pendingParameters,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to start Google sign-in from the browser.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLaunchingBrowser = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Continue with Google'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.open_in_browser, size: 48, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                'Continue with Google',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'The app will open your browser so Google can complete sign-in. Return to the app when the browser flow finishes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isLaunchingBrowser ? null : _openBrowser,
                icon: _isLaunchingBrowser
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.launch),
                label: Text(_isLaunchingBrowser ? 'Opening browser...' : 'Open browser'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
