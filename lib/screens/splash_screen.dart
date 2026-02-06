import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../utils/design_tokens.dart';
import 'main_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const String _target = 'UangBro';
  late String _display;
  Timer? _timer;
  final _rng = Random();
  bool _revealed = false;

  late final AnimationController _logoController;
  late final Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _display = List.generate(_target.length, (_) => _randomChar()).join();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _startScramble();
  }

  String _randomChar() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    return chars[_rng.nextInt(chars.length)];
  }

  void _startScramble() {
    const total = 1800; // ms
    const tick = 60; // ms
    var elapsed = 0;

    _timer = Timer.periodic(const Duration(milliseconds: tick), (t) {
      elapsed += tick;

      final keep = (elapsed / total) * _target.length;
      final keepCount = keep.clamp(0, _target.length).toInt();

      final List<String> chars = List.generate(_target.length, (i) {
        // progressively freeze characters from the left
        if (i < keepCount) return _target[i];
        return _randomChar();
      });

      setState(() => _display = chars.join());

      if (elapsed >= total) {
        t.cancel();
        // final reveal animation
        Future.delayed(const Duration(milliseconds: 120), () {
          setState(() {
            _display = _target;
            _revealed = true;
          });
          _logoController.forward();
        });

        // then navigate to MainWrapper after a short pause
        Future.delayed(const Duration(milliseconds: 1100), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainWrapper()),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [DesignTokens.bg, DesignTokens.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _logoScale,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 450),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(_revealed ? 0.06 : 0.03),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // simple icon circle
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: DesignTokens.primaryGradient,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 400),
                        style: theme.textTheme.headlineSmall!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: _revealed ? 0.6 : 0.0,
                          fontSize: _revealed ? 34 : 32,
                        ),
                        child: Text(_display),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // caption / progress
              SizedBox(
                width: 160,
                child: LinearProgressIndicator(
                  value: null,
                  color: DesignTokens.primary,
                  backgroundColor: Colors.white.withOpacity(0.06),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
