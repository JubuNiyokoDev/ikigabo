import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/preferences_service.dart';

final preferencesServiceProvider = FutureProvider<PreferencesService>((ref) async {
  return await PreferencesService.init();
});