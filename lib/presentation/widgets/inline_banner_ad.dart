import 'package:flutter/material.dart';

import 'banner_ad_widget.dart';

class InlineBannerAd extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const InlineBannerAd({
    super.key,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(padding: padding, child: const BannerAdWidget());
  }
}
