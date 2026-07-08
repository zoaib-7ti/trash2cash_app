import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/models/user_model.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userRoleKey = 'user_role';

  final FlutterSecureStorage _storage;

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }

  Future<void> saveUserRole(UserRole role) {
    return _storage.write(key: _userRoleKey, value: role.apiValue);
  }

  Future<UserRole?> getUserRole() async {
    final storedRole = await _storage.read(key: _userRoleKey);
    if (storedRole == null || storedRole.isEmpty) {
      return null;
    }

    try {
      return UserRoleJson.fromJson(storedRole);
    } on FormatException {
      return null;
    }
  }

  Future<void> clearAll() async {
    await Future.wait([
      clearTokens(),
      _storage.delete(key: _userRoleKey),
    ]);
  }
}