import 'dart:async';
import 'dart:io';

import 'package:in_app_update/in_app_update.dart';

class InAppUpdateService {
  bool _isChecking = false;
  StreamSubscription<InstallStatus>? _installSub;

  Future<void> checkForUpdate() async {
    if (!Platform.isAndroid || _isChecking) return;

    _isChecking = true;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }

      if (info.immediateUpdateAllowed) {
        final result = await InAppUpdate.performImmediateUpdate();
        print('In-app update immediate result: $result');
        return;
      }

      if (info.flexibleUpdateAllowed) {
        await _installSub?.cancel();
        _installSub = InAppUpdate.installUpdateListener.listen((status) async {
          if (status == InstallStatus.downloaded) {
            await InAppUpdate.completeFlexibleUpdate();
            await _installSub?.cancel();
            _installSub = null;
          }
        });

        final result = await InAppUpdate.startFlexibleUpdate();
        print('In-app update flexible result: $result');
        if (result != AppUpdateResult.success) {
          await _installSub?.cancel();
          _installSub = null;
        }
      }
    } catch (e) {
      print('In-app update check failed: $e');
    } finally {
      _isChecking = false;
    }
  }

  Future<void> dispose() async {
    await _installSub?.cancel();
    _installSub = null;
  }
}
