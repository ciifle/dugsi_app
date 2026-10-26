import 'package:flutter/foundation.dart';

import 'app_update_platform_stub.dart'
    if (dart.library.js_interop) 'app_update_platform_web.dart';

/// Low-level hooks for detecting and applying a newer deployed app version.
/// Web uses the Flutter service worker; other platforms update through the
/// store/APK and never report an update here.
abstract class AppUpdatePlatform {
  /// Starts watching; calls [onUpdateReady] once a newer version is ready.
  void start(VoidCallback onUpdateReady);

  /// Asks the server for a newer version now (e.g. on resume).
  Future<void> check();

  /// Loads the newer version. Must only reload the page: never clear
  /// storage, caches or service worker registrations, so the offline
  /// attendance queue (localStorage) survives.
  void apply();

  void stop();
}

/// Tells the UI when a newer web deployment is ready, so an open tab or
/// installed PWA never keeps showing an outdated interface indefinitely.
class AppUpdateService extends ChangeNotifier {
  AppUpdateService({AppUpdatePlatform? platform})
    : _platform = platform ?? createAppUpdatePlatform();

  final AppUpdatePlatform _platform;
  bool _started = false;
  bool updateReady = false;

  /// Hidden for this page load after "Later"; it reappears on the next load
  /// if the update is still waiting.
  bool dismissed = false;

  bool get showPrompt => updateReady && !dismissed;

  void start() {
    if (_started) return;
    _started = true;
    _platform.start(() {
      if (updateReady) return;
      updateReady = true;
      notifyListeners();
    });
  }

  Future<void> check() => _platform.check();

  void dismiss() {
    dismissed = true;
    notifyListeners();
  }

  void apply() => _platform.apply();

  @override
  void dispose() {
    _platform.stop();
    super.dispose();
  }
}
