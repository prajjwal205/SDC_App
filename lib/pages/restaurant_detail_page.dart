import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RestaurantDetailPage extends StatefulWidget {
  final String vendorId; // The document ID of the restaurant
  final String restaurantName;
  final String restaurantWhatsApp; // Main WhatsApp number

  const RestaurantDetailPage({
    super.key,
    required this.vendorId,
    required this.restaurantName,
    required this.restaurantWhatsApp,
  });

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to launch WhatsApp for a specific item
  void _orderOnWhatsApp(String itemName, String price) async {
    String phoneNumber = widget.restaurantWhatsApp;
    if (phoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("This restaurant has not provided a WhatsApp number.")),
        );
      }
      return;
    }

    if (!phoneNumber.startsWith('+')) {
      phoneNumber = '+91$phoneNumber';
    }

    final String message = Uri.encodeComponent(
        "Hello ${widget.restaurantName}, I'd like to order:\n\n1 x $itemName (₹$price)\n\n(From the SDC App)");
    final Uri whatsappUrl =
    Uri.parse("https://wa.me/$phoneNumber?text=$message");

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $whatsappUrl';
      }
    } catch (e) {
      if (mounted) {
        print("Error launching WhatsApp: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open WhatsApp.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurantName),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        // 1. Fetch the main restaurant document
        future: _firestore.collection('market_vendors').doc(widget.vendorId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading restaurant details."));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Restaurant not found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String name = data['name'] ?? 'Restaurant';
          final String imageUrl = data['imageUrl'] ?? '';
          final String description = data['description'] ?? 'No description.';
          final List<dynamic> bestForList = data['bestFor'] ?? [];
          final String bestFor = bestForList.join(' • ');

          return Column(
            children: [
              // --- Header Section ---
              _buildHeader(imageUrl, name, description, bestFor),
              // --- Menu Section ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Text(
                  "Menu",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),

              // 2. Fetch the menu_items subcollection
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('market_vendors')
                      .doc(widget.vendorId)
                      .collection('menu_items')
                      .snapshots(),
                  builder: (context, menuSnapshot) {
                    if (menuSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                    }
                    if (menuSnapshot.hasError) {
                      return const Center(child: Text("Error loading menu."));
                    }
                    if (!menuSnapshot.hasData || menuSnapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("This restaurant has not added a menu yet."));
                    }

                    final menuItems = menuSnapshot.data!.docs;

                    return ListView.builder(
                      itemCount: menuItems.length,
                      padding: const EdgeInsets.all(12.0),
                      itemBuilder: (context, index) {
                        final item = menuItems[index].data() as Map<String, dynamic>;
                        final String itemName = item['itemName'] ?? 'No Name';
                        final String itemPrice = item['price']?.toString() ?? 'N/A';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Text(itemName, style: const TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: Text("₹$itemPrice"),
                            trailing: ElevatedButton.icon(
                              icon: const Icon(Icons.chat_bubble_outline, size: 16),
                              label: const Text("Order"),
                              onPressed: () => _orderOnWhatsApp(itemName, itemPrice),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper widget for the top section of the page
  Widget _buildHeader(String imageUrl, String name, String description, String bestFor) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restaurant Image
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
                onError: (error, stackTrace) => print("Error loading header image: $error"),
              ),
            ),
            // Fallback for image load error
            child: imageUrl.isEmpty ? Center(child: Icon(Icons.broken_image, color: Colors.grey[300], size: 50)) : null,
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            description,
            style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.4),
          ),
          const SizedBox(height: 12),
          // Best For
          if (bestFor.isNotEmpty) ...[
            const Text(
              "Best for:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              bestFor,
              style: TextStyle(fontSize: 15, color: Colors.grey[700]),
            ),
          ]
        ],
      ),
    );
  }
}

