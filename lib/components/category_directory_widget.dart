import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CategoryDirectoryWidget extends StatefulWidget {
  final String title;
  final String firestoreField; // e.g., 'selectedSports' or 'selectedClubs'
  final String imageType; // e.g., 'sports' or 'clubs'
  final String Function(String) getImagePath; // Custom image resolver

  const CategoryDirectoryWidget({
    super.key,
    required this.title,
    required this.firestoreField,
    required this.imageType,
    required this.getImagePath,
  });

  @override
  State<CategoryDirectoryWidget> createState() => _CategoryDirectoryWidgetState();
}

class _CategoryDirectoryWidgetState extends State<CategoryDirectoryWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, Map<String, List<Map<String, String>>>> _data = {};
  List<String> _categories = [];
  bool _isLoading = true;
  String? _selectedCategory;

  final List<String> _yearOrder = ["4th", "3rd", "2nd", "1st"];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final snapshot = await _firestore.collection('users').get();
      Map<String, Map<String, List<Map<String, String>>>> tempData = {};
      Set<String> uniqueCategories = {};

      for (var userDoc in snapshot.docs) {
        final userData = userDoc.data();
        final String? name = userData['name'];
        final String? branch = userData['branch'];
        final String? year = userData['year'];
        final String? address = userData['address'];
        final List<dynamic>? selectedItems = userData[widget.firestoreField];

        if (name != null &&
            branch != null &&
            year != null &&
            selectedItems != null &&
            selectedItems.isNotEmpty) {
          final studentInfo = {
            'name': name,
            'branch': branch,
            'address': (address != null && address.isNotEmpty)
                ? address
                : 'No address provided',
          };

          for (var item in selectedItems) {
            String categoryName = item.toString();
            uniqueCategories.add(categoryName);
            tempData.putIfAbsent(categoryName, () => {});
            tempData[categoryName]!.putIfAbsent(year, () => []);
            tempData[categoryName]![year]!.add(studentInfo);
          }
        }
      }

      List<String> sortedList = uniqueCategories.toList()..sort();

      if (mounted) {
        setState(() {
          _data = tempData;
          _categories = sortedList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading ${widget.title} data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          ? Center(child: Text("No ${widget.imageType} data found."))
          : Column(
        children: [
          _buildCategoryGrid(),
          const Divider(height: 1),
          Expanded(
            child: _selectedCategory == null
                ? Center(
              child: Text(
                "Select a ${widget.imageType} above to see members.",
                style: const TextStyle(
                    color: Colors.grey, fontSize: 16),
              ),
            )
                : _buildParticipantDisplay(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final boxSize = (screenWidth - 12) / 4;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1.0,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final categoryName = _categories[index];
          final isSelected = _selectedCategory == categoryName;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = isSelected ? null : categoryName;
              });
            },
            child: Column(
              children: [
                Container(
                  height: boxSize,
                  width: boxSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: isSelected
                          ? Colors.blueGrey[700]!
                          : Colors.grey[400]!,
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
                      widget.getImagePath(categoryName),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.groups, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    categoryName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.blueGrey[800]
                          : Colors.black87,
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

  Widget _buildParticipantDisplay() {
    final participantsByYear = _data[_selectedCategory!];
    if (participantsByYear == null || participantsByYear.isEmpty) {
      return Center(
          child: Text("No members found for $_selectedCategory."));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          "Members of $_selectedCategory",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[900],
          ),
        ),
        const SizedBox(height: 10),
        ..._buildParticipantList(participantsByYear),
      ],
    );
  }

  List<Widget> _buildParticipantList(
      Map<String, List<Map<String, String>>>? participantsByYear) {
    List<Widget> yearWidgets = [];

    for (String year in _yearOrder) {
      if (participantsByYear?.containsKey(year) ?? false) {
        final participants = participantsByYear![year]!;
        if (participants.isEmpty) continue;

        yearWidgets.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text(
            "$year Year",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey[800],
            ),
          ),
        ));

        yearWidgets.addAll(participants.map((student) {
          String subtitle = student['branch']!;
          if (student['address'] != 'No address provided') {
            subtitle += " - ${student['address']}";
          }

          return ListTile(
            dense: true,
            leading: const Icon(Icons.person_outline, size: 20),
            title: Text(student['name']!),
            subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
            visualDensity: VisualDensity.compact,
          );
        }));
        yearWidgets.add(const Divider(height: 10));
      }
    }

    if (yearWidgets.isNotEmpty && yearWidgets.last is Divider) {
      yearWidgets.removeLast();
    }

    return yearWidgets;
  }
}
