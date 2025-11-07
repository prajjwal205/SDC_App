import 'package:flutter/material.dart';
import 'package:sdc/components/my_button.dart';
import 'package:sdc/components/my_textfield.dart';
import 'package:sdc/components/square_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'phone_auth_page.dart';
import '../services/auth_service.dart';



class LoginPage extends StatefulWidget {
  final Function()? onTap;
  LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
final emailController = TextEditingController();
final passwordController = TextEditingController();

// sign user in method
void signUserIn() async {
  // show best  and modern loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Container(
        color: Colors.black54, // semi-transparent background
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
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailController.text,
      password: passwordController.text,
    );
    Navigator.pop(context);
  } on FirebaseAuthException catch (e) {
    Navigator.pop(context); // Close loading dialog

    String message;

    if (e.code == 'user-not-found') {
      message = 'No user found for that email.';
    } else if (e.code == 'wrong-password') {
      message = 'Incorrect password. Try again.';
    } else {
      message = e.message ?? 'Login failed. Please try again.';
    }

    // Show error message in a dialog
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        backgroundColor: Colors.red,
        title: Center(
          child: Text('Incorrect Email',
          style: TextStyle(color: Colors.white),),
        ),
        // actions: [
        //   TextButton(
        //     onPressed: () => Navigator.pop(context),
        //     child: const Text('OK'),
        //   ),
        // ],
      ),
    );
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
              // ✅ added scrollable container
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.03,
                vertical: size.height * 0.03,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                //logo
                  Image.asset(
                    'lib/assets/images/sdc_logo.png', // <--- Your logo path here
                    height: size.height * 0.25,
                    width: size.width * 0.60,// Adjusted height for a logo
                  ),
                  SizedBox(height: size.height*0.01),
                //welcome back
                  const Text(
                    'Welcome back, developer!',
                    style: TextStyle(
                        fontSize: 22,
                        color: Colors.black,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'We missed you. Sign in to continue.',
                    style: TextStyle(
                        color: Colors.grey[100],
                        fontSize: 16),
                  ),
                SizedBox(height: size.height*0.04),

                //username textfield
                MyTextField(
                 controller: emailController,
                  hintText: 'Username',
                  obscureText: false,
                ),
                  SizedBox(height: size.height *0.015,),

                //password textfield
                  MyTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                  ),
                  SizedBox(height: size.height *0.015,),

                //forgot password?
                Padding(
                  padding: EdgeInsets.symmetric(horizontal:
                  MediaQuery.of(context).size.width*0.06),
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
                  SizedBox(height: size.height *0.03),


                //signin button
                  MyButton(
                    text: "Sign in",
                    onTap: signUserIn,
                  ),
                   SizedBox(height: size.height*0.04),

                //or continue with

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
                      horizontal:MediaQuery.of(context).size.height*.02),
                  child: Text('Or continue with',
                  style: TextStyle(color: Colors.grey[100]
                  ),),
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

                  //google + apple signin button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // //google image
                  // Image.asset('lib/assets/images/goole1.png',
                  //   height:MediaQuery.of(context).size.height*.05,),
                  SquareTile(
                    imagePath: 'lib/assets/images/goole1.png',
                    onTap: () async {
                      final userCredential = await AuthService().signInWithGoogle();
                      if (userCredential != null) {
                        print("Signed in as: ${userCredential.user?.displayName}");
                      } else {
                        print("Google Sign-In canceled or failed");
                      }
                    },
                  ),

                  SizedBox(width: size.width *0.06),
              // apple image
                  SquareTile(imagePath: 'lib/assets/images/appler.png'),
                  SizedBox(width: size.width *0.06),

                  // facebook image
      // OTP image
                  SquareTile(
                    imagePath: 'lib/assets/images/otp.png',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PhoneAuthPage()),
                      );
                    },
                  ),              ],
              ),
                 SizedBox(height: size.height *0.04),

                //not a member register now

                  Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Not a member?',
                  style: TextStyle(
                    color: Colors.grey[100],
                  ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: const Text(
                      'Register now',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                // not a member register now
              ],),
                  SizedBox(height: size.height * 0.01),

                ]
                      ),
            ),
        ),
        ),
      ),
    );

  }
}
