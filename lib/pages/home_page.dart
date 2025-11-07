import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sdc/components/event_carousel.dart';
import 'package:sdc/pages/academic_resources_page.dart';
import 'package:sdc/pages/clubs_page.dart';
import 'package:sdc/pages/logout_page.dart';
import 'package:sdc/pages/market_page.dart';
import 'package:sdc/pages/profile_page.dart';
import 'package:sdc/pages/sports_directory_page.dart';
import 'package:url_launcher/url_launcher.dart';
// 1. ADDED: Import for the new ContactsSection component
import 'package:sdc/components/contacts_section.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String userName = "";
  String userYear = "";
  String userBranch = "";


  @override
  void initState() {
    super.initState();
    _fetchUserData();// 3. REMOVED: No need to fetch transport data here anymore
    // _fetchTransportData();
  }



  Future<void> _fetchUserData() async {
    // Added mount check for safety
    if (!mounted) return;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          userName = doc['name'] ?? "Student";
          userYear = doc['year'] ?? "Year ?";
          userBranch = doc['branch'] ?? "Branch ?";
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error fetching user data: ${e.toString()}")));
      }
    }
  }




  void _handleBackButton() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const LogoutPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBackButton();
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.blueGrey[900],
          elevation: 0,
          title:
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'lib/assets/images/clg_logo.png', // first image (bulb)
                height: MediaQuery.of(context).size.height * 0.07,
                width: MediaQuery.of(context).size.width * 0.15,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 1),
              Image.asset(
                'lib/assets/images/recb.png', // second image (SDC text logo)
                height: MediaQuery.of(context).size.height * 0.05,
                fit: BoxFit.contain,
              ),
            ],
          ),

          actions: [
            IconButton(
              icon: const Icon(Icons.account_circle, color: Colors.white),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
                _fetchUserData(); // Refresh data after returning
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: Colors.white,
              onSelected: (value) {
                if (value == 'logout') {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const LogoutPage()),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'logout',
                  child: Text('Logout'),
                ),
              ],
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EventCarousel(),

              const SizedBox(height: 8),
              Text(
                "Year: $userYear • Branch: $userBranch ",
                style: TextStyle(color: Colors.grey[700], fontSize: 15),
              ),
              const SizedBox(height: 16),

              _buildQuickAccessGrid(), // Quick Access Grid Widget Function


              // 4. ADDED: Use the new ContactsSection component here
              const ContactsSection(),

            ],
          ),
        ),
      ),
    );
  }

  // 5. REMOVED: _buildTransportSection function is now in ContactsSection widget


  Widget _buildQuickAccessGrid() {
    // 6. REMOVED: "Contacts" card from the grid, as it's now a separate section below
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: [
        _buildCard(
          icon: Icons.description,
          color: Colors.blue.shade100,
          title: "CT Papers",
          subtitle: "View & download papers",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AcademicResourcesPage()),
            );
          },
        ),
        _buildCard(
          icon: Icons.group,
          color: Colors.amber,
          title: "Clubs",
          subtitle: "Explore college clubs",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ClubsPage()),
            );
          },
        ),
        _buildCard(
          icon: Icons.shopping_bag_outlined,
          color: Colors.pink.shade100,
          title: "Atarra Market",
          subtitle: "Best shops info",
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MarketPage()),
            );
                },
        ),
        _buildCard(
          icon: Icons.sports_cricket,
          color: Colors.green.shade100,
          title: "Sports",
          subtitle: "College Sports",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SportsDirectoryPage()),
            );
          },
        ),
        // The Contacts card is removed from here
      ],
    );
  }



  Widget _buildCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16), // Match container radius
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15), // Softer shadow
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color, // Lighter background
              radius: 24,
              child: Icon(icon, color: Colors.black, size: 28), // Icon color matches accent
            ),
            const SizedBox(height: 12), // Increased spacing
            Text(title,
                style: const TextStyle(
                    fontSize: 16, // Slightly adjusted size
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4), // Spacing between title and subtitle
            Text(subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey[600])), // Adjusted color
          ],
        ),
      ),
    );
  }
}

