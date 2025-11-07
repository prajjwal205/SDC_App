import 'package:flutter/material.dart';

class SimpleShopCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String description;
  final VoidCallback onContactTap;
  final VoidCallback onKnowMoreTap;

  const SimpleShopCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.onContactTap,
    required this.onKnowMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // 🔹 Responsive scaling factors
    double buttonHeight = screenHeight * 0.045;
    double fontSize = screenWidth * 0.028;
    double iconSize = screenWidth * 0.035;
    double cardPadding = screenWidth * 0.025;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        // Keeps card height consistent across grid cells
        constraints: const BoxConstraints(minHeight: 200, maxHeight: 350),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- Shop Image ---
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print("Error loading shop image: $error");
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.storefront,
                            color: Colors.grey, size: 40),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // --- Shop Info ---
                Text(
                  name,
                  style: TextStyle(
                    fontSize: fontSize + 2,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // const SizedBox(height: 4),
                // Text(
                //   description,
                //   style: TextStyle(
                //     fontSize: fontSize,
                //     color: Colors.grey[700],
                //     height: 1.3,
                //   ),
                //   maxLines: 3, // Increased a bit since it's scrollable
                //   overflow: TextOverflow.ellipsis,
                // ),
                const SizedBox(height: 10),

                // --- Buttons ---
                Column(
                  children: [
                    SizedBox(height: cardPadding / 2),
                    SizedBox(
                      width: double.infinity,
                      height: buttonHeight,
                      child: ElevatedButton.icon(
                        onPressed: onKnowMoreTap,
                        icon: Icon(Icons.double_arrow_outlined, size: iconSize),
                        label: Text(
                          "Know More",
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey[900],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: buttonHeight * 0.15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
