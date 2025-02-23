import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kariago/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ReclamationScreen extends StatefulWidget {
  @override
  _ReclamationScreenState createState() => _ReclamationScreenState();
}

class _ReclamationScreenState extends State<ReclamationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _image;
  bool _isLoading = false; // Tracks loading state
  String? _errorMessage; //  Stores error messages

  // Select an image
  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Submit Reclamation
  void _submitReclamation() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? userId = prefs.getString("userId"); //  Get logged-in user ID

        if (userId == null) {
          setState(() {
            _errorMessage = "User ID not found. Please log in again.";
            _isLoading = false;
          });
          return;
        }

        final response = await ApiService.submitReclamation(
          userId,
          _titleController.text.trim(),
          _descriptionController.text.trim(),
          _image, //  Send image if available
        );

        print(" Reclamation Submitted: $response");

        setState(() {
          _isLoading = false;
          _titleController.clear();
          _descriptionController.clear();
          _image = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Reclamation Submitted Successfully! ✅")));
      } catch (e) {
        print(" Reclamation Submission Failed: $e");
        setState(() {
          _errorMessage = "Failed to submit reclamation. Try again.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Submit Reclamation"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade800, Colors.blue.shade200],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    AppBar().preferredSize.height -
                    MediaQuery.of(context).padding.top,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildReclamationCard()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReclamationCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Reclamation Details",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 20),
            _buildTextField(
              Icons.title,
              "Title",
              _titleController,
              "Enter reclamation title",
            ),
            SizedBox(height: 20),
            _buildTextField(
              Icons.description,
              "Description",
              _descriptionController,
              "Describe your issue",
              maxLines: 4,
            ),
            SizedBox(height: 20),
            _buildImageAttachment(),
            SizedBox(height: 30),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(IconData icon, String label,
      TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue.shade800),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade800, width: 2),
        ),
      ),
      validator: (value) => value!.isEmpty ? "$label is required" : null,
    );
  }

  Widget _buildImageAttachment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Attach an Image (Optional)",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        SizedBox(height: 10),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade800),
            ),
            child: _image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_image!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: 50, color: Colors.blue.shade800),
                      SizedBox(height: 10),
                      Text(
                        "Tap to add an image",
                        style: TextStyle(color: Colors.blue.shade800),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submitReclamation,
      child: Text("Submit Reclamation", style: TextStyle(fontSize: 18)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}
