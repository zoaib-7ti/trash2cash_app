import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  static const int backendPort = 5000;
  // Must match the backend's actual running port in .env.
  // 5000 matches the current backend README, but update this if the server runs elsewhere.

  static const String androidEmulatorHost = 'http://10.0.2.2';

  // TODO: set this to your machine's LAN IP before testing on a physical device or iOS simulator.
  static const String lanHost = 'http://YOUR_LAN_IP_HERE';

  // TODO: set false when running on a physical Android device so the app uses the LAN host.
  static const bool preferAndroidEmulatorHost = true;

  static String get host {
    final shouldUseAndroidEmulatorHost =
        defaultTargetPlatform == TargetPlatform.android && preferAndroidEmulatorHost;
    return shouldUseAndroidEmulatorHost ? androidEmulatorHost : lanHost;
  }

  static String get origin => '$host:$backendPort';

  static String get apiBaseUrl => '$origin/api';

  static String get uploadsBaseUrl => origin;

  static const String healthPath = '/health';
  static const String authRegisterPath = '/auth/register';
  static const String authLoginPath = '/auth/login';
  static const String authRefreshPath = '/auth/refresh';
  static const String authLogoutPath = '/auth/logout';
  static const String authMePath = '/auth/me';

  static const String pickupsPath = '/pickups';
  static const String jobsFeedPath = '/jobs/feed';
  static const String jobsMyJobsPath = '/jobs/my-jobs';
}