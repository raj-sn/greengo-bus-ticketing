import 'package:flutter/material.dart';
import 'package:gticketing/auth/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures binding before Firebase init
  await Firebase.initializeApp(); // Initializes Firebase
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GTicketing',
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 30, 43, 30),
        primarySwatch: Colors.green,
      ),
      home: AuthCheck(),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream:
          FirebaseAuth.instance
              .authStateChanges(), // Listen for auth state changes
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          ); // Show loading screen
        }
        if (snapshot.hasData) {
          return homepage(); // User is signed in → Go to HomeScreen
        }
        return LoginPage(); // User is NOT signed in → Go to LoginScreen
      },
    );
  }
}
