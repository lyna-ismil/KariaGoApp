import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'dart:io';
import 'confirmation_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String selectedCar;
  final DateTime startDate;
  final DateTime endDate;
  final String dropOffLocation;
  final String fullName;
  final File cinImage;
  final File licenseImage;
  final String paymentMethod;

  PaymentScreen({
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
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  String selectedPaymentMethod = "Credit/Debit Card";
  String cardNumber = "";
  String expiryDate = "";
  String cardHolderName = "";
  String cvvCode = "";
  bool isCvvFocused = false;
  bool isProcessing = false;

  void _processPayment() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isProcessing = true;
      });

      // Simulate processing time
      Future.delayed(Duration(seconds: 2), () {
        setState(() {
          isProcessing = false;
        });

        // Navigate to Confirmation Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmationScreen(
              selectedCar: widget.selectedCar,
              startDate: widget.startDate,
              endDate: widget.endDate,
              dropOffLocation: widget.dropOffLocation,
              fullName: widget.fullName,
              cinImage: widget.cinImage,
              licenseImage: widget.licenseImage,
              paymentMethod: selectedPaymentMethod,
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Payment"),
        backgroundColor: Colors.blue.shade800,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Booking Summary"),
              _buildSummaryTile("Car Model", widget.selectedCar),
              _buildSummaryTile("Rental Start", "${widget.startDate}"),
              _buildSummaryTile("Rental End", "${widget.endDate}"),
              _buildSummaryTile("Drop-Off Location", widget.dropOffLocation),
              _buildSummaryTile("Full Name", widget.fullName),

              // CIN & License Images
              _buildSectionTitle("Verification Documents"),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImagePreview(widget.cinImage, "CIN"),
                  _buildImagePreview(widget.licenseImage, "Driver's License"),
                ],
              ),
              SizedBox(height: 20),

              // Payment Method Selection
              _buildSectionTitle("Select Payment Method"),
              _buildPaymentOptions(),

              if (selectedPaymentMethod == "Credit/Debit Card") ...[
                SizedBox(height: 20),
                _buildCreditCardForm(),
              ],

              // Pay Button
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: isProcessing ? null : _processPayment,
                child: isProcessing
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Confirm Payment", style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Section Title
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 20, bottom: 10),
      child: Text(title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  // Booking Summary Tiles
  Widget _buildSummaryTile(String title, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value),
    );
  }

  // Payment Options
  Widget _buildPaymentOptions() {
    return Column(
      children: [
        RadioListTile<String>(
          title: Text("Credit/Debit Card"),
          value: "Credit/Debit Card",
          groupValue: selectedPaymentMethod,
          onChanged: (value) => setState(() => selectedPaymentMethod = value!),
        ),
        RadioListTile<String>(
          title: Text("Google Pay / Apple Pay"),
          value: "Google Pay / Apple Pay",
          groupValue: selectedPaymentMethod,
          onChanged: (value) => setState(() => selectedPaymentMethod = value!),
        ),
        RadioListTile<String>(
          title: Text("PayPal"),
          value: "PayPal",
          groupValue: selectedPaymentMethod,
          onChanged: (value) => setState(() => selectedPaymentMethod = value!),
        ),
      ],
    );
  }

  // Credit Card Form
  Widget _buildCreditCardForm() {
    return Column(
      children: [
        CreditCardWidget(
          cardNumber: cardNumber,
          expiryDate: expiryDate,
          cardHolderName: cardHolderName,
          cvvCode: cvvCode,
          showBackView: isCvvFocused,
          onCreditCardWidgetChange: (CreditCardBrand brand) {},
        ),
        CreditCardForm(
          formKey: _formKey,
          cardNumber: cardNumber,
          expiryDate: expiryDate,
          cardHolderName: cardHolderName,
          cvvCode: cvvCode,
          onCreditCardModelChange: (CreditCardModel data) {
            setState(() {
              cardNumber = data.cardNumber;
              expiryDate = data.expiryDate;
              cardHolderName = data.cardHolderName;
              cvvCode = data.cvvCode;
              isCvvFocused = data.isCvvFocused;
            });
          },
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
