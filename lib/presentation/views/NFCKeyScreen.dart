import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

import '../../constants/api_config.dart'; // ✅ uses centralized endpoint

class NFCKeyScreen extends StatefulWidget {
  final String carId;
  final DateTime startDate;
  final DateTime endDate;
  final String pickupLocation;
  final String dropOffLocation;
  final double estimatedPrice;
  final String bookingId; // ✅ Required for PUT request

  const NFCKeyScreen({
    Key? key,
    required this.carId,
    required this.startDate,
    required this.endDate,
    required this.pickupLocation,
    required this.dropOffLocation,
    required this.estimatedPrice,
    required this.bookingId,
  }) : super(key: key);

  @override
  _NFCKeyScreenState createState() => _NFCKeyScreenState();
}

class _NFCKeyScreenState extends State<NFCKeyScreen>
    with SingleTickerProviderStateMixin {
  late String nfcKey;
  Timer? countdownTimer;
  Duration remaining = Duration.zero;
  bool _isLoading = false;
  Map<String, dynamic> _carDetails = {};

  // Define the blue colors to match other screens
  final Color primaryBlue = Color(0xFF1E88E5);
  final Color lightBlue = Color(0xFF64B5F6);
  final Color darkBlue = Color(0xFF1565C0);

  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    generateNfcKey();
    startCountdown();
    _fetchCarDetails();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  void generateNfcKey() {
    final raw =
        '${widget.carId}|${widget.startDate.millisecondsSinceEpoch}|${Random().nextInt(999999)}';
    nfcKey = base64Url.encode(utf8.encode(raw));
  }

  void startCountdown() {
    final now = DateTime.now();
    if (now.isBefore(widget.startDate)) {
      remaining = widget.startDate.difference(now);
      countdownTimer = Timer.periodic(Duration(seconds: 1), (_) {
        setState(() {
          final newNow = DateTime.now();
          remaining = widget.startDate.difference(newNow);
          if (remaining.isNegative) {
            countdownTimer?.cancel();
          }
        });
      });
    }
  }

  Future<void> _fetchCarDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Replace with your actual API endpoint
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/cars/${widget.carId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _carDetails = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> updateBookingWithKey() async {
    final url = Uri.parse('$bookingEndpoint/${widget.bookingId}');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'current_Key_car': nfcKey}),
    );

    if (response.statusCode == 200) {
      print("✅ Booking updated with NFC key");
    } else {
      print(
          "❌ Failed to update booking: ${response.statusCode} ${response.body}");
    }
  }

  Future<void> writeKeyToCard() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: lightBlue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.nfc, color: primaryBlue),
              ),
              SizedBox(width: 12),
              Text(
                "Ready to Write NFC",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: darkBlue,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Hold your NFC card near the back of the phone...",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
              ),
            ],
          ),
        ),
      );

      await FlutterNfcKit.poll();

      final record = ndef.TextRecord(
        text: nfcKey,
        language: 'en',
        encoding: ndef.TextEncoding.UTF8,
      );

      await FlutterNfcKit.writeNDEFRecords([record]);
      await FlutterNfcKit.finish();
      Navigator.of(context).pop();

      await updateBookingWithKey();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text(
                "NFC key written and booking updated",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      await FlutterNfcKit.finish();
      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline, color: Colors.red[700]),
              ),
              SizedBox(width: 12),
              Text(
                "Failed to write",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          content: Text(
            "Error: ${e.toString()}",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                "Try Again",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: primaryBlue,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                writeKeyToCard();
              },
            ),
            TextButton(
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final canWrite = now.isAfter(widget.startDate);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "Digital Car Key",
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
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header card with car details
                        Card(
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
                                    borderRadius: BorderRadius.circular(16),
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
                                  _carDetails['marque'] ?? "Your Car",
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: darkBlue,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: lightBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: lightBlue.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    _carDetails['matricule'] ?? "License Plate",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: primaryBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 24),

                        // Booking details section
                        _buildSectionHeader(
                            "Booking Details", Icons.calendar_today),
                        SizedBox(height: 16),

                        _buildDetailCard(
                          title: "Pick-up Date",
                          value: DateFormat('EEE, MMM d, yyyy • h:mm a')
                              .format(widget.startDate),
                          icon: Icons.play_circle_outline,
                          iconColor: primaryBlue,
                        ),

                        SizedBox(height: 12),

                        _buildDetailCard(
                          title: "Return Date",
                          value: DateFormat('EEE, MMM d, yyyy • h:mm a')
                              .format(widget.endDate),
                          icon: Icons.stop_circle_outlined,
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
                        _buildSectionHeader("Price", Icons.attach_money),
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
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryBlue.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(Icons.attach_money,
                                      color: primaryBlue, size: 28),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Total Price",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "\ ${widget.estimatedPrice.toStringAsFixed(2)} DT",
                                        style: GoogleFonts.poppins(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: primaryBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 40),

                        // NFC Key section
                        if (!canWrite && remaining.inSeconds > 0) ...[
                          Card(
                            elevation: 8,
                            shadowColor: darkBlue.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Container(
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [darkBlue, primaryBlue],
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.timer,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    "Booking starts in",
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildTimeBox(remaining.inHours
                                          .toString()
                                          .padLeft(2, '0')),
                                      SizedBox(width: 8),
                                      Text(
                                        ":",
                                        style: GoogleFonts.poppins(
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      _buildTimeBox((remaining.inMinutes % 60)
                                          .toString()
                                          .padLeft(2, '0')),
                                      SizedBox(width: 8),
                                      Text(
                                        ":",
                                        style: GoogleFonts.poppins(
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      _buildTimeBox((remaining.inSeconds % 60)
                                          .toString()
                                          .padLeft(2, '0')),
                                    ],
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    "You'll be able to write your NFC key when the booking starts",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          Card(
                            elevation: 8,
                            shadowColor: darkBlue.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Container(
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [darkBlue, primaryBlue],
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Column(
                                children: [
                                  AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _pulseAnimation.value,
                                        child: Container(
                                          padding: EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.nfc,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    "Your Digital Key is Ready",
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    "Write your digital key to an NFC card to unlock your car",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  SizedBox(height: 24),
                                  Container(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: writeKeyToCard,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: primaryBlue,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.nfc, size: 24),
                                          SizedBox(width: 12),
                                          Text(
                                            "Write NFC Key to Card",
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Card(
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
                                      color: lightBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.info_outline,
                                        color: primaryBlue),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "How to use",
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          "Tap the NFC card on the car's reader to unlock. Keep the card with you during your rental period.",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

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

  Widget _buildTimeBox(String value) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
