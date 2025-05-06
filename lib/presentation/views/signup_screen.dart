import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/api_config.dart';
import 'home_screen.dart';
import './widgets/password_strength_indicator.dart';
import 'login_screen.dart';
import 'package:http/http.dart' as http;

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  File? _idCardImage;
  File? _driverLicenseImage;
  String? _errorMessage;
  int _currentStep = 0;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<File> compressImage(File file) async {
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image != null) {
      img.Image resized = img.copyResize(image, width: 800);
      final compressedBytes = img.encodeJpg(resized, quality: 70);
      final compressedFile = File(file.path)..writeAsBytesSync(compressedBytes);
      return compressedFile;
    } else {
      return file;
    }
  }

  Future<void> _pickImage(bool isIdCard) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
      maxWidth: 800,
    );

    if (pickedFile != null) {
      setState(() {
        if (isIdCard) {
          _idCardImage = File(pickedFile.path);
        } else {
          _driverLicenseImage = File(pickedFile.path);
        }
      });
    }
  }

  void _signUpWithEmailAndPassword() async {
    if (_formKey.currentState!.validate() &&
        _idCardImage != null &&
        _driverLicenseImage != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        const String baseUrl = "$userEndpoint/signup";
        var uri = Uri.parse(baseUrl);

        File compressedIdCard = await compressImage(_idCardImage!);
        File compressedDriverLicense =
            await compressImage(_driverLicenseImage!);

        var request = http.MultipartRequest('POST', uri);

        request.fields['fullName'] =
            _fullNameController.text.trim(); // ✅ correct
        request.fields['email'] = _emailController.text.trim();
        request.fields['num_phone'] = _phoneNumberController.text.trim();
        request.fields['password'] = _passwordController.text.trim();

        request.files.add(
            await http.MultipartFile.fromPath("cin", compressedIdCard.path));
        request.files.add(await http.MultipartFile.fromPath(
            "permis", compressedDriverLicense.path));

        var streamedResponse =
            await request.send().timeout(Duration(seconds: 60));
        var responseData = await streamedResponse.stream.bytesToString();

        if (streamedResponse.statusCode == 201) {
          var data = jsonDecode(responseData);

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString("userId", data["user"]["_id"]);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Signup Successful! Please Login.")),
          );
        } else {
          var errorData = jsonDecode(responseData);
          setState(() {
            _errorMessage = errorData["message"] ?? "Signup failed. Try again.";
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = "Server connection failed. Check your network.";
        });
      }

      setState(() {
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage =
            "All fields, including CIN & Permis images, are required!";
      });
    }
  }

  String _getPasswordStrength(String password) {
    if (password.length < 6) return "Weak";
    if (password.length < 10) return "Medium";
    return "Strong";
  }

  Color _getPasswordStrengthColor(String strength) {
    switch (strength) {
      case "Weak":
        return Colors.red;
      case "Medium":
        return Colors.orange;
      case "Strong":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF007AFF), Color(0xFF00CCFF)],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 30),
                      FadeInDown(
                        duration: Duration(milliseconds: 1000),
                        child: Text(
                          "Create Account",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 10),
                      FadeInDown(
                        duration: Duration(milliseconds: 1200),
                        child: Text(
                          "Sign up to get started",
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 18),
                        ),
                      ),
                      SizedBox(height: 40),
                      Expanded(
                        child: FadeInUp(
                          duration: Duration(milliseconds: 1400),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      _buildStepper(),
                                      SizedBox(height: 20),
                                      if (_currentStep == 0) ...[
                                        _buildTextField(_fullNameController,
                                            "Full Name", Icons.person),
                                        SizedBox(height: 20),
                                        _buildTextField(_emailController,
                                            "Email", Icons.email),
                                        SizedBox(height: 20),
                                        _buildTextField(_phoneNumberController,
                                            "Phone Number", Icons.phone,
                                            isNumber: true),
                                        SizedBox(height: 20),
                                        _buildTextField(_passwordController,
                                            "Password", Icons.lock,
                                            isPassword: true),
                                        SizedBox(height: 10),
                                        _buildPasswordStrengthIndicator(),
                                        SizedBox(height: 20),
                                        _buildTextField(
                                            _confirmPasswordController,
                                            "Confirm Password",
                                            Icons.lock,
                                            isPassword: true),
                                      ],
                                      if (_currentStep == 1) ...[
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildImagePicker(
                                                label: "ID Card",
                                                imageFile: _idCardImage,
                                                onTap: () => _pickImage(true),
                                                icon: Icons.credit_card,
                                              ),
                                            ),
                                            SizedBox(width: 20),
                                            Expanded(
                                              child: _buildImagePicker(
                                                label: "Driver's License",
                                                imageFile: _driverLicenseImage,
                                                onTap: () => _pickImage(false),
                                                icon: Icons.drive_eta,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (_errorMessage != null)
                                        Padding(
                                          padding: EdgeInsets.only(top: 20),
                                          child: Text(
                                            _errorMessage!,
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      SizedBox(height: 30),
                                      _buildActionButton(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Center(
                        child: FadeInUp(
                          duration: Duration(milliseconds: 1800),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LoginScreen()),
                              );
                            },
                            child: Text(
                              "Already have an account? Login",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Row(
      children: [
        _buildStepCircle(0, "Account"),
        Expanded(child: Container(height: 2, color: Colors.grey.shade300)),
        _buildStepCircle(1, "Verification"),
      ],
    );
  }

  Widget _buildStepCircle(int step, String label) {
    bool isActive = _currentStep >= step;
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: isActive ? Color(0xFF007AFF) : Colors.grey.shade300,
          child: Text(
            "${step + 1}",
            style: TextStyle(color: isActive ? Colors.white : Colors.grey),
          ),
        ),
        SizedBox(height: 5),
        Text(label,
            style:
                TextStyle(color: isActive ? Color(0xFF007AFF) : Colors.grey)),
      ],
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hint, IconData icon,
      {bool isPassword = false, bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Color(0xFF007AFF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF007AFF)),
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'This field is required';
        if (hint == "Email" && !value.contains('@'))
          return 'Please enter a valid email';
        if (hint == "Phone Number" && value.length < 8)
          return 'Please enter a valid phone number';
        if (hint == "Password" && value.length < 6)
          return 'Password must be at least 6 characters';
        if (hint == "Full Name" && value.trim().isEmpty)
          return 'Please enter your full name';
        return null;
      },
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    String strength = _getPasswordStrength(_passwordController.text);
    return Row(
      children: [
        Text("Password Strength: ", style: TextStyle(color: Colors.grey)),
        Text(
          strength,
          style: TextStyle(
            color: _getPasswordStrengthColor(strength),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker({
    required String label,
    required File? imageFile,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Color(0xFF007AFF), width: 2),
        ),
        child: imageFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 50, color: Color(0xFF007AFF)),
                  SizedBox(height: 10),
                  Text(label,
                      style: TextStyle(
                          color: Color(0xFF007AFF),
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text("Tap to upload", style: TextStyle(color: Colors.grey)),
                ],
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.file(
                      imageFile,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildActionButton() {
    return ElevatedButton(
      onPressed: _isLoading
          ? null
          : (_currentStep == 0 ? _nextStep : _signUpWithEmailAndPassword),
      child: _isLoading
          ? CircularProgressIndicator(color: Colors.white)
          : Text(_currentStep == 0 ? "Next" : "Sign Up",
              style: TextStyle(fontSize: 18)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF007AFF),
        padding: EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        minimumSize: Size(double.infinity, 50),
      ),
    );
  }

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _currentStep = 1;
      });
    }
  }
}
