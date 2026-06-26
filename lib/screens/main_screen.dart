import 'package:flutter/material.dart';
import 'search_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    SearchScreen(),
  ];

  String _getTabLabel(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Journals';
      case 2:
        return 'Keywords';
      case 3:
        return 'Profile';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: 0, // Keep selection locked to SearchScreen (index 0)
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          if (index == 0) {
            setState(() {
              _currentIndex = index;
            });
          } else {
            final tabLabel = _getTabLabel(index);
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$tabLabel section is currently disabled',
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                backgroundColor: theme.colorScheme.errorContainer,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.menu_book_outlined,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            label: 'Journals',
            tooltip: 'Journals (Disabled)',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.tag_outlined,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            label: 'Keywords',
            tooltip: 'Keywords (Disabled)',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            label: 'Profile',
            tooltip: 'Profile (Disabled)',
          ),
        ],
      ),
    );
  }
}
