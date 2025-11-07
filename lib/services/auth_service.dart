import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("Error during Google sign-in: $e");
      return null;
    }
  }

  // --- Phone OTP Verification ---

  // Method to send OTP (wraps verifyPhoneNumber)
  Future<void> sendOtp({
    required BuildContext context,
    required String phoneNumber, // Must include country code, e.g., +11234567890
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    VoidCallback? onVerificationCompleted, // Optional: for auto-retrieval
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          // This callback is triggered on auto-retrieval (mainly on Android)
          // You might want to auto-sign-in the user here
          if (onVerificationCompleted != null) {
            onVerificationCompleted();
          }
          // Example: _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          // Handle failed verification
          onVerificationFailed(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          // This is what you need to trigger OTP entry
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Handle timeout - e.g., resend OTP UI
        },
      );
    } on FirebaseAuthException catch (e) {
      onVerificationFailed(e);
    }
  }

  // Method to verify the OTP (wraps signInWithCredential)
  Future<UserCredential?> verifyOtp({
    required String verificationId,
    required String smsCode, // The 6-digit OTP from the user
  }) async {
    try {
      // Create a PhoneAuthCredential with the code
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Sign the user in (or link) with the credential
      UserCredential userCredential =
      await _auth.signInWithCredential(credential);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle error (e.g., invalid OTP)
      debugPrint('Failed to verify OTP: ${e.message}');
      return null;
    }
  }

  // THE ULTIMATE SIGN OUT METHOD
  Future<void> signOut() async {
    try {

      // Step 1: Sign out from Google. This is the key.
      // disconnect() is more forceful than signOut().
      await _googleSignIn.disconnect();

      // Step 2: Sign out from Firebase
      await _auth.signOut();

    } catch (e) {
      print("Error during sign out: $e");
    }
  }
}

