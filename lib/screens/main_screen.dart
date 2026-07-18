import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_view_model.dart';
import 'search_screen.dart';
import 'journals_screen.dart';
import 'keywords_screen.dart';
import 'user_management_screen.dart';
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
    const UserManagementScreen(),
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
            key: Key('navHomeTab'),
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            key: Key('navJournalsTab'),
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Journals',
          ),
          const NavigationDestination(
            key: Key('navKeywordsTab'),
            icon: Icon(Icons.label_outlined),
            selectedIcon: Icon(Icons.label),
            label: 'Keywords',
          ),
          const NavigationDestination(
            key: Key('navUsersTab'),
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
          Consumer<AuthViewModel>(
            builder: (context, auth, _) {
              final user = auth.currentUser;
              final hasPhoto = user != null && user.photoURL != null;

              // NOTE: this destination's *icon* swaps from Icons.person_outline
              // to a CircleAvatar once the signed-in user has a photoURL (the
              // Mock/Developer sign-in sets one). It always keeps the same
              // Key('navProfileTab') though, so tests should find it by key,
              // never by icon.
              if (!hasPhoto) {
                return const NavigationDestination(
                  key: Key('navProfileTab'),
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                );
              }

              return NavigationDestination(
                key: const Key('navProfileTab'),
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

