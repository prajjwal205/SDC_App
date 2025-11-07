import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType; // Added for phone number
  final String? prefixText; // Added for phone number

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    this.keyboardType, // Make optional
    this.prefixText, // Make optional
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.06),
      child: TextFormField( // Changed to TextFormField for consistency
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.grey[800]), // Text color
        decoration: InputDecoration(
          // --- Style Update ---
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none, // No border when enabled
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide:
            BorderSide(color: Colors.blueAccent, width: 2), // Blue border when focused
            borderRadius: BorderRadius.circular(12),
          ),
          fillColor: Colors.white, // Background color from image
          filled: true,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixText: prefixText,
          prefixStyle: TextStyle(color: Colors.grey[700], fontSize: 16),
          // --- End Style Update ---
        ),
      ),
    );
  }
}
