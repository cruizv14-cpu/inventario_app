import 'package:flutter/material.dart';

// Breakpoints
const double kMobileBreakpoint = 600;
const double kTabletBreakpoint = 1024;

bool isMobile(BuildContext context) =>
    MediaQuery.of(context).size.width < kMobileBreakpoint;

bool isTablet(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  return w >= kMobileBreakpoint && w < kTabletBreakpoint;
}

bool isDesktop(BuildContext context) =>
    MediaQuery.of(context).size.width >= kTabletBreakpoint;

/// Devuelve un valor distinto según el tamaño de pantalla actual
T responsiveValue<T>(BuildContext context,
    {required T mobile, T? tablet, required T desktop}) {
  if (isDesktop(context)) return desktop;
  if (isTablet(context)) return tablet ?? desktop;
  return mobile;
}
