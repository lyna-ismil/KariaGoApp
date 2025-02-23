import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // ✅ For saving token

class ApiService {
  static const String baseUrl =
      "http://10.0.2.2:5000/api"; // ✅ Fix localhost issue

  // ✅ Get Auth Token
  static Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("token"); // Retrieve saved JWT token
  }

  // ✅ User Signup
  static Future<Map<String, dynamic>> signupUser(String cin, String permis,
      String numPhone, String email, String password) async {
    final url = Uri.parse('$baseUrl/users/signup');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "cin": cin,
        "permis": permis,
        "num_phone": numPhone,
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Signup Failed: ${response.body}");
    }
  }

  // ✅ User Login (Save Token)
  static Future<Map<String, dynamic>> loginUser(
      String email, String password) async {
    final url = Uri.parse('$baseUrl/users/login');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString("token", data["token"]); // ✅ Save token
      prefs.setString("userId", data["user"]["_id"]); // ✅ Save user ID
      return data;
    } else {
      throw Exception("Login Failed: ${response.body}");
    }
  }

  // ✅ Get All Users (Requires Token)
  static Future<List<dynamic>> getAllUsers() async {
    final url = Uri.parse('$baseUrl/users');
    String? token = await _getToken();
    if (token == null) throw Exception("Unauthorized: No token provided");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token", // ✅ Add token
        "Content-Type": "application/json"
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch users");
    }
  }

  // ✅ Get User Profile (Requires Token)
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final url = Uri.parse('$baseUrl/users/$userId');
    String? token = await _getToken();
    if (token == null) throw Exception("Unauthorized: No token provided");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token", // ✅ Add token
        "Content-Type": "application/json"
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch user profile.");
    }
  }

  // ✅ Update User Profile (Requires Token)
  static Future<Map<String, dynamic>> updateUser(String userId, String numPhone,
      String email, String profilePicture) async {
    final url = Uri.parse('$baseUrl/users/$userId');
    String? token = await _getToken();
    if (token == null) throw Exception("Unauthorized: No token provided");

    final response = await http.put(
      url,
      headers: {
        "Authorization": "Bearer $token", // ✅ Add token
        "Content-Type": "application/json"
      },
      body: jsonEncode({
        "num_phone": numPhone,
        "email": email,
        "profile_picture": profilePicture,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Update Failed: ${response.body}");
    }
  }

  // ✅ Request Password Reset
  static Future<Map<String, dynamic>> resetPassword(String email) async {
    final url = Uri.parse('$baseUrl/users/forgot-password');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Return success message
    } else {
      throw Exception("Failed to send password reset link.");
    }
  }

  // ✅ Submit Reclamation (Requires Token)
  static Future<Map<String, dynamic>> submitReclamation(
      String userId, String title, String description, File? image) async {
    final url = Uri.parse('$baseUrl/reclamations');
    String? token = await _getToken();
    if (token == null) throw Exception("Unauthorized: No token provided");

    var request = http.MultipartRequest('POST', url);
    request.headers["Authorization"] = "Bearer $token"; // ✅ Add token
    request.fields['id_user'] = userId;
    request.fields['title'] = title;
    request.fields['description'] = description;

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      return jsonDecode(responseData);
    } else {
      throw Exception("Failed to submit reclamation: $responseData");
    }
  }
}
