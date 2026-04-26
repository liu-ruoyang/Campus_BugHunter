import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'Auth.dart';

// This is the absolute starting point of the entire Flutter application.
// The main function is the first piece of code that runs when the user opens the app on their device.
void main() async {
  // This line is extremely important when we need to do asynchronous tasks before the app interface actually runs.
  // It ensures that the underlying Flutter engine is fully initialized and ready to communicate with native device features.
  WidgetsFlutterBinding.ensureInitialized();

  // Here we initialize the Firebase connection using the specific configuration options we defined in the firebase_options.dart file.
  // This establishes the secure link between our app and the cloud database/authentication servers before the user even sees the first screen.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Once everything is set up and initialized, we tell Flutter to start building the user interface by running our root widget called MyApp.
  runApp(const MyApp());
}

// MyApp is a stateless widget that acts as the root configuration layer for the visual application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // We use a MaterialApp widget which provides many standard interface tools and routing capabilities out of the box.
    return MaterialApp(
      // This title is used by the device operating system to identify the app, such as in the recent apps task switcher.
      title: 'Campus BugHunter',
      // We set this to false to remove the small red "DEBUG" banner that usually appears in the top right corner during development.
      debugShowCheckedModeBanner: false,
      // We set the initial screen of the app to be the Auth widget. 
      // The Auth widget will then intelligently decide whether to show the login screen or the main homepage based on the user's session.
      home: Auth(),
    );
  }
}