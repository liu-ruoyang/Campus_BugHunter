import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {

  final usernameController = TextEditingController();
  final genderController = TextEditingController();
  final ageController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  /// 🔥 读取用户数据
  Future<void> loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      usernameController.text = data['username'] ?? "";
      genderController.text = data['gender'] ?? "";
      ageController.text = data['age']?.toString() ?? "";
      addressController.text = data['address'] ?? "";
      emailController.text = data['email'] ?? "";
    }
  }

  /// 🔥 保存
  Future<void> saveProfile() async {
    setState(() => isLoading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({
      'username': usernameController.text,
      'gender': genderController.text,
      'age': int.tryParse(ageController.text) ?? 0,
      'address': addressController.text,
      'email': emailController.text,
    });

    setState(() => isLoading = false);

    showMessage("Profile updated");
  }

  Future<void> showMessage(String msg) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Message"),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"))
        ],
      ),
    );
  }

  /// 🔥 输入框UI（统一样式）
  Widget inputField(String label, TextEditingController controller) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF020617),

      appBar: AppBar(
        title: Text("Edit Profile"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [

            /// 🔹 头像（占位）
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[800],
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),

            SizedBox(height: 20),

            /// 🔹 输入区域
            inputField("Username", usernameController),
            inputField("Gender", genderController),
            inputField("Age", ageController),
            inputField("Address", addressController),
            inputField("Email", emailController),

            SizedBox(height: 30),

            /// 🔥 保存按钮（优化）
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  "Save Changes",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}