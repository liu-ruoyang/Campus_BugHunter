import 'package:flutter/material.dart';

// This is a custom built bottom navigation bar widget. 
// We made it a separate reusable component so the main homepage code remains clean and easy to read.
class BottomNav extends StatelessWidget {
  // It requires two pieces of information from the parent widget to function properly.
  // The current index tells it which navigation tab is currently active.
  final int currentIndex;
  // The onTap function is a callback that tells the parent widget when the user taps a different navigation tab.
  final Function(int) onTap;

  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // We enclose the entire navigation bar inside a container with some margin at the bottom and rounded corners.
    // This gives it a floating pill like appearance instead of attaching directly to the absolute bottom of the screen.
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
      ),
      // We use a Row to align our four navigation items horizontally across the bottom space with equal spacing between them.
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          buildItem(Icons.dashboard_outlined, "BOARD", 0),
          buildItem(Icons.check_circle_outline, "ACTIVE", 1),
          buildItem(Icons.add_circle_outline, "POST", 2),
          buildItem(Icons.person_outline, "PROFILE", 3),
        ],
      ),
    );
  }

  // This helper function creates the individual buttons for the navigation bar.
  // It takes the specific icon, the text label, and the position index for each button.
  Widget buildItem(IconData icon, String label, int index) {
    // We check if the index of this specific button matches the currently active index passed down from the parent.
    // If they match, it means this tab is currently selected.
    bool isSelected = currentIndex == index;

    // We wrap the button in a GestureDetector so it can register when the user taps on it.
    // When tapped, it triggers the onTap callback function and sends its index back up to the parent to change the page.
    return GestureDetector(
      onTap: () => onTap(index),
      // We use an AnimatedContainer here. This is a very neat widget that automatically creates a smooth visual transition.
      // For example, when the user selects this tab, its background color will smoothly change to blue over 200 milliseconds.
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          // If the tab is selected, it gets a bright blue background. If not, the background remains completely transparent.
          color: isSelected ? Color(0xFF3B82F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        // Inside the animated container, we stack the icon and the text label vertically using a Column.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The icon color also changes based on the selection state. It turns bright white if selected, or fades to grey if unselected.
            Icon(icon, color: isSelected ? Colors.white : Colors.grey),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}