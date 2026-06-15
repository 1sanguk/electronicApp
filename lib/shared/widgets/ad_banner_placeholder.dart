import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 화면 상단 광고 영역 자리. 추후 실제 광고 배너로 교체될 placeholder.
class AdBannerPlaceholder extends StatelessWidget {
  const AdBannerPlaceholder({super.key});

  static const double height = 48;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(color: AppTheme.textSecondary.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 18,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 6),
          Text(
            '광고 영역',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
