import 'dart:io'; // Required for File operations
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart'; // File picking
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Firebase Storage
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p; // For getting file extension

class UploadResourcePage extends StatefulWidget {
  final String resourceType; // e.g., "CT Paper", "Resume", "Notes"

  const UploadResourcePage({super.key, required this.resourceType});

  @override
  State<UploadResourcePage> createState() => _UploadResourcePageState();
}

class _UploadResourcePageState extends State<UploadResourcePage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _titleController = TextEditingController();

  // Filter options (same as ProfilePage)
  final List<String> _years = ['1st', '2nd', '3rd', '4th'];
  final List<String> _branches = ['Common', 'IT', 'EE', 'ME']; // Added Common

  String? _selectedYear;
  String? _selectedBranch;

  // File picking state
  PlatformFile? _pickedFile; // Stores info about the picked file
  String? _pickedFilePath; // Stores the local path for upload
  String _fileStatus = "No file selected";

  // Loading and status
  bool _isLoading = false;
  String _statusMessage = "";

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _subjectController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    // Reset previous selection
    setState(() {
      _pickedFile = null;
      _pickedFilePath = null;
      _fileStatus = "Selecting file...";
    });

    try {
      // Pick file (allow PDF and common image types)
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _pickedFile = result.files.single;
          _pickedFilePath = result.files.single.path!;
          _fileStatus = "Selected: ${_pickedFile!.name}";
        });
      } else {
        // User canceled the picker
        setState(() {
          _fileStatus = "No file selected";
        });
      }
    } catch (e) {
      setState(() {
        _fileStatus = "Error picking file";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking file")),
      );
    }
  }

  Future<void> _uploadResource() async {
    // 1. Validate Form
    if (!_formKey.currentState!.validate()) {
      return; // Stop if form is invalid
    }
    if (_pickedFilePath == null || _pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a file to upload.")),
      );
      return; // Stop if no file is selected
    }

    // 2. Show Loading
    setState(() {
      _isLoading = true;
      _statusMessage = "Uploading file...";
    });
    FocusScope.of(context).unfocus(); // Hide keyboard

    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Error: Not logged in.";
      });
      return;
    }

    try {
      // 3. Upload to Firebase Storage
      final String fileName = _pickedFile!.name;
      // Create a unique path in Storage (e.g., resources/IT/3rd/ct_papers/os_paper.pdf)
      final String storagePath =
          'academic_resources/${_selectedBranch ?? 'common'}/${_selectedYear ?? 'all_years'}/${widget.resourceType.toLowerCase().replaceAll(' ', '_')}/$fileName';
      final storageRef = _storage.ref().child(storagePath);
      final uploadTask = storageRef.putFile(File(_pickedFilePath!));

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // 4. Prepare Data for Firestore
      final resourceData = {
        'resourceType': widget.resourceType,
        'year': _selectedYear,
        'branch': _selectedBranch,
        // Include subject or title based on resource type
        if (widget.resourceType == "CT Paper" || widget.resourceType == "Notes")
          'subject': _subjectController.text.trim(),
        if (widget.resourceType == "Resume")
          'title': _titleController.text.trim(),
        'downloadUrl': downloadUrl,
        'fileName': fileName,
        'uploadedByUid': user.uid,
        'uploadedAt': FieldValue.serverTimestamp(), // Use server time
        'status': 'approved', // Default status for admin approval
      };

      // 5. Save metadata to Firestore
      setState(() { _statusMessage = "Saving details..."; });
      await _firestore.collection('academic_resources').add(resourceData);

      // 6. Success Feedback and Navigation
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = "${widget.resourceType} submitted successfully for approval!";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_statusMessage),
            backgroundColor: Colors.green,
          ),
        );
        // Pop back after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = "Firebase Error: ${e.message}";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_statusMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = "An unexpected error occurred: ${e.toString()}";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_statusMessage), backgroundColor: Colors.red),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Upload ${widget.resourceType}"),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Submit a new ${widget.resourceType}",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Your submission will be reviewed by an admin.",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              // --- File Picker ---
              OutlinedButton.icon(
                icon: const Icon(Icons.attach_file),
                label: const Text("Select File (PDF, JPG, PNG)"),
                onPressed: _pickFile,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 8),
              Center(child: Text(_fileStatus, style: TextStyle(color: Colors.grey[700]))),
              const SizedBox(height: 20),


              // --- Year (Mandatory) ---
              DropdownButtonFormField<String>(
                value: _selectedYear,
                decoration: const InputDecoration(
                  labelText: "Year *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
                hint: const Text("Select year"),
                isExpanded: true,
                items: _years.map((String year) {
                  return DropdownMenuItem<String>(value: year, child: Text(year));
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedYear = newValue;
                    // Auto-select 'Common' branch if 1st year
                    if (newValue == '1st') {
                      _selectedBranch = 'Common';
                    }
                    // If changing away from 1st yr and branch was Common, clear branch
                    else if (_selectedBranch == 'Common') {
                      _selectedBranch = null;
                    }
                  });
                },
                validator: (value) => value == null ? "Please select year" : null,
              ),
              const SizedBox(height: 20),

              // --- Branch (Mandatory) ---
              DropdownButtonFormField<String>(
                value: _selectedBranch,
                decoration: const InputDecoration(
                  labelText: "Branch *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_tree),
                ),
                hint: const Text("Select branch"),
                // Disable if 1st year is selected
                disabledHint: _selectedYear == '1st' ? const Text("Common (1st Yr)") : null,
                isExpanded: true,
                items: _branches.map((String branch) {
                  return DropdownMenuItem<String>(value: branch, child: Text(branch));
                }).toList(),
                // Disable if 1st year is selected
                onChanged: _selectedYear == '1st' ? null : (newValue) {
                  setState(() {
                    _selectedBranch = newValue;
                  });
                },
                validator: (value) => value == null ? "Please select branch" : null,
              ),
              const SizedBox(height: 20),

              // --- Subject (Conditional: CT Paper / Notes) ---
              if (widget.resourceType == "CT Paper" || widget.resourceType == "Notes")
                TextFormField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: "Subject *",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.subject),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter the subject";
                    }
                    return null;
                  },
                ),

              // --- Title (Conditional: Resume) ---
              if (widget.resourceType == "Resume")
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: "Title * (e.g., SWE Resume)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter a title";
                    }
                    return null;
                  },
                ),

              const SizedBox(height: 40),

              // --- Submit Button ---
              ElevatedButton(
                // Disable button while loading
                onPressed: _isLoading ? null : _uploadResource,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueGrey[800],
                  foregroundColor: Colors.white,
                  textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text("Submit for Approval"),
              ),
              const SizedBox(height: 16),

              // --- Status Message ---
              if (_statusMessage.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _statusMessage.startsWith("Error")
                            ? Colors.red
                            : Colors.green,
                      ),
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

// **How to Use:**
//
// 1.  Save this code as `lib/pages/upload_resource_page.dart`.
// 2.  Go back to your `lib/pages/academic_resources_page.dart`.
// 3.  **Uncomment** the import for `upload_resource_page.dart` at the top.
// 4.  Find the `_navigateToUploadPage` function and **uncomment** the `Navigator.push` line, making sure it passes the `resourceType` correctly:
// ```dart

void _navigateToUploadPage(String resourceType) {
  Navigator.of(p.context as BuildContext).push(
    MaterialPageRoute(
      builder: (context) => UploadResourcePage(resourceType: resourceType),
    ),
  );
  ScaffoldMessenger.of(p.context as BuildContext).showSnackBar( // Remove this line
         SnackBar(content: Text("Upload page for $resourceType coming soon!")));
}

