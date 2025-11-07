import 'package:firebase_auth/firebase_auth.dart';
import 'package:sdc/pages/login_or_register.dart';
import 'package:sdc/pages/login_page.dart';
import 'home_page.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {

          // Show loading while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          // user is logged in
          if (snapshot.hasData) {
            return  HomePage();
          }

          // user is not Logged in
          else {
            return LoginOrRegisterPage();
          }
        }
          ),
    );
  }
}
