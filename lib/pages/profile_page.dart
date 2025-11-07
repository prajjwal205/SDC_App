import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sdc/components/my_button.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedYear;
  String? _selectedBranch;

  final List<String> _years = ['1st', '2nd', '3rd', '4th'];
  final List<String> _branches = ['IT', 'EE', 'ME'];

  // --- 1. NEW: Master lists for all clubs and sports ---
  final List<String> _allClubs = [
    'SDC', 'IoT', 'Drone', 'WDC', 'LLC', 'Media Club', 'IEEE', 'MDAC', 'Vigyan Club'
  ];
  final List<String> _allSports = [
    'Basketball', 'Volleyball', 'Football', 'Cricket', 'TT', 'Badminton', 'Chess', 'Carrom', 'Athletics'
  ];

  // --- 2. NEW: State variables to hold user's selections ---
  List<String> _selectedClubs = [];
  List<String> _selectedSports = [];

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  String _statusMessage = "";

  StreamSubscription? _userSubscription;

  @override
  void initState() {
    super.initState();
    _listenToUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _userSubscription?.cancel();
    super.dispose();
  }

  void _listenToUserData() {
    setState(() {
      _isLoading = true;
      _statusMessage = "";
    });

    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Error: Not logged in.";
      });
      return;
    }

    _userSubscription?.cancel();
    _userSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
          (doc) {
        if (doc.exists && mounted) {
          final data = doc.data()!;
          if (_nameController.text != (data['name'] ?? '')) {
            _nameController.text = data['name'] ?? '';
          }
          if (_addressController.text != (data['address'] ?? '')) {
            _addressController.text = data['address'] ?? '';
          }

          String? newYear = _years.contains(data['year']) ? data['year'] : null;
          String? newBranch = _branches.contains(data['branch']) ? data['branch'] : null;

          // --- 3. NEW: Load selected clubs and sports ---
          // We safely cast the List<dynamic> from Firebase to List<String>
          List<String> newClubs = data.containsKey('selectedClubs')
              ? List<String>.from(data['selectedClubs'])
              : [];
          List<String> newSports = data.containsKey('selectedSports')
              ? List<String>.from(data['selectedSports'])
              : [];

          setState(() {
            _selectedYear = newYear;
            _selectedBranch = newBranch;
            _selectedClubs = newClubs;
            _selectedSports = newSports;
            _isLoading = false; // Mark as loaded
          });
        } else if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _statusMessage = "Error: ${e.toString()}";
            _isLoading = false;
          });
        }
      },
    );
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = "";
    });

    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Error: Not logged in.";
      });
      return;
    }

    try {
      // --- 4. NEW: Add selected clubs and sports to the data to be saved ---
      final profileData = {
        'name': _nameController.text.trim(),
        'year': _selectedYear,
        'branch': _selectedBranch,
        'address': _addressController.text.trim(),
        'uid': user.uid,
        'email': user.email,
        'selectedClubs': _selectedClubs, // <-- ADDED
        'selectedSports': _selectedSports, // <-- ADDED
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(profileData, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _statusMessage = "Profile Saved Successfully!";
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile Saved!"),
            backgroundColor: Colors.green,
          ),
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = "Error: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  // --- 5. NEW: Reusable widget to build a section of selectable chips ---
  Widget _buildChipSection({
    required String title,
    required List<String> allOptions,
    required List<String> selectedOptions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Wrap(
          spacing: 8.0, // Horizontal gap
          runSpacing: 8.0, // Vertical gap
          children: allOptions.map((option) {
            final isSelected = selectedOptions.contains(option);
            return ChoiceChip(
              label: Text(option),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              selected: isSelected,
              selectedColor: Colors.blue[700],
              backgroundColor: Colors.yellow.shade100,
              showCheckmark: false, // Hides the checkmark
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    selectedOptions.add(option);
                  } else {
                    selectedOptions.remove(option);
                  }
                });
              },
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
                  )
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 6. NEW: Added CircleAvatar like in the design ---
              const Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blueGrey,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                  // TODO: Add image upload functionality later
                ),
              ),
              const SizedBox(height: 16),
              // Name, Year, Branch, Address TextFields...
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter your name";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedYear,
                decoration: const InputDecoration(
                  labelText: "Year *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
                hint: const Text("Select your year"),
                isExpanded: true,
                items: _years.map((String year) {
                  return DropdownMenuItem<String>(
                    value: year,
                    child: Text(year),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedYear = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return "Please select your year";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedBranch,
                decoration: const InputDecoration(
                  labelText: "Branch *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_tree),
                ),
                hint: const Text("Select your branch"),
                isExpanded: true,
                items: _branches.map((String branch) {
                  return DropdownMenuItem<String>(
                    value: branch,
                    child: Text(branch),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedBranch = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return "Please select your branch";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: "Address (Optional)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
              ),
              const SizedBox(height: 24),
              Divider(color: Colors.white),

              // --- 7. NEW: Adding the chip sections to the UI ---
              _buildChipSection(
                title: "Clubs & Communities",
                allOptions: _allClubs,
                selectedOptions: _selectedClubs,
              ),
              const SizedBox(height: 16),
              // 1. REMOVED: Deleted the duplicate line "_buildChipSection("
              _buildChipSection(
                title: "Sports & Activities",
                allOptions: _allSports,
                selectedOptions: _selectedSports,
              ),

              const SizedBox(height: 40),
              MyButton(
                text: "Save Changes", // Updated text
                onTap: _saveProfile,
              ),
              const SizedBox(height: 16),
              if (_statusMessage.isNotEmpty)
                Center(
                  // 2. ADDED: Completed the rest of the file that was missing
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _statusMessage.startsWith("Error")
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

