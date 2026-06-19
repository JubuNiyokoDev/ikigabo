import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
        debugPrint('In-app update immediate result: $result');
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
        debugPrint('In-app update flexible result: $result');
        if (result != AppUpdateResult.success) {
          await _installSub?.cancel();
          _installSub = null;
        }
      }
    } catch (error) {
      if (_isInstalledOutsideGooglePlay(error)) {
        debugPrint(
          'In-app update skipped: this installation does not come from '
          'Google Play.',
        );
        return;
      }
      debugPrint('In-app update check failed: $error');
    } finally {
      _isChecking = false;
    }
  }

  bool _isInstalledOutsideGooglePlay(Object error) {
    if (error is! PlatformException || error.code != 'TASK_FAILURE') {
      return false;
    }

    final message = error.message?.toLowerCase() ?? '';
    return message.contains('install error(-10)') ||
        message.contains('error_app_not_owned') ||
        message.contains('not owned');
  }

  Future<void> dispose() async {
    await _installSub?.cancel();
    _installSub = null;
  }
}
