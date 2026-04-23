import 'package:flutter/material.dart';
import 'bottom_nav.dart';   // 🔥 引入
import 'profile.dart';

class Homepage extends StatefulWidget {
  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int currentIndex = 1;

  final List<Widget> pages = [
    Center(child: Text("Board", style: TextStyle(color: Colors.white))),
    Center(child: Text("Active", style: TextStyle(color: Colors.white))),
    Center(child: Text("Post", style: TextStyle(color: Colors.white))),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF020617),

      body: pages[currentIndex],

      /// 🔥 使用组件
      bottomNavigationBar: BottomNav(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }
}