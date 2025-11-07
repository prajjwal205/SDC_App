import 'dart:async'; // 1. ADDED: For StreamSubscription
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactsSection extends StatefulWidget {
  const ContactsSection({super.key});

  @override
  State<ContactsSection> createState() => _ContactsSectionState();
}

class _ContactsSectionState extends State<ContactsSection> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _contactList = [];
  bool _isLoading = true;
  bool _isExpanded = false;

  // 2. ADDED: A variable to hold our database listener
  StreamSubscription? _contactSubscription;

  @override
  void initState() {
    super.initState();
    // 3. CHANGED: Call the new listener function
    _listenToContactData();
  }

  @override
  void dispose() {
    // 4. ADDED: Cancel the listener when the widget is removed
    _contactSubscription?.cancel();
    super.dispose();
  }

  // 5. NEW FUNCTION: This sets up the real-time listener
  void _listenToContactData() {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    _contactSubscription?.cancel(); // Cancel any old listener

    _contactSubscription = _firestore
        .collection('contacts')
        .snapshots() // <-- This is the change from .get()
        .listen(
          (snapshot) {
        if (!mounted) return;
        setState(() {
          _contactList = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'name': data.containsKey('name') ? data['name'] : 'Unknown Name',
              'phone': data.containsKey('phone') ? data['phone'] : 'No Phone',
              'type': data.containsKey('type') ? data['type'] : 'Other',
              'description': data.containsKey('description')
                  ? data['description']
                  : '',
            };
          }).toList();
          _isLoading = false;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contacts: $e')),
        );
      },
    );
  }

  // 6. REMOVED: The old _fetchContactData() function is no longer needed.

  void _makePhoneCall(String? number) async {
    // ... (This function remains unchanged)
    if (number == null || number.isEmpty || number == 'No Phone') {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Invalid phone number")));
      return;
    }
    final Uri url = Uri(scheme: 'tel', path: number);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Cannot launch dialer")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error launching dialer: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // The entire build method remains unchanged
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.white,
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.call, color: Colors.black87, size: 30),
            title: const Text(
              "Contacts",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            trailing: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: ConstrainedBox(
              constraints: _isExpanded
                  ? const BoxConstraints()
                  : const BoxConstraints(maxHeight: 0),
              child: _isLoading
                  ? const Padding(
                padding: EdgeInsets.all(16.0),
                child:
                Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
                  : _contactList.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text("No contacts available.")),
              )
                  : ListView.builder(
                itemCount: _contactList.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                itemBuilder: (context, index) {
                  final data = _contactList[index];
                  return Padding(
                    padding:
                    const EdgeInsets.symmetric(vertical: 6.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(data['phone'] ?? 'N/A',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700])),
                                Text(data['type'] ?? 'N/A',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500])),
                                if (data['description'] != null &&
                                    data['description'].isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 4.0),
                                    child: Text(
                                        data['description'],
                                        style: TextStyle(
                                            fontSize: 12,
                                            color:
                                            Colors.grey[600])),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () =>
                                _makePhoneCall(data['phone'] ?? ''),
                            icon: const Icon(Icons.phone,
                                color: Colors.white, size: 18),
                            label: const Text("Call"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              textStyle:
                              const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
