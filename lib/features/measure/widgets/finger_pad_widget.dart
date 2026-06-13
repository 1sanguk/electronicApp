import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class FingerPadWidget extends StatelessWidget {
  final bool isScanning;
  final VoidCallback? onPointerDown;
  final VoidCallback? onPointerUp;
  final void Function(double radiusMajor)? onPointerDownWithRadius;
  final void Function(double radiusMajor)? onPointerMoveWithRadius;
  final String? overlayText;

  const FingerPadWidget({
    super.key,
    required this.isScanning,
    this.onPointerDown,
    this.onPointerUp,
    this.onPointerDownWithRadius,
    this.onPointerMoveWithRadius,
    this.overlayText,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) {
        onPointerDownWithRadius?.call(e.radiusMajor);
        onPointerDown?.call();
      },
      onPointerMove: (e) => onPointerMoveWithRadius?.call(e.radiusMajor),
      onPointerUp: (_) => onPointerUp?.call(),
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isScanning
              ? AppTheme.primary.withValues(alpha: 0.12)
              : AppTheme.primary.withValues(alpha: 0.06),
          border: Border.all(
            color: isScanning ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.4),
            width: isScanning ? 3 : 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fingerprint,
              size: 80,
              color: isScanning
                  ? AppTheme.primary
                  : AppTheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              overlayText ?? (isScanning ? '측정 중...' : '여기에 손가락을\n올려주세요'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: overlayText != null ? 20 : 18,
                fontWeight: overlayText != null ? FontWeight.w700 : FontWeight.w500,
                color: isScanning ? AppTheme.primary : AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
