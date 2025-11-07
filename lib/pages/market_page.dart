import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sdc/components/restaurant_grid_item.dart';
import 'package:sdc/components/simple_shop_card.dart';
import 'package:sdc/pages/restaurant_detail_page.dart';
import 'package:sdc/pages/shop_detail_page.dart';
import 'package:url_launcher/url_launcher.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. UPDATED: Map now holds the paths to your images
  final Map<String, String> _categories = {
    'Restaurant': 'lib/assets/images/restaurent.jpg',
    'Men Salon': 'lib/assets/images/haircut.jpg',
    'Medical': 'lib/assets/images/medical.jpg',
    'Sweets/Snacks': 'lib/assets/images/sweet.jpg',
    'Electronics': 'lib/assets/images/electronic.jpg',
    'Grocery': 'lib/assets/images/grocery.jpg',
  };

  String _selectedCategory = 'Restaurant';
  bool _isLoading = true;

  List<QueryDocumentSnapshot> _allShops = [];
  List<QueryDocumentSnapshot> _filteredShops = [];

  @override
  void initState() {
    super.initState();
    _fetchAllShops();
  }

  Future<void> _fetchAllShops() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    try {
      final snapshot = await _firestore.collection('market_vendors').get();
      if (mounted) {
        _allShops = snapshot.docs;
        _filterShops();
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        print("Error fetching shops: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error loading shops. Please try again.")),
        );
      }
    }
  }

  void _filterShops() {
    _filteredShops = _allShops.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data.containsKey('category') && data['category'] == _selectedCategory;
    }).toList();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _filterShops();
    });
  }

  void _launchWhatsApp(String? phoneNumber, String shopName) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No WhatsApp number provided.")),
        );
      }
      return;
    }
    if (!phoneNumber.startsWith('+')) {
      phoneNumber = '+91$phoneNumber';
    }
    final String message = Uri.encodeComponent(
        "Hello $shopName, I'd like to inquire about your services (from the SDC App).");
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
    final categoryNames = _categories.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Atarra Market"),
        backgroundColor: Colors.blueGrey[900],

        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // --- LEFT CATEGORY SIDEBAR ---
          Container(
            width: 100,
            color: Colors.grey[100],
            padding: const EdgeInsets.only(left: 10, top: 10),
            child: Column(
              children: [
                // --- Static "For You" Section ---
                // --- Static "For You" Section ---
                Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.asset(
                            'lib/assets/images/foru.jpg', // 👈 your "For You" icon image
                            width: 55,
                            height: 55,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Text(
                        'For You',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[500],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // --- Category List ---
                Expanded(
                  child: ListView.builder(
                    itemCount: categoryNames.length,
                    itemBuilder: (context, index) {
                      final category = categoryNames[index];
                      final imagePath = _categories[category]!;
                      final isSelected = _selectedCategory == category;

                      return GestureDetector(
                        onTap: () => _onCategorySelected(category),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.grey[100],
                            border: isSelected
                                ? Border(
                              left: BorderSide(
                                color: Colors.yellow[800]!,
                                width: 4,
                              ),
                            )
                                : null,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.yellow[800]!
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.asset(
                                    imagePath,
                                    width: 70,
                                    height: 75,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                category,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.yellow[800]
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),),


          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Shops in $_selectedCategory",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[900],
                    ),
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredShops.isEmpty
                      ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        "No shops found in '$_selectedCategory'.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 16),
                      ),
                    ),
                  )
                      : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _filteredShops.length,
                    itemBuilder: (context, index) {
                      final shopDoc = _filteredShops[index];
                      final shop = shopDoc.data() as Map<String, dynamic>;

                      if (_selectedCategory == 'Restaurant') {
                        return RestaurantGridItem(
                          key: ValueKey(shopDoc.id),
                          name: shop['name'] ?? 'No Name',
                          imageUrl: shop['imageUrl'] ?? '',
                          onKnowMoreTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RestaurantDetailPage(
                                  vendorId: shopDoc.id,
                                  restaurantName: shop['name'] ?? 'Restaurant',
                                  restaurantWhatsApp: shop['whatsappNumber'] ?? '',
                                ),
                              ),
                            );
                          },
                        );
                      } else {
                        return SimpleShopCard(
                          key: ValueKey(shopDoc.id),
                          name: shop['name'] ?? 'No Name',
                          imageUrl: shop['imageUrl'] ?? '',
                          description: shop['description'] ?? 'No Description',
                          onContactTap: () => _launchWhatsApp(
                              shop['whatsappNumber'], shop['name']),
                          onKnowMoreTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ShopDetailPage(
                                  vendorId: shopDoc.id, // 👈 THIS IS THE FIX
                                  name: shop['name'] ?? 'No Name',
                                  description: shop['description'] ?? 'No Description',
                                  imageUrl: shop['imageUrl'] ?? '',
                                  whatsappNumber: shop['whatsappNumber'] ?? '',
                                ),
                              ),
                            );
                          },
                        );
                      }

                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

