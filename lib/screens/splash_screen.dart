import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  /// The screen to navigate to after the animation completes
  final Widget destination;

  const SplashScreen({super.key, required this.destination});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _popInCtrl;
  late Animation<double>   _scaleAnim;
  late Animation<double>   _opacityAnim;
  late Animation<double>   _glowAnim;

  late AnimationController _textCtrl;
  late Animation<double>   _textSlide;
  late Animation<double>   _textOpacity;

  late AnimationController _tagCtrl;
  late Animation<double>   _tagOpacity;

  late AnimationController _outCtrl;
  late Animation<double>   _outScale;
  late Animation<double>   _outOpacity;
  late Animation<Color?>   _bgColor;

  @override
  void initState() {
    super.initState();

    _popInCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.18)
              .chain(CurveTween(curve: Curves.easeOutCubic)),
          weight: 55),
      TweenSequenceItem(
          tween: Tween(begin: 1.18, end: 0.95)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 25),
      TweenSequenceItem(
          tween: Tween(begin: 0.95, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 20),
    ]).animate(_popInCtrl);

    _opacityAnim = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _popInCtrl,
            curve: const Interval(0.0, 0.3, curve: Curves.easeIn)));

    _glowAnim = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _popInCtrl,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOut)));

    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _textSlide = Tween(begin: 24.0, end: 0.0).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    _textOpacity = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    _tagCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _tagOpacity = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _tagCtrl, curve: Curves.easeIn));

    _outCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));

    _outScale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.88)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 0.88, end: 4.0)
              .chain(CurveTween(curve: Curves.easeInCubic)),
          weight: 70),
    ]).animate(_outCtrl);

    _outOpacity = Tween(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _outCtrl,
            curve: const Interval(0.5, 1.0, curve: Curves.easeIn)));

    _bgColor = ColorTween(
        begin: const Color(0xFF0A0A0A),
        end: const Color(0xFFFFD700)).animate(
        CurvedAnimation(parent: _outCtrl,
            curve: const Interval(0.0, 0.6, curve: Curves.easeIn)));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    await _popInCtrl.forward();
    
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    await _textCtrl.forward();
    
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    await _tagCtrl.forward();
    
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    await _outCtrl.forward();
    
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => widget.destination,
        transitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _popInCtrl.dispose();
    _textCtrl.dispose();
    _tagCtrl.dispose();
    _outCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Explicitly cast Listenable.merge to clear compile analyzer type errors
    return AnimatedBuilder(
      animation: Listenable.merge([_popInCtrl, _textCtrl, _tagCtrl, _outCtrl]),
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          backgroundColor: _bgColor.value ?? const Color(0xFF0A0A0A),
          body: Center(
            child: Opacity(
              opacity: _outOpacity.value.clamp(0.0, 1.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo ────────────────────────────────────
                  Transform.scale(
                    scale: (_outCtrl.isAnimating
                            ? _outScale.value
                            : _scaleAnim.value)
                        .clamp(0.0, 10.0),
                    child: Opacity(
                      opacity: _opacityAnim.value.clamp(0.0, 1.0),
                      child: AnimatedBuilder(
                        animation: _glowAnim,
                        builder: (_, __) => Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700)
                                    .withValues(alpha: 0.65 * _glowAnim.value),
                                blurRadius: 44 * _glowAnim.value,
                                spreadRadius: 10 * _glowAnim.value,
                              ),
                              BoxShadow(
                                color: const Color(0xFFFFD700)
                                    .withValues(alpha: 0.3 * _glowAnim.value),
                                blurRadius: 90 * _glowAnim.value,
                                spreadRadius: 22 * _glowAnim.value,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.fastfood_rounded,
                              color: Colors.black, size: 50),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Brand name ───────────────────────────────
                  Transform.translate(
                    offset: Offset(0, _textSlide.value),
                    child: Opacity(
                      opacity: _textOpacity.value.clamp(0.0, 1.0),
                      child: AnimatedBuilder(
                        animation: _outCtrl,
                        builder: (_, __) => Text(
                          'FINDFOOD',
                          style: TextStyle(
                            color: _outCtrl.isAnimating
                                ? Color.lerp(Colors.white, Colors.black,
                                    (_outCtrl.value * 2).clamp(0.0, 1.0))
                                : Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Tagline ──────────────────────────────────
                  Opacity(
                    opacity: (_tagOpacity.value *
                            (1 - _outCtrl.value * 2).clamp(0.0, 1.0))
                        .clamp(0.0, 1.0),
                    child: const Text(
                      'Food delivery, done fast.',
                      style: TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 15,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}