import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login.dart';
import 'homepage.dart';

// This file acts as the main authentication gatekeeper for the entire application.
// It decides whether to show the login screen or the main homepage based on the user's current login status.
class Auth extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // We use a StreamBuilder here. This widget constantly listens to a stream of data.
    // In this case, it is listening to FirebaseAuth to see if the authentication state changes, such as when a user logs in or logs out.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // While the app is actively trying to connect to Firebase to figure out the user's status, the connection state is waiting.
        // During this brief moment, we show a basic blank screen with a spinning circular progress indicator in the center so the user knows something is loading.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If the snapshot has data, it means Firebase has confirmed that a valid user is currently logged in.
        // In this case, we bypass the login screen completely and directly return the Homepage widget to let them into the app.
        if (snapshot.hasData) {
          return Homepage();
        }

        // If the snapshot does not have data, it means no user is logged in or their session has expired.
        // Therefore, we return the Login widget so they can enter their credentials to access the app.
        return Login();
      },
    );
  }
}