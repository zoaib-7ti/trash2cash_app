import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/screens/profile_screen.dart';
import '../../pickups/screens/pickup_list_screen.dart';

class HouseholdShellScreen extends StatefulWidget {
  const HouseholdShellScreen({super.key});

  @override
  State<HouseholdShellScreen> createState() => _HouseholdShellScreenState();
}

class _HouseholdShellScreenState extends State<HouseholdShellScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.lightTokens;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          PickupListScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: tokens.primaryColor,
          unselectedItemColor: const Color(0xFF6B7280),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
