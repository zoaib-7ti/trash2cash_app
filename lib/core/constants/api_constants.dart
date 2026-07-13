import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  static const int backendPort = 5000;
  // Must match the backend's actual running port in .env.
  // 5000 matches the current backend README, but update this if the server runs elsewhere.

  static const String androidEmulatorHost = 'http://10.0.2.2';

  // TODO: set this to your machine's LAN IP before testing on a physical device or iOS simulator.
  static const String lanHost = 'http://192.168.1.14';

  // Set to true when using an Android emulator (uses 10.0.2.2 to access host localhost)
  // Set to false when using a physical device (uses lanHost)
  static const bool preferAndroidEmulatorHost = false;

  static String get host {
    final shouldUseAndroidEmulatorHost =
        defaultTargetPlatform == TargetPlatform.android &&
        preferAndroidEmulatorHost;
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
  static String pickupByIdPath(String id) => '$pickupsPath/$id';
  static const String jobsFeedPath = '/jobs/feed';
  static const String jobsMyJobsPath = '/jobs/my-jobs';
  static String jobByIdPath(String id) => '/jobs/$id';
  static String jobAcceptPath(String id) => '/jobs/$id/accept';
  static String jobStatusPath(String id) => '/jobs/$id/status';
}
