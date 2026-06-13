import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ScanAnimationWidget extends StatefulWidget {
  final bool isActive;
  final int remainingSeconds;

  const ScanAnimationWidget({
    super.key,
    required this.isActive,
    required this.remainingSeconds,
  });

  @override
  State<ScanAnimationWidget> createState() => _ScanAnimationWidgetState();
}

class _ScanAnimationWidgetState extends State<ScanAnimationWidget>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  static const int _ringCount = 3;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _ringCount,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2000),
      ),
    );
    _animations = _controllers
        .map((c) => Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: c, curve: Curves.easeOut),
            ))
        .toList();

    if (widget.isActive) _startAnimations();
  }

  void _startAnimations() {
    for (var i = 0; i < _ringCount; i++) {
      Future.delayed(Duration(milliseconds: i * 600), () {
        if (mounted) _controllers[i].repeat();
      });
    }
  }

  void _stopAnimations() {
    for (final c in _controllers) {
      c.stop();
      c.reset();
    }
  }

  @override
  void didUpdateWidget(ScanAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startAnimations();
    } else if (!widget.isActive && oldWidget.isActive) {
      _stopAnimations();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < _ringCount; i++)
                AnimatedBuilder(
                  animation: _animations[i],
                  builder: (_, __) {
                    final scale = 0.4 + _animations[i].value * 0.6;
                    final opacity = (1.0 - _animations[i].value).clamp(0.0, 1.0);
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: opacity * 0.5),
                            width: 2.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              Text(
                '${widget.remainingSeconds}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '손가락을 고정해주세요',
          style: TextStyle(
            fontSize: 18,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
