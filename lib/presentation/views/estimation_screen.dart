import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../services/api_service.dart';
import 'booking_screen.dart';

class EstimationScreen extends StatefulWidget {
  @override
  _EstimationScreenState createState() => _EstimationScreenState();
}

class _EstimationScreenState extends State<EstimationScreen> {
  final _formKey = GlobalKey<FormState>();

  double bookingHour = 14;
  int bookingDayOfWeek = 5;
  int bookingMonth = 5;
  bool isPeakHour = false;
  bool isWeekend = false;
  double totalDurationHours = 3.5;
  int durationDays = 1;
  int bookingCount = 2;
  double driveBehaviorScore = 4.5;

  double? estimatedCost;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDriveScore();
  }

  Future<void> _loadDriveScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString("userId");
    if (userId != null) {
      try {
        final profile = await ApiService.getUserProfile(userId);
        setState(() {
          driveBehaviorScore =
              double.tryParse(profile["drive_score"].toString()) ?? 4.0;
          bookingCount = profile["nbr_fois_allocation"] ?? 2;
        });
      } catch (e) {
        print("Failed to fetch drive score: $e");
      }
    }
  }

  Future<void> _estimateCost() async {
    setState(() => isLoading = true);

    final url = Uri.parse("http://10.0.2.2:8000/predict");
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

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          estimatedCost = result['estimated_cost'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to estimate cost')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: ensure FastAPI is running')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Estimation")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text("Fill in booking details:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              _buildSlider("Booking Hour", bookingHour, 0, 23,
                  (val) => setState(() => bookingHour = val)),
              _buildIntDropdown("Day of Week (0=Mon)", bookingDayOfWeek, 0, 6,
                  (val) => setState(() => bookingDayOfWeek = val)),
              _buildIntDropdown("Booking Month", bookingMonth, 1, 12,
                  (val) => setState(() => bookingMonth = val)),
              SwitchListTile(
                  title: Text("Peak Hour?"),
                  value: isPeakHour,
                  onChanged: (val) => setState(() => isPeakHour = val)),
              SwitchListTile(
                  title: Text("Weekend?"),
                  value: isWeekend,
                  onChanged: (val) => setState(() => isWeekend = val)),
              _buildSlider("Total Duration (Hours)", totalDurationHours, 0.5,
                  24, (val) => setState(() => totalDurationHours = val)),
              _buildIntDropdown("Duration Days", durationDays, 1, 10,
                  (val) => setState(() => durationDays = val)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : _estimateCost,
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Estimate Price"),
              ),
              SizedBox(height: 20),
              if (estimatedCost != null)
                Column(
                  children: [
                    Text(
                        "Estimated Cost: \$${estimatedCost!.toStringAsFixed(2)}",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => BookingScreen()));
                      },
                      child: Text("Start Booking"),
                    )
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max,
      Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: ${value.toStringAsFixed(1)}"),
        Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            label: value.toStringAsFixed(1),
            onChanged: onChanged),
      ],
    );
  }

  Widget _buildIntDropdown(String label, int currentValue, int min, int max,
      Function(int) onChanged) {
    return DropdownButtonFormField<int>(
      value: currentValue,
      decoration: InputDecoration(labelText: label),
      items: List.generate(max - min + 1, (i) => min + i)
          .map((val) =>
              DropdownMenuItem(value: val, child: Text(val.toString())))
          .toList(),
      onChanged: (val) => onChanged(val ?? currentValue),
    );
  }
}
