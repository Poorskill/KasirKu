import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';

enum DeviceScreenType { mobile, tablet, desktop }

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isMobile => screenWidth < AppDimensions.mobileBreakpoint;
  bool get isTablet =>
      screenWidth >= AppDimensions.mobileBreakpoint &&
      screenWidth <= AppDimensions.tabletBreakpoint;
  bool get isDesktop => screenWidth > AppDimensions.tabletBreakpoint;

  DeviceScreenType get screenType {
    if (isMobile) return DeviceScreenType.mobile;
    if (isTablet) return DeviceScreenType.tablet;
    return DeviceScreenType.desktop;
  }
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > AppDimensions.tabletBreakpoint) {
          return desktop;
        }
        if (constraints.maxWidth >= AppDimensions.mobileBreakpoint) {
          return tablet ?? desktop;
        }
        return mobile;
      },
    );
  }
}
