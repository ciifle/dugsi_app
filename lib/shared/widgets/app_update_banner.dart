import 'package:flutter/material.dart';

import 'package:kobac/services/app_update/app_update_service.dart';

/// Overlays a "new version available" prompt on top of [child] while
/// [service] reports a newer web deployment. Reload keeps all device data,
/// including unsent offline attendance.
class AppUpdateBanner extends StatelessWidget {
  const AppUpdateBanner({
    super.key,
    required this.service,
    required this.child,
  });

  final AppUpdateService service;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        ListenableBuilder(
          listenable: service,
          builder: (context, _) {
            if (!service.showPrompt) return const SizedBox.shrink();
            return Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Material(
                      key: const ValueKey('app-update-banner'),
                      elevation: 6,
                      color: const Color(0xFF0F2A4A),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.end,
                          spacing: 4,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                'A new version of Dugsi is available. Save any '
                                'open work, then reload. Saved and unsent '
                                'attendance stays on this device.',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            TextButton(
                              key: const ValueKey('app-update-later'),
                              onPressed: service.dismiss,
                              child: const Text(
                                'Later',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                            FilledButton(
                              key: const ValueKey('app-update-reload'),
                              onPressed: service.apply,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF0F2A4A),
                              ),
                              child: const Text('Reload'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
