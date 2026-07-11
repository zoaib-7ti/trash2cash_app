import 'package:flutter/material.dart';

import '../../data/models/pickup_request_model.dart';

class StatusBadgeStyle {
  const StatusBadgeStyle({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

class AppThemeTokens {
  const AppThemeTokens({
    required this.primaryColor,
    required this.lightGreenSurfaceTint,
    required this.secondaryColor,
    required this.statusBadgeStyles,
    required this.filterChipTheme,
    required this.skeletonLoaderColor,
    required this.emptyStateBackgroundColor,
    required this.emptyStateTitleTextStyle,
    required this.emptyStateBodyTextStyle,
    required this.errorBannerBackgroundColor,
    required this.errorBannerForegroundColor,
    required this.errorBannerTextStyle,
  });

  final Color primaryColor;
  final Color lightGreenSurfaceTint;
  final Color secondaryColor;
  final Map<PickupStatus, StatusBadgeStyle> statusBadgeStyles;
  final ChipThemeData filterChipTheme;
  final Color skeletonLoaderColor;
  final Color emptyStateBackgroundColor;
  final TextStyle emptyStateTitleTextStyle;
  final TextStyle emptyStateBodyTextStyle;
  final Color errorBannerBackgroundColor;
  final Color errorBannerForegroundColor;
  final TextStyle errorBannerTextStyle;
}

class AppTheme {
  AppTheme._();

  static const AppThemeTokens lightTokens = AppThemeTokens(
    primaryColor: Color(0xFF1BC956),
    lightGreenSurfaceTint: Color(0xFFEDFDF2),
    secondaryColor: Color(0xFF4B5563),
    statusBadgeStyles: <PickupStatus, StatusBadgeStyle>{
      PickupStatus.pending: StatusBadgeStyle(
        background: Color(0xFFFEF3C5),
        foreground: Color(0xFFB45309),
      ),
      PickupStatus.accepted: StatusBadgeStyle(
        background: Color(0xFFDAEAFF),
        foreground: Color(0xFF1D4ED8),
      ),
      PickupStatus.inProgress: StatusBadgeStyle(
        background: Color(0xFFF5E7FF),
        foreground: Color(0xFF7E22CE),
      ),
      PickupStatus.completed: StatusBadgeStyle(
        background: Color(0xFFD6FCE7),
        foreground: Color(0xFF15803D),
      ),
      PickupStatus.cancelled: StatusBadgeStyle(
        background: Color(0xFFEFF2F7),
        foreground: Color(0xFF475569),
      ),
    },
    filterChipTheme: ChipThemeData(
      backgroundColor: Color(0xFFF1F5F9),
      selectedColor: Color(0xFF1BC956),
      disabledColor: Color(0xFFE2E8F0),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: TextStyle(
        color: Color(0xFF374151),
        fontWeight: FontWeight.w600,
      ),
      secondaryLabelStyle: TextStyle(
        color: Color(0xFFFFFFFF),
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: Color(0xFFE2E8F0)),
    ),
    skeletonLoaderColor: Color(0xFFE2E8F0),
    emptyStateBackgroundColor: Color(0xFFF8FAFC),
    emptyStateTitleTextStyle: TextStyle(
      color: Color(0xFF0F172A),
      fontSize: 20,
      fontWeight: FontWeight.w700,
    ),
    emptyStateBodyTextStyle: TextStyle(
      color: Color(0xFF475569),
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    errorBannerBackgroundColor: Color(0xFFFBEDEC),
    errorBannerForegroundColor: Color(0xFFB91C1C),
    errorBannerTextStyle: TextStyle(
      color: Color(0xFF7F1D1D),
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: lightTokens.primaryColor),
      chipTheme: lightTokens.filterChipTheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
  }
}
