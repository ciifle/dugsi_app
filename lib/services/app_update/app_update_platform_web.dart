import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'app_update_service.dart';

AppUpdatePlatform createAppUpdatePlatform() => _ServiceWorkerUpdates();

/// Detects a new deployment through Flutter's `flutter_service_worker.js`.
///
/// Every `flutter build web` changes the worker's resource hashes, so the
/// browser installs a new worker when it next checks. Flutter's worker calls
/// skipWaiting and replaces changed cached files on activation; the page that
/// is already open keeps running the old code until it reloads. This watches
/// for that hand-over (and polls for it while the app stays open) so the UI
/// can offer a reload.
class _ServiceWorkerUpdates implements AppUpdatePlatform {
  static const _pollEvery = Duration(minutes: 30);

  web.ServiceWorkerRegistration? _registration;
  Timer? _timer;
  VoidCallback? _onReady;
  bool _hadController = false;
  JSFunction? _onVisible;

  @override
  void start(VoidCallback onUpdateReady) {
    _onReady = onUpdateReady;
    unawaited(_attach());
  }

  Future<void> _attach() async {
    try {
      final container = web.window.navigator.serviceWorker;
      // No controller on the very first visit: that is an install, not an
      // update.
      _hadController = container.controller != null;
      container.addEventListener(
        'controllerchange',
        ((web.Event _) {
          if (_hadController) _ready();
          _hadController = true;
        }).toJS,
      );
      final registration = await container.getRegistration().toDart;
      if (registration == null) return;
      _registration = registration;
      if (registration.waiting != null && _hadController) _ready();
      registration.addEventListener(
        'updatefound',
        ((web.Event _) => _watch(registration.installing)).toJS,
      );
      _watch(registration.installing);
      _timer = Timer.periodic(_pollEvery, (_) => unawaited(check()));
      _onVisible = ((web.Event _) {
        if (web.document.visibilityState == 'visible') unawaited(check());
      }).toJS;
      web.document.addEventListener('visibilitychange', _onVisible);
    } catch (e) {
      // Service workers unavailable (http, private mode, some in-app
      // browsers): the next normal load still fetches index.html online-first.
      debugPrint('[AppUpdate] service worker unavailable: $e');
    }
  }

  void _watch(web.ServiceWorker? worker) {
    if (worker == null) return;
    worker.addEventListener(
      'statechange',
      ((web.Event _) {
        final state = worker.state;
        if ((state == 'installed' || state == 'activated') && _hadController) {
          _ready();
        }
      }).toJS,
    );
  }

  void _ready() => _onReady?.call();

  @override
  Future<void> check() async {
    try {
      await _registration?.update().toDart;
    } catch (_) {
      // Offline or server unreachable: try again on the next trigger.
    }
  }

  @override
  void apply() {
    // A waiting worker takes over first (Flutter's worker understands this
    // message). Only the page reloads: localStorage, IndexedDB, caches and
    // registrations are left untouched, so queued attendance survives.
    try {
      _registration?.waiting?.postMessage('skipWaiting'.toJS);
    } catch (_) {}
    web.window.location.reload();
  }

  @override
  void stop() {
    _timer?.cancel();
    if (_onVisible != null) {
      web.document.removeEventListener('visibilitychange', _onVisible);
    }
  }
}
