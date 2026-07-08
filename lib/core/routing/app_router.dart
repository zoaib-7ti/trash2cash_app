import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import 'route_guard.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  late final RouteGuard _routeGuard;
  late final Stream<void> _sessionExpiredStream;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<void>? _sessionExpiredSubscription;

  @override
  void initState() {
    super.initState();
    _routeGuard = context.read<RouteGuard>();
    _sessionExpiredStream = _routeGuard.sessionExpiredStream;
    _sessionExpiredSubscription = _sessionExpiredStream.listen((_) {
      _navigateTo(AppDestination.login.routeName);
    });
  }

  @override
  void dispose() {
    _sessionExpiredSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      navigatorKey: _navigatorKey,
      routes: <String, WidgetBuilder>{
        AppDestination.login.routeName: (_) => const _PlaceholderPage(
              title: 'Login placeholder',
              subtitle: 'Auth UI will be added in a later phase.',
            ),
        AppDestination.citizenHome.routeName: (_) => const _PlaceholderPage(
              title: 'Household home placeholder',
              subtitle: 'Citizen screens will be added in a later phase.',
            ),
        AppDestination.collectorHome.routeName: (_) => const _PlaceholderPage(
              title: 'Collector home placeholder',
              subtitle: 'Collector screens will be added in a later phase.',
            ),
      },
      home: _StartupGate(
        routeGuard: _routeGuard,
        onResolved: _navigateTo,
      ),
    );
  }

  void _navigateTo(String routeName) {
    _navigatorKey.currentState?.pushNamedAndRemoveUntil(routeName, (route) => false);
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate({required this.routeGuard, required this.onResolved});

  final RouteGuard routeGuard;
  final void Function(String routeName) onResolved;

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
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title, required this.subtitle});

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
            ],
          ),
        ),
      ),
    );
  }
}