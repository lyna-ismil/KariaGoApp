import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import 'confirmation_screen.dart';

class EstimationScreen extends StatefulWidget {
  final String carId; // Added car ID parameter
  final String pickupLocation;

  const EstimationScreen({
    Key? key,
    required this.carId,
    required this.pickupLocation,
  }) : super(key: key);

  @override
  _EstimationScreenState createState() => _EstimationScreenState();
}

class _EstimationScreenState extends State<EstimationScreen>
    with SingleTickerProviderStateMixin {
  DateTime? startDate;
  DateTime? endDate;
  double? estimatedCost;
  bool isLoading = false;
  String dropOffLocation = ""; // Added field for drop-off location
  late String pickupLocation;

  // Define the blue colors
  final Color primaryBlue = Color(0xFF1E88E5);
  final Color lightBlue = Color(0xFF64B5F6);
  final Color darkBlue = Color(0xFF1565C0);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    pickupLocation = widget.pickupLocation;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryBlue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: primaryBlue,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: primaryBlue,
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isStart) {
            startDate = fullDateTime;
            endDate = null;
          } else {
            endDate = fullDateTime;
          }
        });
      }
    }
  }

  Future<void> _estimateCost() async {
    if (startDate == null || endDate == null) {
      _showErrorSnackBar('Please select both start and end time');
      return;
    }

    final diff = endDate!.difference(startDate!);
    final totalDurationHours = diff.inMinutes / 60;
    final durationDays = diff.inDays == 0 ? 1 : diff.inDays;
    final bookingHour = startDate!.hour.toDouble();
    final bookingDayOfWeek = startDate!.weekday % 7; // Sunday = 0
    final bookingMonth = startDate!.month;
    final isWeekend = bookingDayOfWeek == 6 || bookingDayOfWeek == 0;
    final isPeakHour = bookingHour >= 8 && bookingHour <= 10 ||
        bookingHour >= 17 && bookingHour <= 19;

    final bookingCount = 2; // Placeholder, retrieve from DB
    final driveBehaviorScore = 4.5; // Placeholder, retrieve from DB

    final url = Uri.parse("http://85.214.12.71:8000/predict");
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      "booking_hour": bookingHour,
      "booking_day_of_week": bookingDayOfWeek,
      "booking_month": bookingMonth,
      "is_peak_hour": isPeakHour ? 1 : 0,
      "is_weekend": isWeekend ? 1 : 0,
      "total_duration_hours": totalDurationHours,
      "duration_days": durationDays,
      "booking_count": bookingCount,
      "drive_behavior_score": driveBehaviorScore,
    });

    setState(() => isLoading = true);
    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          estimatedCost = result['estimated_cost'];
          if (estimatedCost != null) {
            _animationController.reset();
            _animationController.forward();
          }
        });
      } else {
        _showErrorSnackBar('Failed to estimate cost');
      }
    } catch (e) {
      print('Error: $e');
      _showErrorSnackBar('An error occurred. Is the API running?');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Updated method to navigate to confirmation screen with all required data
  void _navigateToConfirmation() {
    if (startDate != null &&
        endDate != null &&
        estimatedCost != null &&
        dropOffLocation.isNotEmpty &&
        pickupLocation.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmationScreen(
            carId: widget.carId,
            startDate: startDate!,
            endDate: endDate!,
            pickupLocation: pickupLocation,
            dropOffLocation: dropOffLocation,
            estimatedPrice: estimatedCost!,
          ),
        ),
      );
    } else {
      _showErrorSnackBar(
        "Please complete all required fields including pickup and drop-off locations",
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor:
            darkBlue, // Changed to dark blue to match the color scheme
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  // Added method for drop-off location input
  Widget _buildDropOffInput() {
    return Card(
      elevation: 4,
      shadowColor: primaryBlue.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: dropOffLocation.isNotEmpty
              ? Border.all(color: primaryBlue.withOpacity(0.5), width: 2)
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: dropOffLocation.isNotEmpty
                    ? lightBlue.withOpacity(0.2)
                    : Colors.grey[100],
                shape: BoxShape.circle,
                boxShadow: dropOffLocation.isNotEmpty
                    ? [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.location_on,
                color:
                    dropOffLocation.isNotEmpty ? primaryBlue : Colors.grey[600],
                size: 28,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Drop-off Location',
                  hintText: 'Enter the drop-off location',
                  labelStyle: GoogleFonts.poppins(
                    color: Colors.grey[700],
                  ),
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                ),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.grey[800],
                ),
                onChanged: (value) {
                  setState(() {
                    dropOffLocation = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? dt) => dt == null
      ? 'Select Date & Time'
      : DateFormat('EEE, MMM d, yyyy • h:mm a').format(dt);

  String _formatDuration() {
    if (startDate == null || endDate == null) return "";

    final diff = endDate!.difference(startDate!);
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    String result = "";
    if (days > 0) result += "$days day${days > 1 ? 's' : ''} ";
    if (hours > 0) result += "$hours hour${hours > 1 ? 's' : ''} ";
    if (minutes > 0) result += "$minutes minute${minutes > 1 ? 's' : ''}";

    return result.trim();
  }

  double _calculateProgress() {
    if (startDate == null && endDate == null) return 0.0;
    if (startDate != null && endDate == null) return 0.33;
    if (startDate != null && endDate != null && dropOffLocation.isEmpty)
      return 0.66;
    return 1.0;
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
          "Estimate Rental Price",
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
            height: MediaQuery.of(context).size.height * 0.3,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header card with illustration
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
                            "Get Your Rental Estimate",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Select your pick-up and return times to calculate your estimated rental price",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 20),

                          // Progress indicator
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Your progress",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    "${(_calculateProgress() * 100).toInt()}%",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: _calculateProgress(),
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      primaryBlue),
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 30),

                  // Date selection section
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: primaryBlue),
                      SizedBox(width: 8),
                      Text(
                        "Rental Period",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Start date card
                  _buildDateTimeCard(
                    title: "Pick-up",
                    subtitle: "When will you get the car?",
                    icon: Icons.play_circle_outline,
                    date: startDate,
                    onTap: () => _pickDateTime(isStart: true),
                  ),

                  // Connector
                  if (startDate != null)
                    Container(
                      margin: EdgeInsets.only(left: 28),
                      width: 2,
                      height: 30,
                      color: primaryBlue.withOpacity(0.3),
                    ),

                  // End date card
                  _buildDateTimeCard(
                    title: "Return",
                    subtitle: "When will you return the car?",
                    icon: Icons.stop_circle_outlined,
                    date: endDate,
                    onTap: startDate == null
                        ? null
                        : () => _pickDateTime(isStart: false),
                    disabled: startDate == null,
                  ),

                  // Duration display
                  if (startDate != null && endDate != null) ...[
                    SizedBox(height: 24),
                    Card(
                      elevation: 4,
                      shadowColor: Colors.black12,
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
                              child: Icon(Icons.timelapse,
                                  color: primaryBlue, size: 28),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Rental Duration",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _formatDuration(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
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
                  ],

                  // Drop-off location section (added)
                  if (startDate != null && endDate != null) ...[
                    SizedBox(height: 30),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 18, color: primaryBlue),
                        SizedBox(width: 8),
                        Text(
                          "Drop-off Location",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildDropOffInput(),
                  ],

                  SizedBox(height: 30),

                  // Estimate button
                  Container(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _estimateCost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calculate, size: 24),
                                SizedBox(width: 12),
                                Text(
                                  "Calculate Estimate",
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

                  // Results section
                  if (estimatedCost != null)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Card(
                            elevation: 12,
                            shadowColor: primaryBlue.withOpacity(0.4),
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
                                  // Success icon
                                  Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    "Estimate Complete",
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Based on your selected dates",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  SizedBox(height: 24),

                                  // Price display
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 16, horizontal: 24),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          "Estimated Cost",
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color:
                                                Colors.white.withOpacity(0.9),
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${estimatedCost!.toStringAsFixed(2)} DT",
                                              style: GoogleFonts.poppins(
                                                fontSize: 36,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "for ${_formatDuration()}",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color:
                                                Colors.white.withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: 24),

                                  // Booking button - Updated to use _navigateToConfirmation
                                  Container(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _navigateToConfirmation,
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
                                          Icon(Icons.directions_car, size: 24),
                                          SizedBox(width: 12),
                                          Text(
                                            "Continue to Booking",
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
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

  Widget _buildDateTimeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required DateTime? date,
    required VoidCallback? onTap,
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: date != null ? 4 : 2,
        shadowColor:
            date != null ? primaryBlue.withOpacity(0.3) : Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: disabled ? Colors.grey[100] : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: date != null
                ? Border.all(color: primaryBlue.withOpacity(0.5), width: 2)
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: disabled
                      ? Colors.grey[300]
                      : (date != null
                          ? lightBlue.withOpacity(0.2)
                          : Colors.grey[100]),
                  shape: BoxShape.circle,
                  boxShadow: date != null
                      ? [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  color: disabled
                      ? Colors.grey[500]
                      : (date != null ? primaryBlue : Colors.grey[600]),
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: disabled ? Colors.grey[500] : Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      date != null ? _formatDate(date) : subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: date != null ? 15 : 13,
                        fontWeight:
                            date != null ? FontWeight.w500 : FontWeight.normal,
                        color: disabled
                            ? Colors.grey[500]
                            : (date != null ? primaryBlue : Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: disabled
                    ? Colors.grey[400]
                    : (date != null ? primaryBlue : Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
