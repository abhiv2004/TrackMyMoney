import 'package:flutter/material.dart';
import 'package:tripexpense/screens/forms/loginform.dart';
import 'package:tripexpense/utils/colors.dart';
import 'package:tripexpense/utils/strings.dart';

import '../../api_helper/apihelper.dart';
import '../../widgets/customsweetalert.dart';
import '../../widgets/navigateWithAnimation.dart';

class PasswordResetScreen extends StatefulWidget {
  final String username;
  final String email;

  PasswordResetScreen({required this.username, required this.email});

  @override
  _PasswordResetScreenState createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureText = true;
  bool _obscureConfirmText = true;

  void _resetPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      String newPassword = _newPasswordController.text;
      String confirmPassword = _confirmPasswordController.text;

      if (newPassword != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }

      try {
        final response = await ApiService().resetPassword(widget.username, widget.email, newPassword);

        if (response) {
          showCustomSweetAlert(context, "Password Changed Successfully!", "success", () {
            navigateWithAnimation(context, LoginScreen());
          });
        } else {
          showCustomSweetAlert(context, "Password Change Failed!", "failure", () {});
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
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

          /// Password Reset Form
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
                  Icon(Icons.lock_reset_outlined, size: 60, color: Colors.teal),
                  SizedBox(height: 10),
                  Text(
                    "Reset Your Password",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                  ),
                  SizedBox(height: 20),

                  /// Password Input Fields
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscureText,
                          decoration: _inputDecoration(
                            "Password",
                            Icons.lock,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.teal,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters long';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmText,
                          decoration: _inputDecoration(
                            "Confirm Password",
                            Icons.lock,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmText
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.teal,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmText = !_obscureConfirmText;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),

                  /// Reset Password Button
                  ElevatedButton(
                    onPressed: _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttoncolor2,
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text("Reset Password", style: TextStyle(fontSize: 18, color: AppColors.buttontextcolor2)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon,
      {Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.8),
      hintText: label,
      hintStyle: TextStyle(
        color: Colors.grey, // Customize label text color
        fontSize: 16, // Customize label text size
        fontWeight: FontWeight.w500, // Bold label text
      ),
      labelText: label,
      labelStyle: TextStyle(color: Colors.teal),
      prefixIcon: Icon(icon, color: Colors.teal),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.teal),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
