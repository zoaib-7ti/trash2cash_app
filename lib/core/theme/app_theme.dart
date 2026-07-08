import 'package:flutter/material.dart';

import '../../data/models/pickup_request_model.dart';

class AppThemeTokens {
  const AppThemeTokens({
    required this.primaryColor,
    required this.secondaryColor,
    required this.statusBadgeColors,
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
  final Color secondaryColor;
  final Map<PickupStatus, Color> statusBadgeColors;
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
    primaryColor: Color(0xFF6750A4), // TODO: replace with real token from Visily UI-library page.
    secondaryColor: Color(0xFF625B71), // TODO: replace with real token from Visily UI-library page.
    statusBadgeColors: <PickupStatus, Color>{
      PickupStatus.pending: Color(0xFFF59E0B), // TODO: replace with real token from Visily UI-library page.
      PickupStatus.accepted: Color(0xFF3B82F6), // TODO: replace with real token from Visily UI-library page.
      PickupStatus.inProgress: Color(0xFF8B5CF6), // TODO: replace with real token from Visily UI-library page.
      PickupStatus.completed: Color(0xFF16A34A), // TODO: replace with real token from Visily UI-library page.
      PickupStatus.cancelled: Color(0xFFDC2626), // TODO: replace with real token from Visily UI-library page.
    },
    filterChipTheme: ChipThemeData(
      backgroundColor: Color(0xFFF1F5F9), // TODO: replace with real token from Visily UI-library page.
      selectedColor: Color(0xFFDBEAFE), // TODO: replace with real token from Visily UI-library page.
      disabledColor: Color(0xFFE2E8F0), // TODO: replace with real token from Visily UI-library page.
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: TextStyle(
        color: Color(0xFF0F172A), // TODO: replace with real token from Visily UI-library page.
        fontWeight: FontWeight.w600,
      ),
      secondaryLabelStyle: TextStyle(
        color: Color(0xFF1E293B), // TODO: replace with real token from Visily UI-library page.
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: Color(0xFFE2E8F0), // TODO: replace with real token from Visily UI-library page.
      ),
    ),
    skeletonLoaderColor: Color(0xFFE2E8F0), // TODO: replace with real token from Visily UI-library page.
    emptyStateBackgroundColor: Color(0xFFF8FAFC), // TODO: replace with real token from Visily UI-library page.
    emptyStateTitleTextStyle: TextStyle(
      color: Color(0xFF0F172A), // TODO: replace with real token from Visily UI-library page.
      fontSize: 20,
      fontWeight: FontWeight.w700,
    ),
    emptyStateBodyTextStyle: TextStyle(
      color: Color(0xFF475569), // TODO: replace with real token from Visily UI-library page.
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    errorBannerBackgroundColor: Color(0xFFFEE2E2), // TODO: replace with real token from Visily UI-library page.
    errorBannerForegroundColor: Color(0xFFB91C1C), // TODO: replace with real token from Visily UI-library page.
    errorBannerTextStyle: TextStyle(
      color: Color(0xFF7F1D1D), // TODO: replace with real token from Visily UI-library page.
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