import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  void _proceedToPayment() {
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
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
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
      items: ["Car A", "Car B", "Car C"]
          .map((car) => DropdownMenuItem(value: car, child: Text(car)))
          .toList(),
      onChanged: (value) {
        setState(() {
          selectedCar = value;
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
        onPressed: _proceedToPayment,
        child: Text("Proceed to Payment"),
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
