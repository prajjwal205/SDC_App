import 'package:flutter/material.dart';
class MyButton extends StatelessWidget {
  final void Function() onTap;
  final String text;
  const MyButton({super.key, required this.onTap, required this.text});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(MediaQuery.of(context).size.height*.02),
        margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width*.05),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: onTap != null
                ? [
              const Color(0xFF3A7FCA), // Blue (approx.)
              const Color(0xFFF98C1E), // Orange (approx.)
            ]
                : [
              Colors.grey.shade600, // Disabled color
              Colors.grey.shade500, // Disabled color
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),

        ),
        child:  Center(
            child:Text(
                text,
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.bold, fontSize: 18),
            ),
        ),
      ),
    );
  }
}
