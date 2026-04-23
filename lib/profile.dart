import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
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
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (doc.exists) {
      setState(() {
        username = doc['username'] ?? "User";
        wallet = (doc['wallet'] ?? 0).toDouble();
      });
    }
  }

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

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> deleteAccount() async {
    try {
      await FirebaseAuth.instance.currentUser!.delete();
      await showMessage("Account deleted");
    } catch (e) {
      await showMessage("Please re-login before delete");
    }
  }

  /// 🔥 卡片按钮（UI优化版）
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
            Text(text,
                style: TextStyle(color: Colors.white, fontSize: 15)),
            Spacer(),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF020617),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [

                /// 🔹 顶部
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
                          icon: Icon(Icons.settings,
                              color: Colors.white),
                          onPressed: () {
                            showMessage("Settings clicked");
                          },
                        ),
                        GestureDetector(
                          onTap: () async {
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
                            child: Icon(Icons.person,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    )
                  ],
                ),

                SizedBox(height: 30),

                /// 🔹 钱包卡片（优化🔥）
                GestureDetector(
                  onTap: () {
                    showMessage("Wallet clicked");
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF2563EB),
                          Color(0xFF60A5FA)
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text("My Wallet",
                            style: TextStyle(
                                color: Colors.white70)),
                        SizedBox(height: 10),
                        Text(
                          "\$${wallet.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 30),

                /// 🔹 功能区
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