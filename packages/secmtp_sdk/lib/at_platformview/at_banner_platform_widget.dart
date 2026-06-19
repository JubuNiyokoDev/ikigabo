import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PlatformBannerWidget extends StatefulWidget {
  PlatformBannerWidget(this.placementID, {this.sceneID});

  final String placementID;

  final String? sceneID;

  @override
  _PlatformBannerWidgetState createState() => _PlatformBannerWidgetState();
}

class _PlatformBannerWidgetState extends State<PlatformBannerWidget> {
  // Maintain a fixed key within the State to ensure it does not change during the current Widget's lifecycle.
  late final Key _androidViewKey;

  @override
  void initState() {
    super.initState();
    _androidViewKey = UniqueKey();
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        key: _androidViewKey,
        viewType: 'at_banner_platform_view',
        creationParams: <String, dynamic>{
          "placementID": widget.placementID,
          "sceneID": widget.sceneID,
        },
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        key: UniqueKey(),
        viewType: "at_banner_platform_view",
        creationParams: <String, dynamic>{
          "placementID": widget.placementID,
          "sceneID": widget.sceneID,
        },
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else {
      return Text("Unsupported platform");
    }
  }
}
