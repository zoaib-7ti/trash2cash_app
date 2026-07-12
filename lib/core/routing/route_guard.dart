import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import '../../data/models/user_model.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../storage/secure_storage_service.dart';

enum AppDestination { login, citizenHome, collectorHome }

extension AppDestinationRouteName on AppDestination {
  String get routeName {
    switch (this) {
      case AppDestination.login:
        return '/login';
      case AppDestination.citizenHome:
        return '/pickups';
      case AppDestination.collectorHome:
        return '/collector-home';
    }
  }
}

class RouteGuard {
  RouteGuard({
    required SecureStorageService secureStorageService,
    required ApiClient apiClient,
  }) : _secureStorageService = secureStorageService,
       _apiClient = apiClient;

  final SecureStorageService _secureStorageService;
  final ApiClient _apiClient;

  ApiClient get apiClient => _apiClient;

  Stream<void> get sessionExpiredStream => _apiClient.sessionExpiredStream;

  Future<AppDestination> resolveStartupDestination() async {
    final accessToken = await _secureStorageService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return AppDestination.login;
    }

    final claims = _decodeAccessToken(accessToken);
    if (claims == null) {
      await _secureStorageService.clearAll();
      return AppDestination.login;
    }

    if (claims.expiresAt.isBefore(DateTime.now().toUtc())) {
      await _secureStorageService.clearAll();
      return AppDestination.login;
    }

    final storedRole = await _secureStorageService.getUserRole();
    if (storedRole != null && storedRole != claims.role) {
      developer.log(
        'Stored user role $storedRole does not match JWT role ${claims.role}. Trusting JWT role.',
        name: 'RouteGuard',
        level: 900,
      );
    }

    await _secureStorageService.saveUserRole(claims.role);
    unawaited(_validateSessionInBackground());

    return switch (claims.role) {
      UserRole.citizen => AppDestination.citizenHome,
      UserRole.collector => AppDestination.collectorHome,
      UserRole.admin || UserRole.vendor => AppDestination.login,
    };
  }

  // Keep this as a straight role match unless an admin module adds a real bypass path.
  bool canAccessRole(UserRole currentRole, UserRole requiredRole) {
    return currentRole == requiredRole;
  }

  Future<void> _validateSessionInBackground() async {
    try {
      final user = await _apiClient.fetchCurrentUserProfile();
      final storedRole = await _secureStorageService.getUserRole();
      if (storedRole != null && storedRole != user.role) {
        developer.log(
          'Background profile returned role ${user.role} and storage had $storedRole. Trusting server profile.',
          name: 'RouteGuard',
          level: 900,
        );
      }

      await _secureStorageService.saveUserRole(user.role);
    } on SessionExpiredException {
      // ApiClient already emitted the logout signal.
    } on ApiException catch (error) {
      developer.log(
        'Background session validation failed: ${error.message}',
        name: 'RouteGuard',
        level: 900,
      );
    } catch (error) {
      developer.log(
        'Unexpected background validation error: $error',
        name: 'RouteGuard',
        level: 900,
      );
    }
  }

  _DecodedAccessToken? _decodeAccessToken(String token) {
    final segments = token.split('.');
    if (segments.length < 2) {
      return null;
    }

    try {
      final payload = _decodeBase64UrlJson(segments[1]);
      final roleValue = payload['role']?.toString();
      final expValue = payload['exp'];

      if (roleValue == null || expValue == null) {
        return null;
      }

      return _DecodedAccessToken(
        role: UserRoleJson.fromJson(roleValue),
        expiresAt: DateTime.fromMillisecondsSinceEpoch(
          _toInt(expValue) * 1000,
          isUtc: true,
        ),
      );
    } on FormatException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _decodeBase64UrlJson(String value) {
    final normalizedValue = _normalizeBase64Url(value);
    final decodedBytes = base64Url.decode(normalizedValue);
    final decodedString = utf8.decode(decodedBytes);
    final decodedJson = jsonDecode(decodedString);

    if (decodedJson is Map<String, dynamic>) {
      return decodedJson;
    }

    if (decodedJson is Map) {
      return decodedJson.map((key, value) => MapEntry(key.toString(), value));
    }

    throw const FormatException('JWT payload was not a JSON object');
  }

  String _normalizeBase64Url(String value) {
    final remainder = value.length % 4;
    if (remainder == 0) {
      return value;
    }

    return value.padRight(value.length + (4 - remainder), '=');
  }

  int _toInt(Object value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.parse(value.toString());
  }
}

class _DecodedAccessToken {
  const _DecodedAccessToken({required this.role, required this.expiresAt});

  final UserRole role;
  final DateTime expiresAt;
}
