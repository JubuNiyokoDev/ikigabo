import 'package:flutter/widgets.dart';

import 'inline_banner_ad.dart';
import 'medium_rectangle_ad.dart';
import 'native_ad_list_item.dart';

enum _ListAdFormat { banner, native, mediumRectangle }

class _ListAdSlot {
  const _ListAdSlot({required this.afterItems, required this.format});

  final int afterItems;
  final _ListAdFormat format;
}

class DynamicListAds {
  const DynamicListAds._();

  static List<_ListAdSlot> _slots(int contentCount) {
    return [
      if (contentCount >= 2)
        const _ListAdSlot(afterItems: 2, format: _ListAdFormat.banner),
      if (contentCount >= 8)
        const _ListAdSlot(afterItems: 8, format: _ListAdFormat.native),
      if (contentCount >= 12)
        const _ListAdSlot(
          afterItems: 12,
          format: _ListAdFormat.mediumRectangle,
        ),
    ];
  }

  static int itemCount(int contentCount) {
    return contentCount + _slots(contentCount).length;
  }

  static Widget? adAt({required int listIndex, required int contentCount}) {
    var inserted = 0;
    for (final slot in _slots(contentCount)) {
      final slotIndex = slot.afterItems + inserted;
      if (listIndex == slotIndex) {
        return switch (slot.format) {
          _ListAdFormat.banner => const InlineBannerAd(),
          _ListAdFormat.native => const NativeAdListItem(),
          _ListAdFormat.mediumRectangle => const MediumRectangleAd(),
        };
      }
      inserted++;
    }
    return null;
  }

  static int contentIndex({required int listIndex, required int contentCount}) {
    var adsBefore = 0;
    var inserted = 0;
    for (final slot in _slots(contentCount)) {
      final slotIndex = slot.afterItems + inserted;
      if (listIndex > slotIndex) adsBefore++;
      inserted++;
    }
    return listIndex - adsBefore;
  }
}
