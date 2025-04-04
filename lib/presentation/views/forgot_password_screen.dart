import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kariago/services/api_service.dart'; 
import 'package:lottie/lottie.dart';
import './widgets/custom_text_field.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  late AnimationController _lottieController;
  int _currentStep = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  void _nextStep() async {
    if (_currentStep == 0 && _formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response =
            await ApiService.resetPassword(_emailController.text.trim());

        print(" Password Reset Request Sent: $response");

        setState(() {
          _isLoading = false;
          _currentStep++;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(response["message"] ??
                "Check your email for reset instructions")));

        _lottieController.forward(); //  Play animation when email is sent
      } catch (e) {
        print(" Password Reset Failed: $e");
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Failed to send reset email. Please try again.")));
      }
    } else if (_currentStep == 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E88E5), Color(0xFF64B5F6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            "Password Recovery",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 48), // To balance the layout
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildContent() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          )
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStepIndicator(),
            SizedBox(height: 30),
            _buildStepContent(),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 300.ms)
        .scale(begin: Offset(0.8, 0.8), end: Offset(1, 1));
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          width: 12,
          height: 12,
          margin: EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentStep >= index
                ? Color(0xFF6A11CB)
                : Colors.grey.shade300,
          ),
        )
            .animate(target: _currentStep >= index ? 1 : 0)
            .scale(begin: Offset(0.8, 0.8), end: Offset(1, 1))
            .fadeIn();
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildEmailStep();
      case 1:
        return _buildVerificationStep();
      case 2:
        return _buildSuccessStep();
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildEmailStep() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Lottie.network(
            'https://assets10.lottiefiles.com/packages/lf20_uwR49r.json',
            width: 200,
            height: 200,
          ),
          SizedBox(height: 20),
          Text(
            "Let's recover your password",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          CustomTextField(
            controller: _emailController,
            hintText: "Enter your email",
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          SizedBox(height: 20),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildVerificationStep() {
    return Column(
      children: [
        Lottie.network(
          'https://assets3.lottiefiles.com/packages/lf20_q7hiluze.json',
          controller: _lottieController,
          onLoaded: (composition) {
            _lottieController
              ..duration = composition.duration
              ..forward();
          },
          width: 200,
          height: 200,
        ),
        SizedBox(height: 20),
        Text(
          "Check your email",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          "We've sent a password reset link to ${_emailController.text}",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 20),
        _buildNextButton(text: "I've reset my password"),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      children: [
        Lottie.network(
          'https://assets2.lottiefiles.com/packages/lf20_jbrw3hcz.json',
          width: 200,
          height: 200,
          repeat: false,
        ),
        SizedBox(height: 20),
        Text(
          "Password Reset Successful!",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          "Your password has been successfully reset. You can now log in with your new password.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          },
          child: Text("Back to Login"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF1E88E5),
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton({String text = "Next"}) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _nextStep,
      child: _isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(text, style: TextStyle(fontSize: 18)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF1E88E5),
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }
}
