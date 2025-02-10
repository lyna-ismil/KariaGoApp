import 'package:flutter/material.dart';
import 'dart:io';
import 'package:lottie/lottie.dart';

class ConfirmationScreen extends StatelessWidget {
  final String selectedCar;
  final DateTime startDate;
  final DateTime endDate;
  final String dropOffLocation;
  final String fullName;
  final File cinImage;
  final File licenseImage;
  final String paymentMethod;

  ConfirmationScreen({
    required this.selectedCar,
    required this.startDate,
    required this.endDate,
    required this.dropOffLocation,
    required this.fullName,
    required this.cinImage,
    required this.licenseImage,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text("Booking Confirmed"),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Success Animation
            Lottie.asset('assets/animations/success.json',
                height: 150, repeat: false),

            SizedBox(height: 20),
            Text(
              "Your Booking is Confirmed!",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              "Here are your booking details:",
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),

            // Booking Details Card
            _buildDetailCard(),

            SizedBox(height: 20),

            // Document Images
            _buildDocumentSection(),

            SizedBox(height: 30),

            // Return to Home Button
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.home),
              label: Text("Return to Home", style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Booking Details Card
  Widget _buildDetailCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDetailTile("Car Model", selectedCar),
            _buildDetailTile("Rental Start", startDate.toString()),
            _buildDetailTile("Rental End", endDate.toString()),
            _buildDetailTile("Drop-Off Location", dropOffLocation),
            _buildDetailTile("Full Name", fullName),
            _buildDetailTile("Payment Method", paymentMethod),
          ],
        ),
      ),
    );
  }

  // Booking Detail Tiles
  Widget _buildDetailTile(String title, String value) {
    return ListTile(
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle:
          Text(value, style: TextStyle(fontSize: 14, color: Colors.black87)),
      contentPadding: EdgeInsets.symmetric(vertical: 4),
    );
  }

  // Document Images (CIN & License)
  Widget _buildDocumentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text("Verification Documents",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildImagePreview(cinImage, "CIN"),
            _buildImagePreview(licenseImage, "Driver’s License"),
          ],
        ),
      ],
    );
  }

  // Image Preview
  Widget _buildImagePreview(File image, String label) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(image, height: 100, width: 100, fit: BoxFit.cover),
        ),
        SizedBox(height: 5),
        Text(label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
