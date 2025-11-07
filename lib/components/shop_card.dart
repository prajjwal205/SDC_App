import 'package:flutter/material.dart';

class ShopCard extends StatelessWidget {
  final String shopName;
  final String shopImageUrl;
  final String description;
  final VoidCallback onCardTap; // Action for tapping the card

  const ShopCard({
    super.key,
    required this.shopName,
    required this.shopImageUrl,
    required this.description,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // Ensures image respects rounded corners
      child: InkWell(
        onTap: onCardTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Shop Image
            Expanded(
              flex: 3, // Image takes more space
              child: Image.network(
                shopImageUrl,
                fit: BoxFit.cover,
                // Loading placeholder
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                },
                // Error placeholder
                errorBuilder: (context, error, stackTrace) {
                  print("Error loading network image $shopImageUrl: $error");
                  return Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.storefront, color: Colors.grey[400], size: 40),
                  );
                },
              ),
            ),
            // Shop Details
            Expanded(
              flex: 2, // Text takes less space
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Pushes icon to bottom
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shopName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    // WhatsApp Icon at the bottom right
                    Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        Icons.chat_bubble_outline,
                        size: 24,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
