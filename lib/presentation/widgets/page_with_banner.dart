import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'banner_ad_widget.dart';

class PageWithBanner extends StatelessWidget {
  final Widget child;
  final bool showBanner;
  final EdgeInsetsGeometry bannerPadding;

  const PageWithBanner({
    super.key,
    required this.child,
    this.showBanner = true,
    this.bannerPadding = const EdgeInsets.fromLTRB(12, 8, 12, 8),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: child),
        if (showBanner)
          SafeArea(
            top: false,
            child: Padding(
              padding: bannerPadding,
              child: SizedBox(
                width: double.infinity,
                child: const BannerAdWidget(),
              ),
            ),
          ),
      ],
    );
  }
}
