import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';

class ShimmerWidget extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceDark
          : Colors.grey[300]!,
      highlightColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.cardBackgroundDark
          : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class ShimmerCard extends StatelessWidget {
  final double? height;
  final EdgeInsets? margin;

  const ShimmerCard({
    super.key,
    this.height,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 80,
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const ShimmerWidget(width: 48, height: 48, borderRadius: BorderRadius.all(Radius.circular(12))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShimmerWidget(
                  width: double.infinity,
                  height: 16,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 8),
                ShimmerWidget(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ShimmerWidget(
            width: 80,
            height: 16,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double? itemHeight;

  const ShimmerList({
    super.key,
    this.itemCount = 5,
    this.itemHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => ShimmerCard(height: itemHeight),
      ),
    );
  }
}