import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class ShopImageCarousel extends StatefulWidget {
  final String vendorId;

  const ShopImageCarousel({super.key, required this.vendorId});

  @override
  State<ShopImageCarousel> createState() => _ShopImageCarouselState();
}

class _ShopImageCarouselState extends State<ShopImageCarousel> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _imageUrls = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchGalleryImages();
  }

  Future<void> _fetchGalleryImages() async {
    try {
      final snapshot = await _firestore
          .collection('market_vendors')
          .doc(widget.vendorId)
          .collection('gallery')
          .get();

      setState(() {
        _imageUrls =
            snapshot.docs.map((doc) => doc['imageUrl'] as String).toList();
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching gallery images: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_imageUrls.isEmpty) {
      return const Center(
        child: Text(
          "No images available",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final bool isSingleImage = _imageUrls.length == 1;

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: _imageUrls.length,
          options: CarouselOptions(
            aspectRatio: 16 / 9,
            enlargeCenterPage: !isSingleImage,
            autoPlay: !isSingleImage, // ✅ AutoPlay only if more than 1 image
            enableInfiniteScroll: !isSingleImage, // ✅ Prevent loop on single
            viewportFraction: 0.9,
            autoPlayInterval: const Duration(seconds: 3),
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
            },
          ),
          itemBuilder: (context, index, realIndex) {
            final imageUrl = _imageUrls[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 50),
                  );
                },
              ),
            );
          },
        ),

        // --- Indicators (only show if multiple images)
        if (!isSingleImage) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _imageUrls.asMap().entries.map((entry) {
              return Container(
                width: 8,
                height: 8,
                margin:
                const EdgeInsets.symmetric(vertical: 4, horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == entry.key
                      ? Colors.black
                      : Colors.grey[400],
                ),
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 8),
        Text(
          "Shop Gallery",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
      ],
    );
  }
}
