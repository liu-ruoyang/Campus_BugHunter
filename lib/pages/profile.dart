import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile.dart';
import 'login.dart';
import 'reload.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = "Loading...";
  double wallet = 0;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() {
          username = "Guest";
          wallet = 0;
        });
        return;
      }

      final uid = user.uid;

      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

      final doc = await docRef.get();

      /// if user document doesn't exist, create one with default values
      /// (this can happen if the user just registered and we haven't created a doc for them yet)
      if (!doc.exists) {
        await docRef.set({
          "username": user.email ?? "User",
          "wallet": 0,
          "createdAt": Timestamp.now(),
        });
      }

      /// After ensuring the document exists, we fetch it again to get the latest data
      /// (including any default values we just set).
      final newDoc = await docRef.get();

      setState(() {
        username = newDoc.data()?['username'] ?? user.email ?? "User";
        wallet = (newDoc.data()?['wallet'] ?? 0).toDouble();
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        username = "Error";
        wallet = 0;
      });
    }
  }

  Future<void> showMessage(String msg) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Message"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  /// logout
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => Login()),
      (route) => false,
    );
  }

  Future<void> deleteAccount() async {
    try {
      await FirebaseAuth.instance.currentUser!.delete();
      await showMessage("Account deleted");
    } catch (e) {
      await showMessage("Please re-login before delete");
    }
  }

  ///card
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
    return Container(
      color: const Color(0xFF020617),

      /// prevent overflow when keyboard appears
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ///top
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    /// 左侧：头像 + 用户名
                    Row(
                      children: [

                        /// 🔥 可点击头像（带鼠标手型）
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditProfilePage(),
                                ),
                              );

                              /// 返回后刷新数据
                              loadUserData();
                            },
                            child: const CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.blue,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        /// 用户名
                        Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    /// 右侧：设置按钮
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () {
                        showMessage("Settings clicked");
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                /// wallet card
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
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // The left side of the row shows the wallet title and the actual balance formatted in RM.
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "My Wallet",
                            style: TextStyle(color: Colors.white70),
                          ),
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
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          "Reload",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),

                ///function cards
                buildCard("Request Record", Icons.list, () {
                  showMessage("Request Record");
                }),

                buildCard("Helper Record", Icons.handshake, () {
                  showMessage("Helper Record");
                }),

                buildCard("Logout", Icons.logout, logout),

                buildCard("Delete Account", Icons.delete, () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Confirm Delete"),
                      content: const Text(
                        "Are you sure you want to delete your account?\nThis action cannot be undone.",
                      ),
                      actions: [
                        ///  取消
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),

                        /// confirm delete
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await deleteAccount(); // execute delete
                          },
                          child: const Text(
                            "Delete",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
