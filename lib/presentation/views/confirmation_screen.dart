import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';

class ConfirmationScreen extends StatelessWidget {
  final String selectedCar;
  final DateTime startDate;
  final DateTime endDate;
  final String dropOffLocation;
  final String fullName;
  final String paymentMethod;

  ConfirmationScreen({
    required this.selectedCar,
    required this.startDate,
    required this.endDate,
    required this.dropOffLocation,
    required this.fullName,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text("Booking Confirmed"),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDetailCard(),
                  SizedBox(height: 30),
                  _buildReturnHomeButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(bottom: 30),
      decoration: BoxDecoration(
        color: Colors.blue.shade800,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Lottie.asset('assets/animations/success.json',
              height: 150, repeat: false),
          Text(
            "Your Booking is Confirmed!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            "Here are your booking details:",
            style: TextStyle(fontSize: 16, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Booking Details",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            Divider(color: Colors.blue.shade100, thickness: 2),
            _buildDetailTile(Icons.directions_car, "Car Model", selectedCar),
            _buildDetailTile(Icons.calendar_today, "Rental Start",
                DateFormat('MMM dd, yyyy').format(startDate)),
            _buildDetailTile(Icons.event_available, "Rental End",
                DateFormat('MMM dd, yyyy').format(endDate)),
            _buildDetailTile(
                Icons.location_on, "Drop-Off Location", dropOffLocation),
            _buildDetailTile(Icons.person, "Full Name", fullName),
            _buildDetailTile(Icons.payment, "Payment Method", paymentMethod),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue.shade600, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue.shade800)),
                SizedBox(height: 4),
                Text(value,
                    style: TextStyle(fontSize: 14, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnHomeButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => Navigator.pop(context),
      icon: Icon(Icons.home),
      label: Text("Return to Home", style: TextStyle(fontSize: 18)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 5,
      ),
    );
  }
}
