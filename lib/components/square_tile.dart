import 'package:flutter/material.dart';
class SquareTile extends StatelessWidget {
  final String imagePath;
  final Function()? onTap;

  const SquareTile({super.key,required this.imagePath,  this.onTap});
  // final Function()? onTap;
  // const SquareTile({super.key, required this.imagePath, required  onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.08, // box size
        width: MediaQuery.of(context).size.height * 0.08,

        decoration:BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.amber),
          borderRadius: BorderRadius.circular(15),
        ),


        child: Padding(
          padding: const EdgeInsets.all(10.0), // reduce logo size
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
