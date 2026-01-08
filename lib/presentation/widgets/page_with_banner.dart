import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/banner_provider.dart';
import 'banner_ad_widget.dart';

class PageWithBanner extends ConsumerWidget {
  final Widget child;
  final bool showBanner;
  final int? bannerPosition; // Position dans une liste (optionnel)

  const PageWithBanner({
    super.key,
    required this.child,
    this.showBanner = true,
    this.bannerPosition,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Si pas de position spécifiée, retourner l'enfant tel quel
    if (!showBanner || bannerPosition == null) {
      return child;
    }

    return child;
  }
}

// Widget helper pour injecter le banner dans les listes
class BannerInjector {
  static List<Widget> injectBanner(List<Widget> items, WidgetRef ref, {int position = 3}) {
    final bannerState = ref.watch(bannerProvider);
    
    if (!bannerState.isVisible || items.length <= position) {
      return items;
    }

    final result = List<Widget>.from(items);
    result.insert(position, const BannerAdWidget());
    return result;
  }
}