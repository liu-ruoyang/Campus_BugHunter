// This page file defines the authenticated homepage shell.
// It combines role loading, tab selection, the shared header, and the bottom navigation for requester and hunter modes.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/home/home_nav_cubit.dart';
import '../bloc/home/role_cubit.dart';
import '../components/bottom_nav.dart';
import '../components/header.dart';
import '../theme/app_theme.dart';
import 'active.dart';
import 'board.dart';
import 'post.dart';
import 'profile.dart';

// Homepage hosts the main app tabs and swaps tab sets according to the current user role.
class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  // The build method provides HomeNavCubit and RoleCubit, then renders the selected tab and bottom navigation.
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => HomeNavCubit()),
        BlocProvider(create: (_) => RoleCubit()..loadRole()),
      ],
      child: BlocBuilder<RoleCubit, UserRole>(
        builder: (context, role) {
          final tabs = _tabsForRole(role);

          return BlocBuilder<HomeNavCubit, int>(
            builder: (context, currentIndex) {
              final selectedIndex = currentIndex.clamp(0, tabs.length - 1);
              final selectedLabel = tabs[selectedIndex].label.toUpperCase();
              final showHomeHeader =
                  selectedLabel != 'PROFILE' && selectedLabel != 'ACTIVE';

              return Scaffold(
                backgroundColor: AppColors.of(context).background,
                body: Column(
                  children: [
                    if (showHomeHeader) const HomeHeader(),
                    Expanded(child: tabs[selectedIndex].page),
                  ],
                ),
                bottomNavigationBar: BottomNav(
                  currentIndex: selectedIndex,
                  items: [
                    for (final tab in tabs)
                      BottomNavItem(
                        icon: tab.icon,
                        label: tab.label.toUpperCase(),
                      ),
                  ],
                  onTap: context.read<HomeNavCubit>().selectTab,
                ),
              );
            },
          );
        },
      ),
    );
  }

  // This helper returns the correct tab list for requester or hunter role.
  List<_HomeTab> _tabsForRole(UserRole role) {
    switch (role) {
      case UserRole.requester:
        return const [
          _HomeTab(
            icon: Icons.add_circle_outline,
            label: 'Post',
            page: PostPage(),
          ),
          _HomeTab(
            icon: Icons.check_circle_outline,
            label: 'Active',
            page: ActivePage(),
          ),
          _HomeTab(
            icon: Icons.person_outline,
            label: 'Profile',
            page: ProfilePage(),
          ),
        ];
      case UserRole.hunter:
        return const [
          _HomeTab(
            icon: Icons.dashboard_outlined,
            label: 'Board',
            page: BoardPage(),
          ),
          _HomeTab(
            icon: Icons.check_circle_outline,
            label: 'Active',
            page: ActivePage(),
          ),
          _HomeTab(
            icon: Icons.person_outline,
            label: 'Profile',
            page: ProfilePage(),
          ),
        ];
    }
  }
}

// _HomeTab stores the icon, label, and page widget used by one bottom navigation item.
class _HomeTab {
  final IconData icon;
  final String label;
  final Widget page;

  const _HomeTab({required this.icon, required this.label, required this.page});
}
