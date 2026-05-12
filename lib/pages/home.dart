import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/home/home_nav_cubit.dart';
import '../bloc/home/role_cubit.dart';
import '../components/bottom_nav.dart';
import '../components/header.dart';
import 'active.dart';
import 'board.dart';
import 'post.dart';
import 'profile.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
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
                backgroundColor: const Color(0xFF020617),
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

class _HomeTab {
  final IconData icon;
  final String label;
  final Widget page;

  const _HomeTab({required this.icon, required this.label, required this.page});
}
