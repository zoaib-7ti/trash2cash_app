import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/screens/profile_screen.dart';
import '../../jobs/screens/job_feed_screen.dart';
import '../../jobs/screens/my_jobs_screen.dart';

class CollectorShellScreen extends StatefulWidget {
  const CollectorShellScreen({super.key});

  @override
  State<CollectorShellScreen> createState() => _CollectorShellScreenState();
}

class _CollectorShellScreenState extends State<CollectorShellScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.lightTokens;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          JobFeedScreen(),
          MyJobsScreen(),
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
              icon: Icon(Icons.list_alt_outlined),
              activeIcon: Icon(Icons.list_alt),
              label: 'Job Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work_outline),
              activeIcon: Icon(Icons.work),
              label: 'My Jobs',
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
