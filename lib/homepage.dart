import 'package:flutter/material.dart';
import 'bottom_nav.dart'; 
import 'profile.dart';

// This file serves as the main structural container for the application after a user successfully logs in.
// It holds the different main screens and manages switching between them using the bottom navigation bar.
class Homepage extends StatefulWidget {
  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  // We use this integer variable to keep track of which tab is currently selected. 
  // It defaults to 1, which corresponds to the "Active" tab in our navigation bar.
  int currentIndex = 1;

  // This is a list of the actual screen widgets that correspond to each tab in the bottom navigation menu.
  // Currently, the Board, Active, and Post screens are just temporary text placeholders.
  // The fourth item is the actual ProfilePage widget that we have fully implemented.
  final List<Widget> pages = [
    Center(child: Text("Board", style: TextStyle(color: Colors.white))),
    Center(child: Text("Active", style: TextStyle(color: Colors.white))),
    Center(child: Text("Post", style: TextStyle(color: Colors.white))),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    // We return a Scaffold which provides the basic visual layout structure for the homepage.
    return Scaffold(
      // We set a very dark blue/black background color to maintain the application's dark theme across all tabs.
      backgroundColor: Color(0xFF020617),

      // The body of the scaffold displays the specific page from our 'pages' list based on the currently selected index.
      // Whenever the currentIndex changes, Flutter automatically rebuilds this body to show the new page.
      body: pages[currentIndex],

      // We attach our custom built BottomNav widget to the bottom of this screen.
      // We pass it the current active index and provide a function that tells the homepage to update its state when a new tab is tapped.
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