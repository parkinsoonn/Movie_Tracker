// ---------------------------------------------------------------------------
// shimmer_loading.dart
// ---------------------------------------------------------------------------
// Reusable shimmer / skeleton placeholder widget.
//
// Uses a repeating opacity animation to simulate a pulsing "loading" effect
// without any third-party dependency. Configurable dimensions and corner
// radius make it composable for cards, avatars, text lines, etc.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class ShimmerLoading extends StatefulWidget {
  /// Width of the skeleton box. Uses parent constraints when `null`.
  final double? width;

  /// Height of the skeleton box.
  final double height;

  /// Corner radius of the skeleton box.
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    this.width,
    this.height = 16.0,
    this.borderRadius = CinephileTheme.radiusMd,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    // A 1.2-second cycle gives a calm, cinematic pulse rather than a frantic
    // flicker — intentionally slower than typical shimmer effects.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          // Pulse between the two surface tones for a subtle glow effect.
          gradient: const LinearGradient(
            colors: [
              CinephileTheme.surfaceContainer,
              CinephileTheme.surfaceContainerHigh,
              CinephileTheme.surfaceContainer,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}
