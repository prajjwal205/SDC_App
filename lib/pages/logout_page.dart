import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sdc/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogoutPage extends StatefulWidget {
  const LogoutPage({super.key});

  @override
  State<LogoutPage> createState() => _LogoutPageState();
}

class _LogoutPageState extends State<LogoutPage> {
  @override
  void initState() {
    super.initState();
    // Start the logout process as soon as the page is loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logout(context);
    });
  }

  // This function handles the complete logout logic.
  Future<void> _logout(BuildContext context) async {
    try {
      // 1. Sign out from Google Sign-In. This is crucial for a complete logout.
      await GoogleSignIn().signOut();

      // 2. Sign out from Firebase Authentication.
      await FirebaseAuth.instance.signOut();

      // 3. Clear any stored user data.
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 4. Navigate to the LoginPage and clear all previous routes
      // so the user cannot navigate back to the home page.
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => LoginPage(
              onTap: () {},
            ),
          ),
              (route) => false,
        );
      }
    } catch (e) {
      print("Error during logout: $e");
      // Handle any errors here, e.g., show a snackbar.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error logging out: ${e.toString()}'))
        );
        // Navigate back if logout fails.
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Display a loading indicator while the logout process is running.
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Logging out..."),
          ],
        ),
      ),
    );
  }
}
