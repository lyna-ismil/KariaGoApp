import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'login_screen.dart';
import 'booking_screen.dart';
import 'profile_screen.dart';
import 'reclamation_screen.dart';
import 'AboutUsScreen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "User"; // Default placeholder
  String userEmail = "email@example.com"; // Default placeholder

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString("userId"); // Retrieve user ID

      if (userId == null) {
        setState(() {
          userName = "User";
          userEmail = "email@example.com";
        });
        return;
      }

      var userData = await ApiService.getUserProfile(userId); // ✅ Pass userId

      if (userData != null) {
        setState(() {
          userName = userData["fullName"] ?? "User"; // ✅ Use correct key
          userEmail = userData["email"] ?? "email@example.com";
        });
      }
    } catch (e) {
      print(" Error loading user data: $e");
    }
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("token"); // Remove JWT token
    await prefs.remove("username");
    await prefs.remove("email");

    // Navigate to login screen and clear previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "KariaGo",
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawer(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade800, Colors.indigo.shade600],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome, $userName",
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Your journey begins here",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 40),
                        _buildFeatureCard(
                          context,
                          "Book a Car",
                          "Find and reserve your perfect ride",
                          Icons.directions_car,
                          BookingScreen(),
                        ),
                        SizedBox(height: 20),
                        _buildFeatureCard(
                          context,
                          "My Profile",
                          "Manage your account details",
                          Icons.person,
                          ProfileScreen(),
                        ),
                        SizedBox(height: 20),
                        _buildFeatureCard(
                          context,
                          "Support",
                          "Get help or report an issue",
                          Icons.headset_mic,
                          ReclamationScreen(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookingScreen()),
        ),
        icon: Icon(Icons.car_rental),
        label: Text("Quick Book"),
        backgroundColor: Colors.orange,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.indigo.shade50,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade800, Colors.indigo.shade600],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        AssetImage('assets/avatar_placeholder.png'),
                  ),
                  SizedBox(height: 10),
                  Text(
                    userName,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userEmail,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(context, Icons.person, 'Profile', ProfileScreen()),
            _buildDrawerItem(
                context, Icons.headset_mic, 'Support', ReclamationScreen()),
            _buildDrawerItem(
                context, Icons.directions_car, 'Book a Car', BookingScreen()),
            Divider(),
            _buildDrawerItem(context, Icons.info, 'About Us',
                AboutUsScreen()), // ✅ New "About Us" item
            Divider(),
            _buildDrawerItem(context, Icons.exit_to_app, 'Logout', null,
                onTap: _logout),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, IconData icon, String title, Widget? screen,
      {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo.shade800),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.indigo.shade800,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        if (onTap != null) {
          onTap(); // If a function is provided (for logout)
        } else if (screen != null) {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => screen));
        }
      },
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, String subtitle,
      IconData icon, Widget screen) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => screen)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.indigo.shade800),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.indigo.shade800),
            ],
          ),
        ),
      ),
    );
  }
}
