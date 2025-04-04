import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_config.dart';

import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("token"); // Retrieve saved JWT token
  }

  static Future<Map<String, dynamic>> signupUser(String cin, String permis,
      String numPhone, String email, String password) async {
    final url = Uri.parse('$userEndpoint/signup');

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

  // User Login (Save Token)
  static Future<Map<String, dynamic>> loginUser(
      String email, String password) async {
    final url = Uri.parse('$userEndpoint/login');

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
      prefs.setString("token", data["token"]); //  Save token
      prefs.setString("userId", data["user"]["_id"]); //  Save user ID
      return data;
    } else {
      throw Exception("Login Failed: ${response.body}");
    }
  }

  static Future<bool> createBooking({
    required String userId,
    required String token,
    required String carId,
    required DateTime startDate,
    required DateTime endDate,
    required String location,
    required String fullName,
  }) async {
    final url = Uri.parse(bookingEndpoint); // http://192.168.1.9:5000/bookings

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "id_user": userId,
        "id_car": carId,
        "date_hour_booking": startDate.toIso8601String(),
        "date_hour_expire": endDate.toIso8601String(),
        "location_After_Renting": location,
        "fullName": fullName,
        "status": "pending",
        "paiement": 0
      }),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      print("❌ Booking Error: ${response.body}");
      return false;
    }
  }

  // Get All Users (Requires Token)
  static Future<List<dynamic>> getAllUsers() async {
    final url = Uri.parse(userEndpoint); // ✅ Correct endpoint for ALL users
    String? token = await _getToken();
    if (token == null) throw Exception("Unauthorized: No token provided");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token", //  Add token
        "Content-Type": "application/json"
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch users");
    }
  }

  //  Get User Profile (Requires Token)
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final url = Uri.parse('$userEndpoint/$userId');
    String? token = await _getToken();
    if (token == null) throw Exception("Unauthorized: No token provided");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token", //  Add token
        "Content-Type": "application/json"
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch user profile.");
    }
  }

  //  Update User Profile (Requires Token)
  static Future<Map<String, dynamic>> updateUser(String userId, String numPhone,
      String email, String profilePicture) async {
    final url = Uri.parse('$userEndpoint/$userId');
    String? token = await _getToken();
    if (token == null) throw Exception("Unauthorized: No token provided");

    final response = await http.put(
      url,
      headers: {
        "Authorization": "Bearer $token", // Add token
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

  //  Request Password Reset
  static Future<Map<String, dynamic>> resetPassword(String email) async {
    final url = Uri.parse('$userEndpoint/forgot-password');

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

// 🔐 Get All Cars (Requires Token)
  static Future<List<dynamic>> getAllCars() async {
    final url =
        Uri.parse(carEndpoint); // uses car endpoint from api_config.dart
    String? token = await _getToken();

    if (token == null) throw Exception("Unauthorized: No token provided");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch cars: ${response.body}");
    }
  }

  // Submit Reclamation (Requires Token)
  static Future<Map<String, dynamic>> submitReclamation(
      String userId, String title, String description, File? image) async {
    final url = Uri.parse('$reclamationEndpoint');
    String? token = await _getToken();
    if (token == null) throw Exception("Unauthorized: No token provided");

    var request = http.MultipartRequest('POST', url);
    request.headers["Authorization"] = "Bearer $token"; // Add token
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
