import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_view_model.dart';
import 'search_screen.dart';
import 'journals_screen.dart';
import 'keywords_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const SearchScreen(),
    const JournalsScreen(),
    const KeywordsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Journals',
          ),
          const NavigationDestination(
            icon: Icon(Icons.label_outlined),
            selectedIcon: Icon(Icons.label),
            label: 'Keywords',
          ),
          Consumer<AuthViewModel>(
            builder: (context, auth, _) {
              final user = auth.currentUser;
              final hasPhoto = user != null && user.photoURL != null;
              
              if (!hasPhoto) {
                return const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                );
              }

              return NavigationDestination(
                icon: CircleAvatar(
                  backgroundImage: NetworkImage(user.photoURL!),
                  radius: 12,
                ),
                selectedIcon: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(user.photoURL!),
                    radius: 12,
                  ),
                ),
                label: 'Profile',
              );
            },
          ),
        ],
      ),
    );
  }
}

