import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // For opening links
// Note: upload_resource_page.dart is NOT imported here by students

class AcademicResourcesPage extends StatefulWidget {
  const AcademicResourcesPage({super.key});

  @override
  State<AcademicResourcesPage> createState() => _AcademicResourcesPageState();
}

class _AcademicResourcesPageState extends State<AcademicResourcesPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State for filters
  String? _userYear;
  String? _userBranch;
  String? _selectedYear;
  String? _selectedBranch;

  final List<String> _years = ['1st', '2nd', '3rd', '4th'];
  final List<String> _branches = ['Common', 'IT', 'EE', 'ME'];

  // State for Tabs
  late TabController _tabController;
  final List<String> _resourceTypes = ["CT Paper", "Resume", "Notes"];

  // State for data
  bool _isLoadingProfile = true;
  bool _isLoadingResources = false;
  List<Map<String, dynamic>> _resources = [];

  // Note: _isAdmin check is not needed here if upload button is fully removed

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _resourceTypes.length, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _fetchUserDataAndInitialResources();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  // When tab changes, re-fetch resources
  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      if (!_isLoadingProfile) {
        _fetchResources();
      }
    }
  }

  // Fetch user's profile to set the default filters
  Future<void> _fetchUserDataAndInitialResources() async {
    setState(() { _isLoadingProfile = true; });
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error: User not logged in.")));
      }
      setState(() { _isLoadingProfile = false; });
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        _userYear = data.containsKey('year') ? data['year'] : null;
        _userBranch = data.containsKey('branch') ? data['branch'] : null;

        // Set initial filters based on user's profile
        _selectedYear = _userYear;
        if (_selectedYear == '1st') {
          _selectedBranch = 'Common';
        } else {
          _selectedBranch = _userBranch;
        }
        // Validate filters against our lists
        if (!_years.contains(_selectedYear)) _selectedYear = null;
        if (!_branches.contains(_selectedBranch)) _selectedBranch = null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error fetching profile: ${e.toString()}")));
      }
    }
    if (mounted) {
      setState(() { _isLoadingProfile = false; });
    }
    // Now fetch resources based on the default filters
    _fetchResources();
  }

  // Fetch resources from Firestore based on current filters and tab
  Future<void> _fetchResources() async {
    if (_selectedYear == null || _selectedBranch == null) return;

    setState(() {
      _isLoadingResources = true;
      _resources = [];
    });

    try {
      final snapshot = await _firestore
          .collection('CT_papers')
          .where('year', isEqualTo: _selectedYear)
          .where('branch', isEqualTo: _selectedBranch)
          .where('resourceType', isEqualTo: _resourceTypes[_tabController.index])
          .orderBy('uploadedAt', descending: true)
          .get();

      setState(() {
        _resources = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        _isLoadingResources = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingResources = false;
      });
      if (kDebugMode) {
        print("Error fetching resources: $e");
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Error fetching resources.")));
    }
  }

  IconData _getIconForResourceType(String type) {
    switch (type) {
      case "CT Paper": return Icons.description_outlined;
      case "Resume": return Icons.article_outlined;
      case "Notes": return Icons.note_alt_outlined;
      default: return Icons.insert_drive_file_outlined;
    }
  }

  // Function to open the Google Drive link
  Future<void> _launchURL(String? urlString) async {
    if (urlString == null || urlString.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Link is invalid or missing.")));
      }
      return;
    }
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        if (kDebugMode) {
          print("Error launching URL: ${e.toString()}");
        } // For your debug
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Could not open link.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Academic Resources"),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[400],
          indicatorColor: Colors.yellow,
          tabs: _resourceTypes.map((type) => Tab(text: type)).toList(),
        ),
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // The Filter UI
          _buildFilterSection(),
          // The list of results
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _resourceTypes.map((type) {
                return _buildResourceList(type);
              }).toList(),
            ),
          ),
        ],
      ),
      // No FloatingActionButton - Students cannot upload
    );
  }

  // The Filter UI Widget
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      color: Colors.grey[200],
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedYear,
              decoration: InputDecoration(
                labelText: "Year",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: Colors.white,
              ),
              hint: const Text("Select Year"),
              items: _years.map((String year) {
                return DropdownMenuItem<String>(value: year, child: Text(year));
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedYear = newValue;
                  if (newValue == '1st') {
                    _selectedBranch = 'Common';
                  } else if (_selectedBranch == 'Common') {
                    _selectedBranch = _userBranch; // Revert to user's branch
                    if (!_branches.contains(_selectedBranch)) _selectedBranch = null;
                  }
                });
                _fetchResources(); // Re-fetch when filter changes
              },
              validator: (value) => value == null ? 'Required' : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedBranch,
              decoration: InputDecoration(
                labelText: "Branch",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: Colors.white,
              ),
              hint: const Text("Select Branch"),
              disabledHint: _selectedYear == '1st' ? const Text("Common (1st Yr)") : null,
              items: _branches.map((String branch) {
                return DropdownMenuItem<String>(value: branch, child: Text(branch));
              }).toList(),
              onChanged: _selectedYear == '1st' ? null : (newValue) {
                setState(() {
                  _selectedBranch = newValue;
                });
                _fetchResources();
              },
              validator: (value) => value == null ? 'Required' : null,
            ),
          ),
        ],
      ),
    );
  }

  // The List of Results Widget
  Widget _buildResourceList(String resourceType) {
    if (_isLoadingResources) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_selectedYear == null || _selectedBranch == null) {
      return const Center(child: Text("Please select Year and Branch to see resources."));
    }
    if (_resources.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            "No ${_resourceTypes[_tabController.index]}s found for $_selectedYear Year $_selectedBranch.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    // Group resources by subject (or 'title' for resumes)
    Map<String, List<Map<String, dynamic>>> groupedResources = {};

    if (resourceType == "Resume") {
      // Resumes aren't grouped by subject, so we'll list them all under one header
      groupedResources["All Resumes"] = _resources;
    } else {
      // Group CT Papers and Notes by their 'subject' field
      for (var resource in _resources) {
        String subject = resource['subject'] ?? resource['title'] ?? 'Other';
        groupedResources.putIfAbsent(subject, () => []).add(resource);
      }
    }

    List<String> subjects = groupedResources.keys.toList()..sort();

    return ListView.builder(
      itemCount: subjects.length,
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, index) {
        String subject = subjects[index];
        List<Map<String, dynamic>> items = groupedResources[subject]!;

        // Use ExpansionTile for each subject group
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            title: Text(
                subject, // e.g., "Operating Systems" or "All Resumes"
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)
            ),
            subtitle: Text("${items.length} item(s)"),
            leading: Icon(
                resourceType == "Resume"
                    ? Icons.article_outlined
                    : Icons.subject_outlined, // Subject icon for papers/notes
                color: Colors.blueGrey[700]
            ),
            initiallyExpanded: resourceType == "Resume", // Auto-expand resume list
            childrenPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            children: items.map((resource) {
              // This is the individual link
              final title = resource['subject'] ?? resource['title'] ?? resource['fileName'] ?? 'Untitled';
              final type = resource['resourceType'] ?? 'File';
              final url = resource['downloadUrl'];
              final subtitle = (resourceType != "Resume" && subject == title)
                  ? "File: ${resource['fileName'] ?? 'Google Drive Link'}"
                  : "Type: $type";

              return Tooltip(
                message: 'Click toopen',
                child: ListTile(
                  leading: Icon(_getIconForResourceType(type), color: Colors.blueGrey[700]),
                  title: Text(
                    // Show the 'fileName' for papers/notes, but 'title' for resumes
                      resourceType == "Resume" ? title : (resource['fileName'] ?? title),
                      style: const TextStyle(fontWeight: FontWeight.w500)
                  ),
                  subtitle: Text(subtitle),
                  trailing: Icon(Icons.open_in_new, color: Colors.green[700]),
                  onTap: () {
                    _launchURL(url); // Open the Google Drive link
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

