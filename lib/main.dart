// This file is the Flutter application entry point.
// It initializes Firebase, wires the root authentication cubit, and launches the first authentication gate screen.
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/auth/auth_cubit.dart';
import 'bloc/theme/theme_cubit.dart';
import 'firebase_options.dart';
import 'pages/auth.dart';
import 'theme/app_theme.dart';

// The main function prepares Flutter bindings, connects Firebase with platform options, and starts the app widget tree.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

// MyApp provides the top-level MaterialApp and exposes AuthCubit to the entire application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(create: (_) => ThemeCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeMode,
            home: const Auth(),
          );
        },
      ),
    );
  }
}
