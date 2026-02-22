import 'package:flutter/material.dart';
import 'package:tripexpense/utils/colors.dart';
import 'package:tripexpense/utils/strings.dart';
import '../../api_helper/apihelper.dart';
import 'passwordresetscreen.dart';

class OTPScreen extends StatefulWidget {
  final String username;
  final String email;

  OTPScreen({required this.username, required this.email});

  @override
  _OTPScreenState createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final int otpLength = 6;
  final List<TextEditingController> controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

  void _verifyOTP() async {
    String otp = controllers.map((c) => c.text).join();

    try {
      final response = await ApiService().verifyOTP(widget.email, otp);

      if (response) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PasswordResetScreen(
              username: widget.username,
              email: widget.email,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid OTP, please try again.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _resendOTP(String username, String email) async {
    try {
      bool otpSent = await ApiService().sendOTP(email);
      if (otpSent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("OTP has been resent successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to resend OTP. Try again!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending OTP: $e')),
      );
    }
  }

  Widget buildOtpTextField(int index) {
    return SizedBox(
      width: 45, // Reduced from 55 to 45
      height: 50, // Reduced slightly
      child: TextField(
        controller: controllers[index],
        focusNode: focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), // Adjusted font size
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.teal, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.teal, width: 3),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < otpLength - 1) {
            FocusScope.of(context).nextFocus();
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).previousFocus();
          }
        },
        onSubmitted: (_) {
          if (index < otpLength - 1) {
            FocusScope.of(context).nextFocus();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Fullscreen Background Image
          Positioned.fill(
            child: Image.asset(
              AppStrings.background,
              fit: BoxFit.fill,
            ),
          ),

          /// Semi-transparent Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),

          /// OTP Form Section
          Center(
            child: Container(
              padding: EdgeInsets.all(24),
              margin: EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 60, color: Colors.teal),
                  SizedBox(height: 10),
                  Text(
                    "Enter the OTP sent to",
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  Text(
                    widget.email,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),

                  /// OTP Fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                        otpLength, (index) => buildOtpTextField(index)),
                  ),
                  SizedBox(height: 30),

                  /// Verify OTP Button
                  ElevatedButton(
                    onPressed: _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttoncolor2,
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text("Verify OTP", style: TextStyle(fontSize: 18,color: AppColors.buttontextcolor2)),
                  ),

                  SizedBox(height: 15),

                  /// Resend OTP Option
                  TextButton(
                    onPressed: () {
                      _resendOTP(widget.username,widget.email);
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Resending OTP...")));
                    },
                    child: Text(
                      "Resend OTP",
                      style: TextStyle(fontSize: 16, color: Colors.teal),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in controllers) controller.dispose();
    for (var node in focusNodes) node.dispose();
    super.dispose();
  }
}
