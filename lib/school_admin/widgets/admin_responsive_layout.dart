import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const double kDesktopWebAdminBreakpoint = 1024;

bool isDesktopWebAdminLayout(BuildContext context) {
  return kIsWeb && MediaQuery.sizeOf(context).width >= kDesktopWebAdminBreakpoint;
}

bool isEmbeddedDesktopAdminBody(BuildContext context, bool embedBodyOnly) {
  return embedBodyOnly && isDesktopWebAdminLayout(context);
}

bool isDesktopLayout(BuildContext context) => isDesktopWebAdminLayout(context);

bool isTabletLayout(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (kIsWeb) {
    return width >= 600 && width < kDesktopWebAdminBreakpoint;
  }
  return width >= 800 && width < 1200;
}

bool isMobileLayout(BuildContext context) {
  if (kIsWeb) {
    return !isDesktopWebAdminLayout(context);
  }
  return MediaQuery.sizeOf(context).width < 800;
}
