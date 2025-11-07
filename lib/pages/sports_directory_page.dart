import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// TODO: If using SVG, add flutter_svg package: import 'package:flutter_svg/flutter_svg.dart';

class SportsDirectoryPage extends StatefulWidget {
  const SportsDirectoryPage({super.key});

  @override
  State<SportsDirectoryPage> createState() => _SportsDirectoryPageState();
}

class _SportsDirectoryPageState extends State<SportsDirectoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Structure: { SportName: { Year: [ {name: '...', branch: '...', address: '...'}, ... ] } }
  Map<String, Map<String, List<Map<String, String>>>> _sportsData = {};
  List<String> _allSportsList = []; // To maintain order and list all sports
  bool _isLoading = true;
  String? _selectedSport; // NEW: Track the currently selected sport

  final List<String> _yearOrder = ["4th", "3rd", "2nd", "1st"];

  @override
  void initState() {
    super.initState();
    _fetchSportsParticipants();
  }

  Future<void> _fetchSportsParticipants() async {
    // ... (Your existing fetch logic - no changes needed) ...
    if (!mounted) return;
    setState(() { _isLoading = true; });
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      Map<String, Map<String, List<Map<String, String>>>> tempSportsData = {};
      Set<String> uniqueSports = {};
      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final String? name = userData['name'];
        final String? branch = userData['branch'];
        final String? year = userData['year'];
        final String? address = userData['address'];
        final List<dynamic>? selectedSports = userData['selectedSports'];
        if (name != null && branch != null && year != null && selectedSports != null && selectedSports.isNotEmpty) {
          final studentInfo = {
            'name': name,
            'branch': branch,
            'address': (address != null && address.isNotEmpty) ? address : 'No address provided',
          };
          for (var sport in selectedSports) {
            String sportName = sport.toString();
            uniqueSports.add(sportName);
            tempSportsData.putIfAbsent(sportName, () => {});
            tempSportsData[sportName]!.putIfAbsent(year, () => []);
            tempSportsData[sportName]![year]!.add(studentInfo);
          }
        }
      }
      List<String> sortedSportsList = uniqueSports.toList()..sort();
      if (mounted) {
        setState(() {
          _sportsData = tempSportsData;
          _allSportsList = sortedSportsList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching sports data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (Your existing build method - no changes needed) ...
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Sports Directory"),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allSportsList.isEmpty
          ? const Center(child: Text("No sports participation data found."))
          : Column(
        children: [
          _buildSportsGrid(),
          const Divider(height: 1), // Separator
          Expanded(
            child: _selectedSport == null
                ? const Center(
              child: Text(
                "Select a sport above to see participants.",
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

  Widget _buildSportsGrid() {
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
        itemCount: _allSportsList.length,
        itemBuilder: (context, index) {
          final sportName = _allSportsList[index];
          final isSelected = _selectedSport == sportName;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedSport = isSelected ? null : sportName;
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
                      _getSportImagePath(sportName),
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
                    sportName,
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


  String _getSportImagePath(String sportName) {
    final lower = sportName.toLowerCase();

    if (lower.contains('cricket')) return 'lib/assets/images/cricket.jpg';
    if (lower.contains('football') || lower.contains('soccer')) return 'lib/assets/images/football.jpg';
    if (lower.contains('basketball')) return 'lib/assets/images/basketball.png';
    if (lower.contains('volleyball')) return 'lib/assets/images/volleyball.jpg';
    if (lower.contains('badminton')) return 'lib/assets/images/badminton.jpg';
    if (lower.contains('chess')) return 'lib/assets/images/Chess.jpg';
    if (lower.contains('carrom')) return 'lib/assets/images/carrom.png';
    if (lower.contains('tt') || lower.contains('table tennis')) return 'lib/assets/images/tt.jpg';
    if (lower.contains('athletics')) return 'lib/assets/images/athletics.jpg';

    return 'lib/assets/images/google1.png';
  }


  Widget _buildParticipantDisplay() {
    // ... (Your existing participant display - no changes needed) ...
    final participantsByYear = _sportsData[_selectedSport!];

    if (participantsByYear == null || participantsByYear.isEmpty) {
      return Center(child: Text("No participants found for $_selectedSport."));
    }

    return ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            " $_selectedSport members",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey[900]),
          ),
          const SizedBox(height: 10),
          ..._buildParticipantList(participantsByYear),
        ]
    );
  }


  List<Widget> _buildParticipantList(Map<String, List<Map<String, String>>>? participantsByYear) {
    // ... (Your existing participant list builder - no changes needed) ...
    if (participantsByYear == null || participantsByYear.isEmpty) {
      return [const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text("No participants found for this sport."),
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

