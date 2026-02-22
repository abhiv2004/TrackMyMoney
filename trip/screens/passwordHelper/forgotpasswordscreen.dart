import 'package:flutter/material.dart';
import 'package:tripexpense/utils/colors.dart';
import '../../api_helper/apihelper.dart';
import '../../utils/strings.dart';
import '../../widgets/customsweetalert.dart';
import '../../widgets/navigateWithAnimation.dart';
import 'otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _usernameOrEmailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  List<Map<String, dynamic>> _accounts = [];

  void _submitUsername() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    String usernameOrEmail = _usernameOrEmailController.text;

    try {
      List<Map<String, dynamic>> users = await ApiService().findAccount(usernameOrEmail);
      if (users.isNotEmpty) {
        setState(() => _accounts = users);
      } else {
        showCustomSweetAlert(context, "User not found.", "warning", () {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _selectAccount(Map<String, dynamic> user) async {
    String username = user['userName'];
    String email = user['email'];

    try {
      bool otpSent = await ApiService().sendOTP(email);
      if (otpSent) {
        navigateWithAnimation(context, OTPScreen(username: username, email: email));
      } else {
        showCustomSweetAlert(context, "Otp Not Sent!", "failure", () {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending OTP: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(AppStrings.background, fit: BoxFit.fill),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Forgot Password',
                        style: TextStyle(
                          color: Colors.teal.shade800,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _usernameOrEmailController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.7),
                          labelText: 'Username or Email',
                          prefixIcon: Icon(Icons.person, color: Colors.teal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Enter username or email' : null,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitUsername,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttoncolor2,
                          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 80),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: Text('Submit', style: TextStyle(fontSize: 16,color: AppColors.buttontextcolor2, fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(height: 20),
                      if (_accounts.isNotEmpty) ...[
                        Text("Select your account:", style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: _accounts.length,
                          itemBuilder: (context, index) {
                            var user = _accounts[index];
                            return Card(
                              elevation: 3,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.teal, // Background color for the circle
                                  child: Icon(Icons.person, color: Colors.white), // User icon inside the circle
                                ),
                                title: Text(user['userName']),
                                subtitle: Text(user['email']),
                                trailing: Icon(Icons.arrow_forward_ios, color: Colors.teal),
                                onTap: () => _selectAccount(user),
                              ),
                            );


                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white, backgroundColor: Colors.grey, strokeWidth: 5.0),
              ),
            ),
        ],
      ),
    );
  }
}
