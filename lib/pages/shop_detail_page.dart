import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sdc/components/shop_image_carousel.dart';
import 'package:url_launcher/url_launcher.dart';

class ShopDetailPage extends StatefulWidget {
  final String vendorId;
  final String name;
  final String description;
  final String imageUrl;
  final String? whatsappNumber;

  const ShopDetailPage({
    Key? key,
    required this.vendorId,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.whatsappNumber,
  }) : super(key: key);

  @override
  State<ShopDetailPage> createState() => _ShopDetailPageState();
}

class _ShopDetailPageState extends State<ShopDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;
  double _rating = 0.0;
  String? _mapUrl;

  @override
  void initState() {
    super.initState();
    _fetchShopDetails();
    _fetchServices();
  }

  Future<void> _fetchShopDetails() async {
    try {
      final doc =
      await _firestore.collection('market_vendors').doc(widget.vendorId).get();
      if (doc.exists) {
        setState(() {
          _rating = (doc.data()?['rating'] ?? 0).toDouble();
          _mapUrl = doc.data()?['mapUrl'];
        });
      }
    } catch (e) {
      print("Error fetching shop details: $e");
    }
  }

  Future<void> _fetchServices() async {
    try {
      final snapshot = await _firestore
          .collection('market_vendors')
          .doc(widget.vendorId)
          .collection('services')
          .get();

      setState(() {
        _services = snapshot.docs.map((doc) => doc.data()).toList();
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching services: $e");
      setState(() => _isLoading = false);
    }
  }

  void _launchWhatsApp(BuildContext context) async {
    if (widget.whatsappNumber == null || widget.whatsappNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No WhatsApp number provided.")),
      );
      return;
    }

    String phone = widget.whatsappNumber!;
    if (!phone.startsWith('+')) phone = '+91$phone';

    final Uri whatsappUrl = Uri.parse(
      "https://wa.me/$phone?text=${Uri.encodeComponent('Hello ${widget.name}, I found your shop on the REC Banda App!')}",
    );

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open WhatsApp.")),
      );
    }
  }

  void _launchMap() async {
    if (_mapUrl == null || _mapUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Map location not available.")),
      );
      return;
    }

    final Uri mapUri = Uri.parse(_mapUrl!);
    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open Maps.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    double titleFont = screenWidth * 0.055;
    double subtitleFont = screenWidth * 0.035;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Carousel Section ---
              ShopImageCarousel(vendorId: widget.vendorId),
              const SizedBox(height: 20),

              // --- Shop Title ---
              // --- Shop Title ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.name,
                      style: TextStyle(
                        fontSize: titleFont,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis, // ✅ Prevent text overflow
                    ),
                  ),
                  const SizedBox(width: 10),

                  // ⭐ Rating (if available)
                  if (_rating > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.yellow[700],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            "Rating: ",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const Icon(Icons.star, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            _rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(width: 10),

                  // 📍 Get Directions Button (right side)
                  ElevatedButton.icon(
                    onPressed: _launchMap,
                    icon: const Icon(Icons.directions, size: 16),
                    label: const Text("Directions"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // --- Description ---
              Text(
                widget.description,
                style: TextStyle(
                  fontSize: subtitleFont,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // --- Map Button ---

              const SizedBox(height: 20),

              // --- Services Section ---
              Text(
                "Available Services",
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[900],
                ),
              ),
              const SizedBox(height: 10),

              _services.isEmpty
                  ? const Text("No services available for this shop.")
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _services.length,
                itemBuilder: (context, index) {
                  final service = _services[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          service['imageUrl'] ?? '',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) =>
                          const Icon(
                              Icons.image_not_supported),
                        ),
                      ),
                      title: Text(
                        service['name'] ?? 'Unnamed Service',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "${service['description'] ?? ''}",
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: Text(
                        "₹${service['price'] ?? '--'}",
                        style: TextStyle(
                          fontSize: subtitleFont,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              // --- WhatsApp Contact ---
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _launchWhatsApp(context),
                  icon: const Icon(Icons.chat_bubble_outline_outlined),
                  label: const Text("Contact on WhatsApp"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.08,
                      vertical: screenHeight * 0.018,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
