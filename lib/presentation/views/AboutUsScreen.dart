import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AboutUsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(height: 40),
                      _buildHeader(),
                      SizedBox(height: 40),
                      Expanded(
                        child: _buildContent(),
                      ),
                      SizedBox(height: 20),
                      _buildSocialLinks(),
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "About KariaGo",
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(duration: 600.ms).slideX(),
        SizedBox(height: 8),
        Text(
          "Revolutionizing Car Rentals",
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 18,
          ),
        ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideX(),
      ],
    );
  }

  Widget _buildContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          )
        ],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildSection(
                "Our Mission",
                "KariaGo is dedicated to providing a seamless, secure, and smart car rental experience through cutting-edge technology and exceptional customer service.",
                Icons.rocket_launch,
              ),
              SizedBox(height: 20),
              _buildSection(
                "Our Vision",
                "To be the leading global platform for innovative and reliable transportation solutions, empowering people to explore the world with ease and confidence.",
                Icons.remove_red_eye,
              ),
              SizedBox(height: 20),
              _buildSection(
                "Why Choose Us?",
                "• Quick and easy bookings\n• Wide range of vehicles\n• Competitive prices\n• 24/7 customer support\n• Contactless rentals",
                Icons.check_circle,
              ),
              SizedBox(height: 20),
              _buildSection(
                "Contact Us",
                "Email: contact@kariago.com\nPhone: +216 123 456 789\nAddress: Tunis, Tunisia",
                Icons.contact_mail,
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 400.ms)
        .slideY(begin: 0.3, end: 0);
  }

  Widget _buildSection(String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Color(0xFF1E88E5), size: 24),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: Color(0xFF1E88E5),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialIcon(FontAwesomeIcons.facebook, Colors.blue),
        SizedBox(width: 20),
        _buildSocialIcon(FontAwesomeIcons.twitter, Colors.lightBlue),
        SizedBox(width: 20),
        _buildSocialIcon(FontAwesomeIcons.instagram, Colors.purple),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 600.ms);
  }

  Widget _buildSocialIcon(IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
