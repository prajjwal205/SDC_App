import 'package:flutter/material.dart';
import 'package:sdc/components/my_button.dart';
import 'package:sdc/components/my_textfield.dart';
import 'package:sdc/components/square_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmedpasswordController = TextEditingController();

  // ✅ function to show error messages
  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red,
        title: const Center(
          child: Text(
            'Error',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // sign user up method
  void signUserUp() async {
    // show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Container(
          color: Colors.black54,
          child: const Center(
            child: SpinKitDualRing(
              color: Colors.amber,
              size: 70.0,
            ),
          ),
        );
      },
    );

    try {
      // check password confirmation
      if (passwordController.text == confirmedpasswordController.text) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        Navigator.pop(context); // close loading indicator
      } else {
        Navigator.pop(context);
        showErrorMessage('Passwords do not match');
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Close loading dialog

      String message;

      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'weak-password') {
        message = 'Password should be at least 6 characters.';
      } else {
        message = e.message ?? 'Registration failed. Please try again.';
      }

      showErrorMessage(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF5F5F6), // Lighter top color (approx.)
            Color(0xFF3A425A), // Darker bottom color (approx.)
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),

      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.03,
                vertical: size.height * 0.03,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // logo
                  Image.asset(
                    'lib/assets/images/sdc_logo.png', // <--- Your logo path here
                    height: size.height * 0.25,
                    width: size.width * 0.60,// Adjusted height for a logo
                  ),
                  SizedBox(height: size.height * 0.001),

                  // welcome text
                  Text(
                    'Welcome back you\'ve been missed!',
                    style: TextStyle(color: Colors.grey[200], fontSize: 16),
                  ),
                  SizedBox(height: size.height * 0.04),

                  // username textfield
                  MyTextField(
                    controller: emailController,
                    hintText: 'Username',
                    obscureText: false,
                  ),
                  SizedBox(height: size.height * 0.015),

                  // password textfield
                  MyTextField(
                    controller: passwordController,
                    hintText: 'Password',
                    obscureText: true,
                  ),
                  SizedBox(height: size.height * 0.010),

                  // confirm password textfield
                  MyTextField(
                    controller: confirmedpasswordController,
                    hintText: 'Confirm Password',
                    obscureText: true,
                  ),
                  SizedBox(height: size.height * 0.015),

                  // forgot password
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.06),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.grey[100]),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: size.height * 0.03),

                  // sign up button
                  MyButton(
                    text: 'Sign Up',
                    onTap: signUserUp,
                  ),
                  SizedBox(height: size.height * 0.04),

                  // or continue with
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            color: Colors.grey[400],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal:
                              MediaQuery.of(context).size.height * .02),
                          child: Text(
                            'Or continue with',
                            style: TextStyle(color: Colors.grey[100]),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: size.height * 0.015),

                  // social login buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SquareTile(imagePath: 'lib/assets/images/goole1.png'),
                      SizedBox(width: size.width * 0.06),
                      SquareTile(imagePath: 'lib/assets/images/appler.png'),
                      SizedBox(width: size.width * 0.06),
                      SquareTile(imagePath: 'lib/assets/images/otp.png'),
                    ],
                  ),
                  SizedBox(height: size.height * 0.04),

                  // already have an account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: TextStyle(color: Colors.grey[100]),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: const Text(
                          'Login now',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: size.height * 0.01),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
