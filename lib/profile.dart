import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile.dart';
import 'reload_page.dart'; // We import the new reload page here so we can navigate to it.

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // We initialize the username with a loading placeholder and the wallet with zero.
  // These will be updated as soon as we retrieve the actual data from the database.
  String username = "Loading...";
  double wallet = 0;

  @override
  void initState() {
    super.initState();
    // As soon as this profile page is created and loaded onto the screen, we trigger the function to fetch user data.
    loadUserData();
  }

  // This asynchronous function fetches the current user's profile information from the Firestore database.
  // It gets the unique ID of the currently logged in user, searches for their document in the 'users' collection,
  // and if it finds the document, it safely updates our local username and wallet variables with the retrieved data.
  Future<void> loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (doc.exists) {
      setState(() {
        username = doc['username'] ?? "User";
        // We ensure the wallet value is treated as a decimal number (double) even if it was saved as an integer.
        wallet = (doc['wallet'] ?? 0).toDouble();
      });
    }
  }

  // This is a reusable helper function that pops up a dialog box to show simple text messages to the user.
  Future<void> showMessage(String msg) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Message"),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text("OK"))
        ],
      ),
    );
  }

  // This function securely signs the current user out of the application using Firebase Authentication.
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  // This function permanently deletes the user's account from Firebase. 
  // It catches potential security errors, like when a user has been logged in for too long and needs to re-authenticate before performing sensitive actions.
  Future<void> deleteAccount() async {
    try {
      await FirebaseAuth.instance.currentUser!.delete();
      await showMessage("Account deleted");
    } catch (e) {
      await showMessage("Please re-login before delete");
    }
  }

  // This widget builder helps us create consistent looking menu buttons (like Logout or Request Record) without duplicating code.
  // It takes the text to display, the icon to show, and the function to run when the user taps it.
  Widget buildCard(String text, IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 12),
            Text(text, style: TextStyle(color: Colors.white, fontSize: 15)),
            Spacer(),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The Scaffold provides the visual background for our profile page, keeping it consistent with a dark theme.
    return Scaffold(
      backgroundColor: Color(0xFF020617),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [

                // This top section is a horizontal row that holds the user's name on the left, and the settings/profile icons on the right.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield, color: Colors.blueAccent),
                        SizedBox(width: 10),
                        Text(
                          username,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.settings, color: Colors.white),
                          onPressed: () {
                            showMessage("Settings clicked");
                          },
                        ),
                        GestureDetector(
                          onTap: () async {
                            // When tapping the avatar, we navigate to the Edit Profile page. 
                            // Once the user comes back, we reload the data to show any potential updates.
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => EditProfilePage()),
                            );
                            loadUserData();
                          },
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey[800],
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                        ),
                      ],
                    )
                  ],
                ),

                SizedBox(height: 30),

                // This section builds the visually distinct Wallet card. It uses a blue gradient to stand out.
                // It now displays the current balance in RM and includes a convenient Reload button directly on the right side.
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // The left side of the row shows the wallet title and the actual balance formatted in RM.
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("My Wallet",
                              style: TextStyle(color: Colors.white70)),
                          SizedBox(height: 10),
                          Text(
                            "RM ${wallet.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // The right side contains the Reload button.
                      ElevatedButton(
                        onPressed: () async {
                          // When tapped, we open the newly created ReloadPage. 
                          // The 'await' ensures that when the user finishes reloading and returns, we instantly refresh the wallet balance.
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ReloadPage()),
                          );
                          loadUserData();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.25),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: Text(
                          "Reload",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30),

                // These are the interactive menu options located below the wallet card.
                buildCard("Request Record", Icons.list, () {
                  showMessage("Request Record");
                }),

                buildCard("Helper Record", Icons.handshake, () {
                  showMessage("Helper Record");
                }),

                buildCard("Logout", Icons.logout, () async {
                  await logout();
                }),

                buildCard("Delete Account", Icons.delete, () async {
                  await deleteAccount();
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}