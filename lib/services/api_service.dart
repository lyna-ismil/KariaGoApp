import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      "http://localhost:5000/api"; // ✅ Replace with your backend URL

  //  User Signup
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

  //  User Login
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
      return jsonDecode(response.body);
    } else {
      throw Exception("Login Failed: ${response.body}");
    }
  }

  // Get All Users
  static Future<List<dynamic>> getAllUsers() async {
    final url = Uri.parse('$baseUrl/users');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch users");
    }
  }

  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final url = Uri.parse('$baseUrl/users/$userId');

    final response = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch user profile.");
    }
  }

  // Update User Profile
  static Future<Map<String, dynamic>> updateUser(String userId, String numPhone,
      String email, String profilePicture) async {
    final url = Uri.parse('$baseUrl/users/$userId');

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
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
}
