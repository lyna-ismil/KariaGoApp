import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kariago/constants/api_config.dart';

import 'payment_screen.dart'; // Import your api_config.dart

class ConfirmationScreen extends StatefulWidget {
  final String carId; // Added car ID parameter
  final DateTime startDate;
  final DateTime endDate;
  final String pickupLocation;
  final String dropOffLocation;
  final double estimatedPrice;

  const ConfirmationScreen({
    Key? key,
    required this.carId, // Required car ID
    required this.startDate,
    required this.endDate,
    required this.pickupLocation,
    required this.dropOffLocation,
    required this.estimatedPrice,
  }) : super(key: key);

  @override
  _ConfirmationScreenState createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? carDetails;

  // Define the blue colors to match EstimationScreen
  final Color primaryBlue = Color(0xFF1E88E5);
  final Color lightBlue = Color(0xFF64B5F6);
  final Color darkBlue = Color(0xFF1565C0);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Car details
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();

    // Fetch car details when screen initializes
    fetchCarDetails(widget.carId);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchCarDetails(String carId) async {
    final url = Uri.parse("$carEndpoint/$carId"); // Use the dynamic endpoint

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          carDetails = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load car details';
          _isLoading = false;
        });
        print("❌ Failed to load car data");
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('EEE, MMM d, yyyy • h:mm a').format(dateTime);
  }

  String _formatDuration() {
    final diff = widget.endDate.difference(widget.startDate);
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    String result = "";
    if (days > 0) result += "$days day${days > 1 ? 's' : ''} ";
    if (hours > 0) result += "$hours hour${hours > 1 ? 's' : ''} ";
    if (minutes > 0) result += "$minutes minute${minutes > 1 ? 's' : ''}";

    return result.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "Confirm Booking",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            height: MediaQuery.of(context).size.height * 0.25,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [darkBlue, primaryBlue],
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryBlue))
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header card with booking summary
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: Card(
                                  elevation: 8,
                                  shadowColor: Colors.black26,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Column(
                                      children: [
                                        // Car illustration
                                        Container(
                                          height: 120,
                                          decoration: BoxDecoration(
                                            color: lightBlue.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.directions_car,
                                              size: 64,
                                              color: primaryBlue,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 20),
                                        Text(
                                          "Booking Summary",
                                          style: GoogleFonts.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          "Please review your booking details before proceeding to payment",
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(height: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 24),

                            // Car details section
                            _buildSectionHeader(
                                "Car Details", Icons.directions_car),
                            SizedBox(height: 16),
                            carDetails == null
                                ? Center(child: CircularProgressIndicator())
                                : Column(
                                    children: [
                                      _buildDetailCard(
                                        title: "Selected Car",
                                        value: carDetails!['marque'] ??
                                            "Unknown Car",
                                        icon: Icons.car_rental,
                                        iconColor: primaryBlue,
                                      ),
                                      SizedBox(height: 12),
                                      _buildDetailCard(
                                        title: "License Plate",
                                        value:
                                            carDetails!['matricule'] ?? "N/A",
                                        icon: Icons.credit_card,
                                        iconColor: primaryBlue,
                                      ),
                                    ],
                                  ),

                            SizedBox(height: 24),

                            // Rental period section
                            _buildSectionHeader(
                                "Rental Period", Icons.calendar_today),
                            SizedBox(height: 16),
                            _buildDetailCard(
                              title: "Pick-up Date",
                              value: _formatDate(widget.startDate),
                              icon: Icons.play_circle_outline,
                              iconColor: primaryBlue,
                            ),
                            SizedBox(height: 12),
                            _buildDetailCard(
                              title: "Return Date",
                              value: _formatDate(widget.endDate),
                              icon: Icons.stop_circle_outlined,
                              iconColor: primaryBlue,
                            ),
                            SizedBox(height: 12),
                            _buildDetailCard(
                              title: "Duration",
                              value: _formatDuration(),
                              icon: Icons.timelapse,
                              iconColor: primaryBlue,
                            ),

                            SizedBox(height: 24),

                            // Location section
                            _buildSectionHeader("Locations", Icons.location_on),
                            SizedBox(height: 16),
                            _buildDetailCard(
                              title: "Pick-up Location",
                              value: widget.pickupLocation,
                              icon: Icons.location_searching,
                              iconColor: primaryBlue,
                            ),
                            SizedBox(height: 12),
                            _buildDetailCard(
                              title: "Drop-off Location",
                              value: widget.dropOffLocation,
                              icon: Icons.location_on,
                              iconColor: primaryBlue,
                            ),

                            SizedBox(height: 24),

                            // Price section
                            _buildSectionHeader(
                                "Price Details", Icons.attach_money),
                            SizedBox(height: 16),
                            Card(
                              elevation: 4,
                              shadowColor: primaryBlue.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      lightBlue.withOpacity(0.2),
                                      Colors.white,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Base Rate",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        Text(
                                          "\ ${(widget.estimatedPrice * 0.8).toStringAsFixed(2)} DT",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Taxes & Fees",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        Text(
                                          "\ ${(widget.estimatedPrice * 0.2).toStringAsFixed(2)} DT",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    Divider(color: Colors.grey[300]),
                                    SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Total Price",
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: darkBlue,
                                          ),
                                        ),
                                        Text(
                                          "\ ${widget.estimatedPrice.toStringAsFixed(2)} DT",
                                          style: GoogleFonts.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: primaryBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: 40),

                            // Payment button
                            Container(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Navigate to the payment screen with the total amount
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PaymentScreen(
                                        carId: widget
                                            .carId, // Reuse the carId passed to ConfirmationScreen
                                        startDate: widget.startDate,
                                        endDate: widget.endDate,
                                        pickupLocation: widget.pickupLocation,
                                        dropOffLocation: widget.dropOffLocation,
                                        totalAmount: widget.estimatedPrice,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.payment, size: 24),
                                    SizedBox(width: 12),
                                    Text(
                                      "Proceed to Payment",
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: 30),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: primaryBlue),
        SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[900],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
