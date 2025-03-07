import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'payment_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BookingScreen extends StatefulWidget {
  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String? selectedCar;
  DateTime? startDate;
  DateTime? endDate;
  bool _isLoading = false; // Tracks booking state

  final TextEditingController dropOffController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  List<Map<String, dynamic>> availableCars = []; //  Store available cars

  //  Add `fetchAvailableCars()` here
  Future<void> fetchAvailableCars() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var uri = Uri.parse(
          "http://localhost:5000/api/cars"); // ✅ Update with actual API endpoint
      var response = await http.get(uri);

      if (response.statusCode == 200) {
        List<dynamic> carList = jsonDecode(response.body);

        setState(() {
          availableCars = carList
              .map((car) => {
                    "id": car["_id"],
                    "name":
                        "${car["marque"]} - ${car["matricule"]}", // ✅ Display brand & plate number
                  })
              .toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to load available cars.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: Unable to load cars.")));
    }

    setState(() {
      _isLoading = false;
    });
  }

  //  Call fetchAvailableCars() when the screen loads
  @override
  void initState() {
    super.initState();
    fetchAvailableCars(); // Fetch cars on screen open
  }

  // Add `_buildSectionTitle()` here
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  String formatDate(DateTime? date) {
    return date != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(date)
        : "Select Date";
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

  void _proceedToPayment() async {
    if (selectedCar == null ||
        startDate == null ||
        endDate == null ||
        dropOffController.text.isEmpty ||
        fullNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please complete all fields!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token"); // ✅ Retrieve saved token
      String? userId = prefs.getString("userId"); // ✅ Get logged-in user ID

      if (token == null || userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Session expired. Please log in again.")),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      var uri = Uri.parse("http://localhost:5000/api/bookings");
      var response = await http.post(
        uri,
        headers: {
          "Authorization": "Bearer $token", // ✅ Secure API with token
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "id_user": userId, // ✅ Correct user reference
          "id_car": selectedCar, // ✅ Correct car reference
          "date_hour_booking": startDate!.toIso8601String(),
          "date_hour_expire": endDate!.toIso8601String(),
          "location_After_Renting": dropOffController.text,
          "fullName": fullNameController.text,
          "status": "pending", // ✅ Default status
          "paiement": 0 // ✅ Default payment amount
        }),
      );

      if (response.statusCode == 201) {
        var responseData = jsonDecode(response.body);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Booking confirmed! Proceeding to payment.")),
        );

        // ✅ Navigate to Payment Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              selectedCar: selectedCar!,
              startDate: startDate!,
              endDate: endDate!,
              dropOffLocation: dropOffController.text,
              fullName: fullNameController.text,
              paymentMethod: "Not Selected Yet",
            ),
          ),
        );
      } else {
        var errorResponse = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Booking failed: ${errorResponse['error']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: Unable to process booking.")),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildTextField(
      TextEditingController controller, String hintText, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildCarSelector() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        hintText: "Select a car",
      ),
      value: selectedCar,
      items: availableCars.map((car) {
        return DropdownMenuItem<String>(
          value: car["id"].toString(), //  Ensure ID is a String
          child: Text(car["name"]), //  Display car name
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedCar = value; // Store selected car ID
        });
      },
    );
  }

  Widget _buildDateSelector(BuildContext context) {
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

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            _isLoading ? null : _proceedToPayment, // ✅ Disable when loading
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white) // ✅ Show loader
            : Text("Proceed to Payment"),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
                        SizedBox(height: 30),
                        _buildSubmitButton(),
                      ],
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
}
