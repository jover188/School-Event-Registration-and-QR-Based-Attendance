import 'dart:async';
import 'package:flutter/material.dart';
import '../../screens/auth/login_screen.dart';
import '../animations/app_animations.dart';
import '../theme/app_tokens.dart';
import 'app_spinner.dart';

/// Animated startup splash screen for Attendify.
///
/// Features:
/// - Prominent Attendify logo (`assets/images/logo_mark.png`) adapting to theme.
/// - Smooth entrance fade-in and subtle scale-up animation.
/// - Clean typography with brand title and subtitle.
/// - Minimal animated loading indicator matching theme.
/// - Waits for both [initialScreenFuture] and [minimumDuration] before
///   smoothly replacing the route with the resolved screen.
/// - Gracefully handles long initialization without flashing or freezing.
/// - Prevents replaying on rebuilds.
/// - Exposes [buildStaticForTesting] for test harnesses.
class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({
    super.key,
    required this.initialScreenFuture,
    this.minimumDuration = const Duration(milliseconds: 1200),
    this.autoNavigate = true,
  });

  /// Future resolving to the resolved initial screen (LoginScreen or role dashboard).
  final Future<Widget> initialScreenFuture;

  /// Minimum duration to display the branded splash screen. Defaults to 1200ms.
  final Duration minimumDuration;

  /// Whether to automatically navigate to the target screen once resolved.
  /// Set to false in test harnesses verifying the static splash screen layout.
  final bool autoNavigate;

  /// Factory helper for test harnesses to construct a static, non-animating splash screen.
  static Widget buildStaticForTesting({
    Widget? initialScreen,
    bool autoNavigate = false,
  }) {
    return AppSplashScreen(
      initialScreenFuture: Future.value(initialScreen ?? const SizedBox()),
      minimumDuration: Duration.zero,
      autoNavigate: autoNavigate,
    );
  }

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  bool _hasNavigated = false;
  bool _startupCoordinated = false;
  Timer? _delayTimer;
  Completer<void>? _timerCompleter;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    final curved = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(curved);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (disableAnimations) {
      _animController.value = 1.0;
    } else if (!_animController.isAnimating && _animController.value == 0.0) {
      _animController.forward();
    }

    if (!_startupCoordinated && widget.autoNavigate) {
      _startupCoordinated = true;
      _coordinateStartup(disableAnimations: disableAnimations);
    }
  }

  Future<void> _coordinateStartup({bool disableAnimations = false}) async {
    try {
      final safeFuture = widget.initialScreenFuture.catchError((_) {
        return const LoginScreen();
      });

      final effectiveDuration =
          disableAnimations ? Duration.zero : widget.minimumDuration;

      _timerCompleter = Completer<void>();
      if (effectiveDuration > Duration.zero) {
        _delayTimer = Timer(effectiveDuration, () {
          if (_timerCompleter != null && !_timerCompleter!.isCompleted) {
            _timerCompleter!.complete();
          }
        });
      } else {
        _timerCompleter!.complete();
      }

      final results = await Future.wait([
        safeFuture,
        _timerCompleter!.future,
      ]);

      if (!mounted || _hasNavigated) return;
      final targetWidget = results[0] as Widget;
      _navigate(targetWidget);
    } catch (_) {
      if (!mounted || _hasNavigated) return;
      _navigate(const LoginScreen());
    }
  }

  void _navigate(Widget targetScreen) {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    final navigator = Navigator.maybeOf(context);
    if (navigator == null) return;

    navigator.pushReplacement(
      AppPageRoute<void>(
        builder: (_) => targetScreen,
      ),
    );
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _delayTimer = null;
    if (_timerCompleter != null && !_timerCompleter!.isCompleted) {
      _timerCompleter!.complete();
    }
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Attendify Logo
          Semantics(
            label: 'Attendify Logo',
            image: true,
            child: Image.asset(
              'assets/images/logo_mark.png',
              key: const ValueKey<String>('attendify-splash-logo'),
              width: 88,
              height: 88,
              fit: BoxFit.contain,
              color: d.foreground,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.school_rounded,
                size: 72,
                color: d.foreground,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 'Attendify' Brand Title
          Text(
            'Attendify',
            key: const ValueKey<String>('attendify-splash-title'),
            style: TextStyle(
              fontFamily: AppPalette.fontFamily,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: d.foreground,
            ),
          ),
          const SizedBox(height: 6),

          // 'School Event Attendance' Subtitle
          Text(
            'School Event Attendance',
            key: const ValueKey<String>('attendify-splash-subtitle'),
            style: TextStyle(
              fontFamily: AppPalette.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              color: d.mutedForeground,
            ),
          ),
          const SizedBox(height: 48),

          // Minimal animated loading indicator
          AppSpinner(
            key: const ValueKey<String>('attendify-splash-spinner'),
            size: 22,
            color: d.mutedForeground,
            strokeWidth: 2.2,
            variant: AppSpinnerVariant.loader2,
            semanticsLabel: 'Initializing Attendify',
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: d.background,
      body: disableAnimations
          ? content
          : AnimatedBuilder(
              animation: _animController,
              builder: (context, child) => FadeTransition(
                opacity: _fadeAnimation,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              ),
              child: content,
            ),
    );
  }
}
