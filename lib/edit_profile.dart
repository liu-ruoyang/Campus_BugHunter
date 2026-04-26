import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {

  // These text editing controllers are used to manage and read the values from each profile field.
  // We keep the genderController because it helps us hold the string value selected from the dropdown menu.
  final usernameController = TextEditingController();
  final genderController = TextEditingController();
  final ageController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();

  // This list defines the fixed set of options for the gender selection.
  // It allows users to choose between not revealing their gender, or selecting male or female.
  final List<String> genderOptions = ["Prefer not to say", "Male", "Female"];

  // This variable is a flag used to display a loading spinner whenever we are waiting for a database operation to complete.
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // We automatically call this function as soon as the page is initialized to fetch the user's current data from the cloud.
    loadUserData();
  }

  // This asynchronous function retrieves the latest user profile information from the Firestore database.
  // It uses the current user's unique ID to find their specific document in the 'users' collection.
  // Once the data is retrieved, it populates all the controllers on the screen so the user can see their current info.
  Future<void> loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        usernameController.text = data['username'] ?? "";
        
        // We read the gender from the database. If it is empty or not in our list, we default it to the first option.
        String savedGender = data['gender'] ?? "Prefer not to say";
        genderController.text = genderOptions.contains(savedGender) ? savedGender : genderOptions[0];
        
        ageController.text = data['age']?.toString() ?? "";
        addressController.text = data['address'] ?? "";
        emailController.text = data['email'] ?? "";
      });
    }
  }

  // This function takes all the current values from the form and updates the user's profile document in Firestore.
  // It ensures that data remains consistent and provides a feedback message to the user after the save is finished.
  Future<void> saveProfile() async {
    // We set the loading state to true here to disable the button and show a progress indicator while saving.
    setState(() => isLoading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;

    // We send an update command to Firestore using the text captured from our controllers.
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

    // We set the loading state back to false after the operation is complete.
    setState(() => isLoading = false);

    // This shows a simple confirmation pop-up letting the user know their changes were saved successfully.
    showMessage("Profile updated");
  }

  // This is a standard helper function used across the app to display alert dialogs with a single OK button.
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

  // This helper function creates a styled text input field with a dark background and rounded corners.
  // It ensures that all input fields on this page share a uniform professional look.
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

  // This function builds the specialized dropdown selection field for gender.
  // It replaces the previous text input to ensure users can only select from the predefined options.
  // It is styled to match the regular input fields to maintain visual consistency.
  Widget genderDropdown() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonFormField<String>(
        // We set the current value of the dropdown based on what is stored in the gender controller.
        value: genderOptions.contains(genderController.text) ? genderController.text : genderOptions[0],
        dropdownColor: Color(0xFF111827),
        icon: Icon(Icons.arrow_drop_down, color: Colors.grey),
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: "Gender",
          labelStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
        ),
        // When the user selects a new gender option, we update the controller text immediately.
        onChanged: (String? newValue) {
          setState(() {
            genderController.text = newValue!;
          });
        },
        // We map our list of string options into the menu items that the user can click.
        items: genderOptions.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The Scaffold defines the basic visual structure of our edit screen.
    return Scaffold(
      backgroundColor: Color(0xFF020617),

      // The AppBar at the top contains the page title and the back navigation button.
      appBar: AppBar(
        title: Text("Edit Profile"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // We explicitly set the foreground color to white here. 
        // This is crucial because it makes both the back arrow icon and the "Edit Profile" text bright and easy to see.
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [

            // This is a visual placeholder for the user's profile image located at the center top.
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[800],
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),

            SizedBox(height: 20),

            // We present the editable fields in a vertical column.
            inputField("Username", usernameController),
            
            // Instead of a plain text field, we use our new dropdown widget for the gender field.
            genderDropdown(),
            
            inputField("Age", ageController),
            inputField("Address", addressController),
            inputField("Email", emailController),

            SizedBox(height: 30),

            // This is the main button to submit changes. It fills the width of the page.
            // While saving, it disables itself and shows a circular loading bar.
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