import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/api_constants.dart';
import 'core/network/api_client.dart';
import 'core/routing/app_router.dart';
import 'core/routing/route_guard.dart';
import 'core/storage/secure_storage_service.dart';
import 'features/auth/state/auth_state.dart';
import 'features/pickups/state/pickups_state.dart';
import 'features/jobs/state/jobs_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final secureStorageService = SecureStorageService();

  final apiClient = ApiClient(
    secureStorageService: secureStorageService,
    apiBaseUrl: ApiConstants.apiBaseUrl,
  );

  final authState = AuthState(
    apiClient: apiClient,
    secureStorageService: secureStorageService,
  );

  final pickupsState = PickupsState(apiClient: apiClient);
  final jobsState = JobsState(apiClient: apiClient);

  final routeGuard = RouteGuard(
    secureStorageService: secureStorageService,
    apiClient: apiClient,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<SecureStorageService>.value(value: secureStorageService),
        Provider<ApiClient>.value(value: apiClient),
        Provider<RouteGuard>.value(value: routeGuard),
        ChangeNotifierProvider<AuthState>.value(value: authState),
        ChangeNotifierProvider<PickupsState>.value(value: pickupsState),
        ChangeNotifierProvider<JobsState>.value(value: jobsState),
      ],
      child: const Trash2CashApp(),
    ),
  );
}

class Trash2CashApp extends StatelessWidget {
  const Trash2CashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppRouter();
  }
}
