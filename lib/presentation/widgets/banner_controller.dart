import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/banner_provider.dart';
import '../../core/constants/app_icons.dart';

class BannerController extends ConsumerWidget {
  const BannerController({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannerState = ref.watch(bannerProvider);
    final bannerNotifier = ref.read(bannerProvider.notifier);

    return FloatingActionButton.small(
      onPressed: () {
        if (bannerState.isVisible) {
          bannerNotifier.hide();
        } else {
          bannerNotifier.show();
        }
      },
      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
      child: Icon(
        bannerState.isVisible ? AppIcons.visibility : AppIcons.visibilityOff,
        color: Colors.white,
        size: 18.sp,
      ),
    );
  }
}