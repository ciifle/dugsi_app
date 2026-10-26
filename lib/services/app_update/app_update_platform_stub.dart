import 'package:flutter/foundation.dart';

import 'app_update_service.dart';

/// Android/desktop: updates arrive as a new APK/build, never in-app.
AppUpdatePlatform createAppUpdatePlatform() => _NoUpdates();

class _NoUpdates implements AppUpdatePlatform {
  @override
  void start(VoidCallback onUpdateReady) {}

  @override
  Future<void> check() async {}

  @override
  void apply() {}

  @override
  void stop() {}
}
