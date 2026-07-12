import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/profile_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/state/auth_state.dart';
import '../../features/pickups/screens/create_pickup_screen.dart';
import '../../features/pickups/screens/edit_pickup_screen.dart';
import '../../features/pickups/screens/pickup_detail_screen.dart';
import '../../features/pickups/screens/pickup_list_screen.dart';
import '../theme/app_theme.dart';
import 'route_guard.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<void>? _sessionExpiredSubscription;

  late final RouteGuard _routeGuard;
  late final AuthState _authState;

  @override
  void initState() {
    super.initState();
    _routeGuard = context.read<RouteGuard>();
    _authState = context.read<AuthState>();
    _sessionExpiredSubscription = _routeGuard.sessionExpiredStream.listen((
      _,
    ) async {
      await _authState.handleSessionExpired();
      _navigateTo(AppDestination.login.routeName);
    });
  }

  @override
  void dispose() {
    _sessionExpiredSubscription?.cancel();
    super.dispose();
  }

  void _navigateTo(String routeName, {Object? arguments}) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    navigator.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      navigatorKey: _navigatorKey,
      home: _StartupGate(routeGuard: _routeGuard, onResolved: _navigateTo),
      routes: <String, WidgetBuilder>{
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/pickups': (_) => const PickupListScreen(),
        '/pickups/create': (_) => const CreatePickupScreen(),
        '/pickups/detail': (_) => const PickupDetailScreen(),
        '/pickups/edit': (_) => const EditPickupScreen(),
        '/collector-home': (_) => const _HomePlaceholderPage(
          title: 'Collector Home',
          subtitle: 'Collector dashboard placeholder.',
        ),
      },
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate({required this.routeGuard, required this.onResolved});

  final RouteGuard routeGuard;
  final ValueChanged<String> onResolved;

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final destination = await widget.routeGuard.resolveStartupDestination();
      if (!mounted) {
        return;
      }
      widget.onResolved(destination.routeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.lightTokens;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tokens.lightGreenSurfaceTint.withValues(alpha: 0.45),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tokens.primaryColor.withValues(alpha: 0.05),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: tokens.primaryColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: tokens.primaryColor.withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bolt,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Coordination & Cash\nfor Your Clean Planet',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF374151),
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: tokens.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Loading...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF4B5563),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomePlaceholderPage extends StatelessWidget {
  const _HomePlaceholderPage({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/profile');
                },
                icon: const Icon(Icons.person),
                label: const Text('Open Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
