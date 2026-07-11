import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:trash2cash_app/main.dart';
import 'package:trash2cash_app/core/network/api_client.dart';
import 'package:trash2cash_app/core/routing/route_guard.dart';
import 'package:trash2cash_app/core/storage/secure_storage_service.dart';
import 'package:trash2cash_app/core/constants/api_constants.dart';
import 'package:trash2cash_app/data/models/user_model.dart';
import 'package:trash2cash_app/features/auth/state/auth_state.dart';

class _FakeSecureStorageService extends SecureStorageService {
  String? _accessToken;
  String? _refreshToken;

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
  }

  @override
  Future<void> saveUserRole(UserRole role) async {}

  @override
  Future<UserRole?> getUserRole() async => null;

  @override
  Future<void> clearAll() async {
    await clearTokens();
  }
}

void main() {
  testWidgets('app builds and lands on login route', (
    WidgetTester tester,
  ) async {
    final secureStorageService = _FakeSecureStorageService();
    final apiClient = ApiClient(
      secureStorageService: secureStorageService,
      apiBaseUrl: ApiConstants.apiBaseUrl,
    );
    final routeGuard = RouteGuard(
      secureStorageService: secureStorageService,
      apiClient: apiClient,
    );
    final authState = AuthState(
      apiClient: apiClient,
      secureStorageService: secureStorageService,
    );

    addTearDown(() async {
      await apiClient.dispose();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SecureStorageService>.value(value: secureStorageService),
          Provider<ApiClient>.value(value: apiClient),
          Provider<RouteGuard>.value(value: routeGuard),
          ChangeNotifierProvider<AuthState>.value(value: authState),
        ],
        child: const Trash2CashApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.widgetWithText(FilledButton, 'Sign In'), findsOneWidget);
  });
}
