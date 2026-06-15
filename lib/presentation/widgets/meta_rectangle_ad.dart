import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/meta_ads_service.dart';

class MetaRectangleAd extends StatefulWidget {
  const MetaRectangleAd({super.key});

  @override
  State<MetaRectangleAd> createState() => _MetaRectangleAdState();
}

class _MetaRectangleAdState extends State<MetaRectangleAd> {
  static const double _height = 250;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    MetaAdsService.onRectangleResult = _onResult;
    MetaAdsService.loadRectangle();
  }

  void _onResult(bool loaded) {
    if (!mounted) return;
    setState(() => _loaded = loaded);
  }

  @override
  void dispose() {
    MetaAdsService.onRectangleResult = null;
    MetaAdsService.destroyRectangle();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    return SizedBox(
      height: _height,
      child: const AndroidView(
        viewType: 'meta_rectangle_view',
        layoutDirection: TextDirection.ltr,
        creationParamsCodec: StandardMessageCodec(),
      ),
    );
  }
}
