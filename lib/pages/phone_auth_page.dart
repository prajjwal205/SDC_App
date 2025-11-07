import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pinput/pinput.dart';
import 'package:sdc/components/my_button.dart';
// import 'package:sdc/components/my_textfield.dart'; // Removed this import
import 'package:sdc/services/auth_service.dart';

import 'home_page.dart';

class PhoneAuthPage extends StatefulWidget {
  const PhoneAuthPage({super.key});

  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _authService = AuthService();

  String? _verificationId;
  bool _isOtpSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // Show a loading dialog
  void _showLoading(bool isLoading) {
    if (isLoading) {
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
    } else {
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss the dialog
    }
  }

  // Send OTP to the user's phone
  void _sendOtp() async {
    setState(() {
      _isLoading = true;
    });
    _showLoading(true);

    String phoneNumber = "+91${_phoneController.text.trim()}";

    await _authService.sendOtp(
      context: context, // <-- FIXED: Added required context
      phoneNumber: phoneNumber,
      onVerificationFailed: (e) {
        setState(() {
          _isLoading = false;
        });
        _showLoading(false);
        _showErrorDialog("Verification Failed: ${e.message}");
      },
      onCodeSent: (verificationId, resendToken) {
        setState(() {
          _verificationId = verificationId;
          _isOtpSent = true;
          _isLoading = false;
        });
        _showLoading(false);
      },
      // <-- FIXED: Removed 'onCodeAutoRetrievalTimeout' as it's handled by the AuthService
    );
  }

  // Verify the OTP entered by the user
  void _verifyOtp() async {
    if (_verificationId == null) {
      _showErrorDialog("Verification ID not found. Please try again.");
      return;
    }

    setState(() {
      _isLoading = true;
    });
    _showLoading(true);

    try {
      // --- FIXED: Changed to named parameters ---
      final userCredential = await _authService.verifyOtp(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );
      // ------------------------------------------

      _showLoading(false);
      setState(() {
        _isLoading = false;
      });

      if (userCredential != null) {
        // Navigate to HomePage on successful verification
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
              (route) => false,
        );
      } else {
        _showErrorDialog("Invalid OTP. Please try again.");
      }
    } catch (e) {
      _showLoading(false);
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog("An error occurred: ${e.toString()}");
    }
  }

  // Show an error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red,
        title: Center(
          child: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Pinput theme
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(fontSize: 22, color: Colors.black),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[700]),
          onPressed: () {
            if (_isOtpSent) {
              setState(() {
                _isOtpSent = false;
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.1,
              vertical: size.height * 0.03,
            ),
            child: _isOtpSent
                ? _buildOtpView(size, defaultPinTheme)
                : _buildPhoneInputView(size),
          ),
        ),
      ),
    );
  }

  // Widget for Phone Number Input View
  Widget _buildPhoneInputView(Size size) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'lib/assets/images/sdc_logo.png', // <--- Your logo path here
          height: size.height * 0.25,
          width: size.width * 0.60,// Adjusted height for a logo
        ),
        const Text(
          'Enter your phone number',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        SizedBox(height: size.height * 0.01),
        Text(
          'We will send you a 6-digit verification code',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: size.height * 0.04),
        // --- FIXED: Replaced MyTextField with standard TextFormField ---
        // This resolves the 'undefined parameter' errors for 'keyboardType' and 'prefixText'
        TextFormField(
          controller: _phoneController,
          obscureText: false,
          keyboardType: TextInputType.phone,
          style: TextStyle(color: Colors.grey[700]),
          decoration: InputDecoration(
            hintText: 'Phone Number (10 digits)',
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixText: "+91 | ",
            prefixStyle: TextStyle(color: Colors.grey[700], fontSize: 16),
            filled: true,
            fillColor: Colors.white, // Changed fill color
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none, // Removed default border
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
            ),
          ),
        ),
        // -------------------------------------------------------------
        SizedBox(height: size.height * 0.03),
        MyButton(
          text: "Send OTP",
          onTap: _sendOtp,
        ),
      ],
    );
  }

  // Widget for OTP Input View
  Widget _buildOtpView(Size size, PinTheme defaultPinTheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'lib/assets/images/sdc_logo.png', // <--- Your logo path here
          height: size.height * 0.25,
          width: size.width * 0.60,// Adjusted height for a logo
        ),
        Text(
          'Enter Verification Code',
          style: TextStyle(color: Colors.grey[700], fontSize: 18),
        ),
        SizedBox(height: size.height * 0.01),
        Text(
          'Enter the 6-digit code sent to\n+91 ${_phoneController.text.trim()}',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: size.height * 0.04),
        Pinput(
          length: 6,
          controller: _otpController,
          defaultPinTheme: defaultPinTheme,
          focusedPinTheme: defaultPinTheme.copyWith(
            decoration: defaultPinTheme.decoration!.copyWith(
              border: Border.all(color: Colors.blue),
            ),
          ),
          submittedPinTheme: defaultPinTheme.copyWith(
            decoration: defaultPinTheme.decoration!.copyWith(
              border: Border.all(color: Colors.green),
            ),
          ),
          onCompleted: (pin) => _verifyOtp(),
        ),
        SizedBox(height: size.height * 0.03),
        MyButton(
          text: "Verify OTP",
          onTap: _verifyOtp,
        ),
      ],
    );
  }
}
