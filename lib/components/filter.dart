import 'package:flutter/material.dart';

class Filter extends StatelessWidget {
  final String? selectedYear;
  final String? selectedBranch;
  final List<String> years;
  final List<String> branches;
  final ValueChanged<String?> onYearChanged;
  // Use ValueChanged<String?>? for onChanged to allow null (for disabled)
  final ValueChanged<String?>? onBranchChanged;
  final String? disabledHint; // For 'Common (1st Yr)' text

  const Filter({
    super.key,
    required this.selectedYear,
    required this.selectedBranch,
    required this.years,
    required this.branches,
    required this.onYearChanged,
    required this.onBranchChanged,
    this.disabledHint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      color: Colors.grey[200],
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedYear,
              decoration: InputDecoration(
                labelText: "Year",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: Colors.white,
              ),
              hint: const Text("Select Year"),
              items: years.map((String year) {
                return DropdownMenuItem<String>(value: year, child: Text(year));
              }).toList(),
              onChanged: onYearChanged, // Use the callback from parent
              validator: (value) => value == null ? 'Required' : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedBranch,
              decoration: InputDecoration(
                labelText: "Branch",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: Colors.white,
              ),
              hint: const Text("Select Branch"),
              disabledHint: disabledHint != null ? Text(disabledHint!) : null,
              items: branches.map((String branch) {
                return DropdownMenuItem<String>(value: branch, child: Text(branch));
              }).toList(),
              // Disable changing branch if 1st year is selected (logic passed via onChanged)
              onChanged: onBranchChanged,
              validator: (value) => value == null ? 'Required' : null,
            ),
          ),
        ],
      ),
    );
  }
}

