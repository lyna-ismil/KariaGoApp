import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kariago/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'payment_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BookingScreen extends StatefulWidget {
  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String? selectedCar;
  DateTime? startDate;
  DateTime? endDate;
  bool _isLoading = false;
  double? estimatedPrice;

  final TextEditingController pickupLocationController =
      TextEditingController();
  final TextEditingController dropOffController = TextEditingController();
  final TextEditingController estimatedDropOffController =
      TextEditingController();

  List<Map<String, dynamic>> availableCars = [];

  @override
  void initState() {
    super.initState();
    fetchAvailableCars();
  }

  Future<void> fetchAvailableCars() async {
    setState(() => _isLoading = true);
    try {
      List<dynamic> cars = await ApiService.getAllCars();
      setState(() {
        availableCars = cars
            .map((car) => {
                  "id": car["_id"],
                  "name": "${car["marque"]} - ${car["matricule"]}",
                })
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load cars.")),
      );
    }
    setState(() => _isLoading = false);
  }

  String formatDate(DateTime? date) {
    return date != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(date)
        : "Select Date";
  }

  Future<void> _pickDateTime(BuildContext context, bool isStart) async {
    DateTime now = DateTime.now();
    DateTime initialDate = isStart ? now : (startDate ?? now);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(pickedDate),
      );

      if (pickedTime != null) {
        DateTime finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isStart) {
            startDate = finalDateTime;
            endDate = null;
          } else {
            endDate = finalDateTime;
          }
        });
      }
    }
  }

  Future<void> _estimatePrice() async {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select start and end dates.")),
      );
      return;
    }

    int bookingHour = startDate!.hour;
    int bookingDayOfWeek = startDate!.weekday;
    int bookingMonth = startDate!.month;
    int isPeakHour = (bookingHour >= 17 && bookingHour <= 20) ? 1 : 0;
    int isWeekend = (bookingDayOfWeek == 6 || bookingDayOfWeek == 7) ? 1 : 0;
    double totalDuration = endDate!.difference(startDate!).inMinutes / 60.0;
    int durationDays = endDate!.difference(startDate!).inDays;
    int bookingCount = 3; // placeholder value
    double driveBehaviorScore = 4.5; // placeholder value

    final uri = Uri.parse("http://127.0.0.1:8000/predict");
    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "booking_hour": bookingHour,
        "booking_day_of_week": bookingDayOfWeek,
        "booking_month": bookingMonth,
        "is_peak_hour": isPeakHour,
        "is_weekend": isWeekend,
        "total_duration_hours": totalDuration,
        "duration_days": durationDays,
        "booking_count": bookingCount,
        "drive_behavior_score": driveBehaviorScore
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        estimatedPrice = data["estimated_cost"];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to estimate price.")),
      );
    }
  }

  Widget _buildSubmitButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _estimatePrice,
            child: Text("Estimate Price"),
          ),
        ),
        if (estimatedPrice != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
                "Estimated Price: \$${estimatedPrice!.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Book a Car")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildCarSelector(),
            SizedBox(height: 20),
            _buildDateSelector(),
            SizedBox(height: 20),
            _buildTextField(pickupLocationController, "Pickup Location",
                Icons.location_on_outlined),
            SizedBox(height: 10),
            _buildTextField(estimatedDropOffController, "Estimated Drop-Off",
                Icons.location_searching),
            SizedBox(height: 10),
            _buildTextField(
                dropOffController, "Final Drop-Off", Icons.location_on),
            SizedBox(height: 30),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildCarSelector() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        hintText: "Select a Car",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      value: selectedCar,
      items: availableCars.map((car) {
        return DropdownMenuItem<String>(
          value: car["id"],
          child: Text(car["name"]),
        );
      }).toList(),
      onChanged: (value) => setState(() => selectedCar = value),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _pickDateTime(context, true),
            child: Text(formatDate(startDate)),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed:
                startDate == null ? null : () => _pickDateTime(context, false),
            child: Text(formatDate(endDate)),
          ),
        ),
      ],
    );
  }
}
