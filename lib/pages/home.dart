import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/home/home_nav_cubit.dart';
import '../components/bottom_nav.dart';
import '../components/header.dart';
import 'post.dart';
import 'profile.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _EmptyPage(title: 'Board'),
      const _EmptyPage(title: 'Active'),
      const PostPage(),
      const ProfilePage(),
    ];

    return BlocProvider(
      create: (_) => HomeNavCubit(),
      child: BlocBuilder<HomeNavCubit, int>(
        builder: (context, currentIndex) {
          return Scaffold(
            backgroundColor: const Color(0xFF020617),
            body: Column(
              children: [
                if (currentIndex != 3) const HomeHeader(),
                Expanded(child: pages[currentIndex]),
              ],
            ),
            bottomNavigationBar: BottomNav(
              currentIndex: currentIndex,
              onTap: context.read<HomeNavCubit>().selectTab,
            ),
          );
        },
      ),
    );
  }
}

class _EmptyPage extends StatelessWidget {
  final String title;

  const _EmptyPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF020617),
      child: Center(
        child: Text(
          '$title Page',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}
