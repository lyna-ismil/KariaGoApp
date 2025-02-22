import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // User data
  File? _profileImage;
  final TextEditingController _fullNameController =
      TextEditingController(text: "John Doe");
  final TextEditingController _emailController =
      TextEditingController(text: "johndoe@example.com");
  final TextEditingController _phoneController =
      TextEditingController(text: "+1234567890");

  bool _isVerified = true; // Change this based on actual user data
  bool _isLoading = false; // Tracks loading state when saving profile
  String? _errorMessage; // Stores error messages when saving profile
  // Pick Image Function
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  // Save Profile Changes
  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? userId = prefs.getString("userId");

        if (userId == null) {
          setState(() {
            _errorMessage = "User ID not found. Please log in again.";
            _isLoading = false;
          });
          return;
        }

        // Use correct backend URL
        const String baseUrl = "http://10.0.2.2:5000/api/users";

        var uri = Uri.parse("$baseUrl/$userId");

        var request = http.MultipartRequest('PUT', uri);
        request.fields['fullName'] = _fullNameController.text.trim();
        request.fields['num_phone'] = _phoneController.text.trim();

        //  If a new profile image is selected, attach it
        if (_profileImage != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'profile_picture',
            _profileImage!.path,
          ));
        }

        var response = await request.send();
        var responseData = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          var data = jsonDecode(responseData);

          setState(() {
            _fullNameController.text = data["user"]["fullName"];
            _phoneController.text = data["user"]["num_phone"];
            if (data["user"]["profile_picture"] != null) {
              _profileImage = File(
                  data["user"]["profile_picture"]); // Update profile image path
            }
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Profile Updated Successfully! ✅")));
        } else {
          setState(() {
            _errorMessage = "Profile update failed. Please try again.";
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = "Server connection failed. Check your network.";
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
        title: Text("My Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E88E5), Color(0xFF64B5F6)],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildProfilePicture(),
                        SizedBox(height: 20),
                        _buildVerificationBadge(),
                        SizedBox(height: 30),
                        Expanded(child: _buildInfoCard()),
                      ],
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

  // Profile Picture Widget
  Widget _buildProfilePicture() {
    return Hero(
      tag: 'profilePicture',
      child: GestureDetector(
        onTap: _showImageSourceDialog,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 70,
                backgroundColor: Colors.grey[300],
                backgroundImage:
                    _profileImage != null ? FileImage(_profileImage!) : null,
                child: _profileImage == null
                    ? Icon(Icons.person, size: 65, color: Colors.grey[700])
                    : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Verification Badge Widget
  Widget _buildVerificationBadge() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isVerified ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isVerified ? Icons.verified : Icons.error_outline,
            color: Colors.white,
            size: 18,
          ),
          SizedBox(width: 5),
          Text(
            _isVerified ? "Verified" : "Not Verified",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Information Card Widget
  Widget _buildInfoCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField(Icons.person, "Full Name", _fullNameController,
                "Enter your full name"),
            SizedBox(height: 20),
            _buildTextField(
                Icons.email, "Email", _emailController, "Enter your email",
                readOnly: true),
            SizedBox(height: 20),
            _buildTextField(Icons.phone, "Phone Number", _phoneController,
                "Enter your phone number"),
            Spacer(),
            _buildSaveButton(),
            SizedBox(height: 20),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  // Custom Text Field Widget
  Widget _buildTextField(IconData icon, String label,
      TextEditingController controller, String hint,
      {bool readOnly = false}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      validator: (value) => value!.isEmpty ? "$label is required" : null,
    );
  }

  // Save Button Widget
  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed:
          _isLoading ? null : _saveProfile, // ✅ Disable button when loading
      child: _isLoading
          ? CircularProgressIndicator(color: Colors.white) // ✅ Show loader
          : Text("Save Changes", style: TextStyle(fontSize: 18)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  // Logout Button Widget
  Widget _buildLogoutButton() {
    return TextButton(
      onPressed: () {
        // Implement logout functionality
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Logout"),
              content: Text("Are you sure you want to logout?"),
              actions: [
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text("Logout"),
                  onPressed: () {
                    // Implement logout logic here
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
      child: Text("Logout", style: TextStyle(color: Colors.red, fontSize: 16)),
    );
  }

  // Function to show image picker options
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera, color: Colors.blue[700]),
                title: Text("Take Photo"),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.blue[700]),
                title: Text("Choose from Gallery"),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
