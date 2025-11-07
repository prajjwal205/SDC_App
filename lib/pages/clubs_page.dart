import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// TODO: Consider adding icons specific to clubs if available

// Kept original class name as requested
class ClubsPage extends StatefulWidget {
  const ClubsPage({super.key});

  @override
  State<ClubsPage> createState() => _ClubsPageState();
}

// Kept original state class name
class _ClubsPageState extends State<ClubsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Structure: { ClubName: { Year: [ {name: '...', branch: '...', address: '...'}, ... ] } }
  Map<String, Map<String, List<Map<String, String>>>> _clubsData = {};
  List<String> _allClubsList = []; // To maintain order and list all clubs
  bool _isLoading = true;
  String? _selectedClub; // Track the currently selected club

  final List<String> _yearOrder = ["4th", "3rd", "2nd", "1st"];

  @override
  void initState() {
    super.initState();
    _fetchClubParticipants();
  }

  // Logic adapted from SportsDirectoryPage's fetch function
  Future<void> _fetchClubParticipants() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });

    try {
      final usersSnapshot = await _firestore.collection('users').get();

      Map<String, Map<String, List<Map<String, String>>>> tempClubsData = {};
      Set<String> uniqueClubs = {};

      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final String? name = userData['name'];
        final String? branch = userData['branch'];
        final String? year = userData['year'];
        final String? address = userData['address'];
        final List<dynamic>? selectedClubs = userData['selectedClubs']; // Fetch clubs

        if (name != null && branch != null && year != null && selectedClubs != null && selectedClubs.isNotEmpty) {
          final studentInfo = {
            'name': name,
            'branch': branch,
            'address': (address != null && address.isNotEmpty) ? address : 'No address provided',
          };

          for (var club in selectedClubs) {
            String clubName = club.toString();
            uniqueClubs.add(clubName);
            tempClubsData.putIfAbsent(clubName, () => {});
            tempClubsData[clubName]!.putIfAbsent(year, () => []);
            tempClubsData[clubName]![year]!.add(studentInfo);
          }
        }
      }

      List<String> sortedClubsList = uniqueClubs.toList()..sort();

      if (mounted) {
        setState(() {
          _clubsData = tempClubsData;
          _allClubsList = sortedClubsList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching club data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Replaced original placeholder body with the directory UI
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Clubs Directory"), // Updated title
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allClubsList.isEmpty
          ? const Center(child: Text("No club participation data found."))
          : Column(
        children: [
          _buildClubsGrid(),
          const Divider(height: 1),
          Expanded(
            child: _selectedClub == null
                ? const Center(
              child: Text(
                "Select a club above to see members.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            )
                : _buildParticipantDisplay(),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: Grid for Club Icons/Names (Adapted from Sports) ---
  Widget _buildClubsGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final boxSize = (screenWidth - 12) / 4; // 4 items per row, minus minimal spacing

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1.0, // perfect square
        ),
        itemCount: _allClubsList.length,
        itemBuilder: (context, index) {
          final clubName = _allClubsList[index];
          final isSelected = _selectedClub == clubName;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedClub = isSelected ? null : clubName;
              });
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: boxSize,
                  width: boxSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: isSelected ? Colors.blueGrey[700]! : Colors.grey[400]!,
                      width: isSelected ? 3 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.grey,
                        blurRadius: 2,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      _getClubImagePath(clubName),
                      fit: BoxFit.cover, // ✅ fills the box completely
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.sports,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    clubName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.blueGrey[800] : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  String _getClubImagePath(String clubName) {
    final lower = clubName.toLowerCase();

    // --- MAP CLUB NAMES TO YOUR IMAGE PATHS ---
    // IMPORTANT: Replace these example paths with your actual file paths
    // Ensure these files exist and the folder is declared in pubspec.yaml

    if (lower.contains('sdc')) return 'lib/assets/images/sdc.png'; // EXAMPLE
    if (lower.contains('iot')) return 'lib/assets/images/iot.jpg'; // EXAMPLE
    if (lower.contains('drone')) return 'lib/assets/images/drone_logo.png'; // EXAMPLE
    if (lower.contains('wdc')) return 'lib/assets/images/wdc_logo.png'; // EXAMPLE
    if (lower.contains('llc')) return 'lib/assets/images/llc_logo.png'; // EXAMPLE
    if (lower.contains('media club')) return 'lib/assets/images/media_logo.png'; // EXAMPLE
    if (lower.contains('ieee')) return 'lib/assets/images/ieee_logo.png'; // EXAMPLE
    if (lower.contains('mdac')) return 'lib/assets/images/mdac_logo.png'; // EXAMPLE
    if (lower.contains('vigyan club')) return 'lib/assets/images/vigyan_logo.png'; // EXAMPLE
    // Add more mappings for any other clubs

    // --- Fallback Image ---
    // Use a generic placeholder or your default icon if no specific logo is found
    return 'lib/assets/images/default_club.png'; // EXAMPLE Fallback
  }
  // --- WIDGET: Displays Participants for the Selected Club (Adapted from Sports) ---
  Widget _buildParticipantDisplay() {
    final participantsByYear = _clubsData[_selectedClub!];

    if (participantsByYear == null || participantsByYear.isEmpty) {
      return Center(child: Text("No members found for $_selectedClub."));
    }

    return ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            "Members of $_selectedClub",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey[900]),
          ),
          const SizedBox(height: 10),
          ..._buildParticipantList(participantsByYear), // Reuse participant list logic
        ]
    );
  }


  // Helper to generate the list of participants grouped by year (Same as Sports page)
  List<Widget> _buildParticipantList(Map<String, List<Map<String, String>>>? participantsByYear) {
    if (participantsByYear == null || participantsByYear.isEmpty) {
      return [const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text("No members found for this club."), // Updated text
      )];
    }

    List<Widget> yearWidgets = [];

    for (String year in _yearOrder) {
      if (participantsByYear.containsKey(year) && participantsByYear[year]!.isNotEmpty) {
        yearWidgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 10.0, bottom: 4.0),
              child: Text(
                "$year Year",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.blueGrey[800]),
              ),
            )
        );

        yearWidgets.addAll(participantsByYear[year]!.map((student) {
          String subtitleText = student['branch']!;
          if (student['address'] != 'No address provided') {
            subtitleText += " - ${student['address']}";
          }

          return ListTile(
            dense: true,
            leading: const Icon(Icons.person_outline, size: 20),
            title: Text(student['name']!),
            subtitle: Text(
              subtitleText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            visualDensity: VisualDensity.compact,
          );
        }).toList());
        yearWidgets.add(const Divider(height: 10));
      }
    }
    if (yearWidgets.isNotEmpty && yearWidgets.last is Divider) {
      yearWidgets.removeLast();
    }
    if (yearWidgets.isNotEmpty) {
      yearWidgets.add(const SizedBox(height: 20));
    }

    return yearWidgets;
  }
}
