import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // We create text editing controllers here so we can read the text that the user types into the email and password fields.
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // This boolean variable keeps track of whether the password should be hidden or visible. By default, we hide the password.
  bool obscurePassword = true;
  // This boolean variable helps us show a loading indicator while the app is communicating with Firebase to log the user in.
  bool isLoading = false;

  // This asynchronous function handles the login process when the user taps the login button.
  // First it checks if the user actually typed something in both the email and password fields.
  // If either is empty, it stops and shows an error message.
  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      await showMessage("Please fill all fields");
      return;
    }

    // We set the loading state to true here so the button can show a spinning circle instead of text while we wait.
    setState(() => isLoading = true);

    try {
      // Here we ask Firebase Auth to sign in the user using the email and password they provided.
      // The trim function is used to remove any accidental blank spaces at the beginning or end of the text.
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // If the code reaches here without throwing an error, it means the login was successful.
      await showMessage("Login Success");

    } on FirebaseAuthException catch (e) {
      // If Firebase encounters an error, it throws a FirebaseAuthException. 
      // We catch it here and look at the error code to give the user a helpful, human readable error message instead of technical jargon.
      String errorMessage;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = "User not found";
          break;
        case 'wrong-password':
          errorMessage = "Wrong password";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email";
          break;
        case 'invalid-credential':
          errorMessage = "Email or password incorrect";
          break;
        default:
          errorMessage = e.message ?? "Login Failed";
      }

      await showMessage(errorMessage);

    } catch (e) {
      // This is a fallback catch block just in case something completely unexpected goes wrong outside of Firebase authentication.
      await showMessage("Something went wrong");
    }

    // Finally, whether the login succeeded or failed, we must stop the loading spinner by setting isLoading back to false.
    setState(() => isLoading = false);
  }

  // This function is responsible for sending a password reset email if the user forgets their password.
  // It takes the email address typed into the dialog box and sends it to Firebase.
  Future<void> resetPassword(String email) async {
    if (email.isEmpty) {
      await showMessage("Please enter your email");
      return;
    }

    try {
      // We tell Firebase to send the recovery email to the provided address.
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.trim(),
      );

      await showMessage("Password reset email sent");

    } on FirebaseAuthException catch (e) {
      await showMessage(e.message ?? "Error");
    }
  }

  // This function brings up a dialog box on the screen where the user can type in their email address to request a password reset.
  // It creates a temporary text controller just for this pop up window.
  void showResetDialog() {
    TextEditingController resetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Reset Password"),
        content: TextField(
          controller: resetController,
          decoration: InputDecoration(
            hintText: "Enter your email",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              // Once they click send, we close the dialog first and then call the reset password function with whatever they typed.
              Navigator.pop(context);
              await resetPassword(resetController.text);
            },
            child: Text("Send"),
          ),
        ],
      ),
    );
  }

  // This is a reusable helper function that pops up a simple message box on the screen to inform the user about something.
  Future<void> showMessage(String message) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Message"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // We are returning a Scaffold here which serves as the base layer for our screen.
    return Scaffold(
      body: Container(
        // We apply a dark linear gradient background to make the login screen look modern.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF020617)],
          ),
        ),
        child: SafeArea(
          // SafeArea ensures our content does not overlap with phone notches or status bars.
          child: Center(
            child: SingleChildScrollView(
              // We wrap everything in a Column so we can place the icon outside and above the main login card.
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // This is the application icon. It is positioned in the upper center part of the screen.
                  // We increased the width and height so it looks clear and prominent even on lower resolution screens.
                  Image.asset(
                    'assets/images/CampusBugHunter_icon.png',
                    width: 90,
                    height: 90,
                  ),
                  
                  SizedBox(height: 16),

                  // This is the welcome greeting text. It sits right below the icon and outside the dark card.
                  // The text size is slightly reduced so it fits nicely on a single line.
                  // We use white70 (a slightly grayish white) to distinguish it from the bright white primary titles.
                  Text(
                    "Welcome back, Hunter/Requester!",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  SizedBox(height: 35),

                  // This container holds the actual login form. It has a semi-transparent black background to separate it from the gradient.
                  Container(
                    width: 350,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [

                        // This is the main title for the login form positioned on the left side.
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        SizedBox(height: 25),

                        // This is the input field for the user email. It has a mail icon prefix and a dark gray background.
                        TextField(
                          controller: emailController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.email, color: Colors.grey),
                            hintText: "Email",
                            hintStyle: TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[900],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        SizedBox(height: 15),

                        // We group the password field and the forgot password button inside a column so they stay close together.
                        Column(
                          children: [
                            // This input field is for the password. It has an eye icon suffix that lets the user toggle password visibility when tapped.
                            TextField(
                              controller: passwordController,
                              obscureText: obscurePassword,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.lock, color: Colors.grey),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                                ),
                                hintText: "Password",
                                hintStyle: TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: Colors.grey[900],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),

                            // This is a clickable text button aligned to the right side allowing users to trigger the password reset dialog.
                            // We changed the text color to redAccent as requested.
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: showResetDialog,
                                child: Text(
                                  "Forgot password?",
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 10),

                        // This area acts as a link to navigate the user to the registration screen.
                        // We use a Row to put the non-clickable white text and the clickable blue text next to each other.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(color: Colors.white),
                            ),
                            // Only the "Register" text is wrapped in the GestureDetector, so only clicking the blue word will navigate.
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => Register()),
                                );
                              },
                              child: Text(
                                "Register",
                                style: TextStyle(color: Colors.blueAccent),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

                        // This is the main login button. It stretches to fill the entire width available.
                        // If the app is currently trying to log in it will disable the button and show a loading spinner instead of the login text.
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : login,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.blue,
                            ),
                            child: isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                              "LOGIN",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}