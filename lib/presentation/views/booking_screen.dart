import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_animate/flutter_animate.dart';
import 'payment_screen.dart';

class BookingScreen extends StatefulWidget {
  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String? selectedCar;
  DateTime? startDate;
  DateTime? endDate;
  final TextEditingController dropOffController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  File? _cinImage;
  File? _licenseImage;

  String formatDate(DateTime? date) {
    return date != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(date)
        : "Select Date";
  }

  Future<void> _captureImage(bool isCIN) async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        if (isCIN) {
          _cinImage = File(pickedFile.path);
        } else {
          _licenseImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _pickDateTime(BuildContext context, bool isStart) async {
    DateTime now = DateTime.now();
    DateTime initialDate =
        isStart ? now : startDate?.add(Duration(hours: 1)) ?? now;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade800,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(pickedDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.blue.shade800,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        DateTime finalDateTime = DateTime(pickedDate.year, pickedDate.month,
            pickedDate.day, pickedTime.hour, pickedTime.minute);

        setState(() {
          if (isStart) {
            startDate = finalDateTime;
            endDate = null; // Reset end date
          } else {
            endDate = finalDateTime;
          }
        });
      }
    }
  }

  void _proceedToPayment() {
    if (selectedCar == null ||
        startDate == null ||
        endDate == null ||
        dropOffController.text.isEmpty ||
        fullNameController.text.isEmpty ||
        _cinImage == null ||
        _licenseImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please complete all fields!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          selectedCar: selectedCar!,
          startDate: startDate!,
          endDate: endDate!,
          dropOffLocation: dropOffController.text,
          fullName: fullNameController.text,
          cinImage: _cinImage!,
          licenseImage: _licenseImage!,
          paymentMethod: "Not Selected Yet",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.network(
              'https://pictures.dealer.com/w/westbroadhyundai/1240/20c14adcb3b6fa8de449c0f8b6a05f34x.jpg?impolicy=downsize_bkpt&w=2500',
              fit: BoxFit.cover,
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200.0,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Book with KariaGo Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black,
                          offset: Offset(5.0, 5.0),
                        ),
                      ],
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 30, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Select a Car"),
                        _buildCarSelector(),
                        _buildSectionTitle("Rental Period"),
                        _buildDateSelector(context),
                        _buildSectionTitle("Drop-Off Location"),
                        _buildTextField(dropOffController,
                            "Enter drop-off location", Icons.location_on),
                        _buildSectionTitle("Full Name"),
                        _buildTextField(fullNameController, "Enter full name",
                            Icons.person),
                        _buildSectionTitle("Capture National ID (CIN)"),
                        _buildImageCaptureButton(_cinImage,
                            () => _captureImage(true), "Capture CIN"),
                        _buildSectionTitle("Capture Driver's License"),
                        _buildImageCaptureButton(_licenseImage,
                            () => _captureImage(false), "Capture License"),
                        SizedBox(height: 30),
                        _buildSubmitButton(),
                      ]
                          .animate(interval: 100.ms)
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.2, end: 0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800),
      ),
    );
  }

  Widget _buildCarSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedCar,
          hint: Text("Choose a car"),
          items: ["Tesla Model 3", "BMW X5", "Toyota Corolla"]
              .map((car) => DropdownMenuItem(value: car, child: Text(car)))
              .toList(),
          onChanged: (value) => setState(() => selectedCar = value),
        ),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildDateButton(context, true),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildDateButton(context, false),
        ),
      ],
    );
  }

  Widget _buildDateButton(BuildContext context, bool isStart) {
    return ElevatedButton.icon(
      onPressed: () => _pickDateTime(context, isStart),
      icon: Icon(Icons.calendar_today, color: Colors.blue.shade800),
      label: Text(
        formatDate(isStart ? startDate : endDate),
        style: TextStyle(color: Colors.black87),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade200,
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue.shade800),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue.shade800, width: 2),
        ),
      ),
    );
  }

  Widget _buildImageCaptureButton(
      File? image, VoidCallback onPressed, String label) {
    return Column(
      children: [
        image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(image,
                    height: 120, width: double.infinity, fit: BoxFit.cover),
              )
            : Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(Icons.camera_alt, size: 50, color: Colors.grey[600]),
              ),
        SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(Icons.camera_alt),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade800,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _proceedToPayment,
      child: Text("Proceed to Payment", style: TextStyle(fontSize: 18)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        minimumSize: Size(double.infinity, 50),
        elevation: 5,
      ),
    );
  }
}
