import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/constants/ad_constants.dart';
import '../../core/theme/app_theme.dart';

/// 화면 상단 배너 광고. 로딩 전/실패 시에는 자리만 차지하는 placeholder를 보여준다.
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  static const double height = 50;

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final bannerAd = BannerAd(
      adUnitId: AdConstants.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _bannerAd = ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannerAd = _bannerAd;
    if (bannerAd != null) {
      return SizedBox(
        width: double.infinity,
        height: AdBannerWidget.height,
        child: Center(
          child: SizedBox(
            width: bannerAd.size.width.toDouble(),
            height: bannerAd.size.height.toDouble(),
            child: AdWidget(ad: bannerAd),
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      height: AdBannerWidget.height,
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
