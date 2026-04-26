import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final usernameController = TextEditingController();
  final ageController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();

  ///gender segment
  String gender = "prefer_not_to_say";

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  /// load user data
  Future<void> loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;

      usernameController.text = data['username'] ?? "";

      ///prevent storing nonstandard gender
      final g = data['gender'];

      if (g == "male" || g == "Male") {
        gender = "male";
      } else if (g == "female" || g == "Female") {
        gender = "female";
      } else {
        gender = "prefer_not_to_say";
      }

      ageController.text = data['age']?.toString() ?? "";
      addressController.text = data['address'] ?? "";
      emailController.text = data['email'] ?? "";
      setState(() {});
    }
  }

  /// save
  Future<void> saveProfile() async {
    setState(() => isLoading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'username': usernameController.text,
      'gender': gender,
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
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget inputField(
    String label,
    TextEditingController controller, {
    TextInputType? type,
    bool enabled = true,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: type,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
        ),
      ),
    );
  }

  ///Dropdown
  Widget genderDropdown() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButton<String>(
        value: gender,
        dropdownColor: Color(0xFF111827),
        isExpanded: true,
        underline: SizedBox(),
        style: TextStyle(color: Colors.white),
        items: const [
          DropdownMenuItem(value: "male", child: Text("Male")),
          DropdownMenuItem(value: "female", child: Text("Female")),
          DropdownMenuItem(
            value: "prefer_not_to_say",
            child: Text("Prefer not to say"),
          ),
        ],
        onChanged: (value) {
          setState(() {
            gender = value!;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF020617),

      appBar: AppBar(
        backgroundColor: Color(0xFF0F172A),
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("Edit Profile", style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[800],
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),

            SizedBox(height: 20),

            inputField("Username", usernameController),

            /// Gender dropdown
            genderDropdown(),

            inputField("Age", ageController, type: TextInputType.number),

            inputField("Address", addressController),

            inputField("Email", emailController, enabled: false),

            SizedBox(height: 30),

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
                    : Text("Save Changes", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
