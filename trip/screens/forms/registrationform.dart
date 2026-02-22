import 'package:flutter/material.dart';
import 'package:tripexpense/screens/forms/loginform.dart';
import '../../api_helper/apihelper.dart';
import '../../utils/strings.dart';
import '../../widgets/customsweetalert.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _mobileController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;
  bool _obscureConfirmText = true;

  void _register() async {
    setState(() => _isLoading = true);
    if (_formKey.currentState?.validate() ?? false) {
      String username = _usernameController.text;
      String email = _emailController.text;
      String password = _passwordController.text;
      String mobile = _mobileController.text;

      try {
        final response =
        await _apiService.registerUser(username, email, password, mobile);

        if (response['message'] == 'Registration is Successful.') {
          showCustomSweetAlert(context, "Registration is Successful!", "success", () {
            Navigator.pop(context);
          });

        } else {
          showCustomSweetAlert(context, "Registration Failed", "failure", () {
            Navigator.pop(context);
          });
        }
      } catch (e) {
        showCustomSweetAlert(context, "Error: $e", "warning", () {});
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              AppStrings.background,
              fit: BoxFit.fill,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          // Form and Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85), // Adjusted opacity for transparency
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

                    SizedBox(height: 20),
                    Text(
                      'Welcome!',
                      style: TextStyle(
                        color: Colors.teal.shade800,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 30),
                    Theme(
                      data: Theme.of(context).copyWith(
                        inputDecorationTheme: InputDecorationTheme(
                          errorStyle: TextStyle(color: Colors.red),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [

                            TextFormField(
                              controller: _usernameController,
                              decoration: _inputDecoration("Username", Icons.person),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your username';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: _inputDecoration("Email", Icons.email),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
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
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _mobileController,
                              decoration:
                              _inputDecoration("Mobile Number", Icons.phone),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your mobile number';
                                }
                                if (value.length < 10) {
                                  return 'Please enter a valid mobile number';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _register,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 80,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                backgroundColor: Colors.teal,
                              ),
                              child: Text(
                                "Register",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            TextButton(
                              onPressed:() => _navigateWithAnimation(context, LoginScreen()),
                              child: Text(
                                "Already have an account? Login",
                                style: TextStyle(color: Colors.teal),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Divider(
                      color: Colors.grey,
                      thickness: 1.2,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // White background for Google button
                        padding: EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(color: Colors.grey.shade100), // Border color
                        ),
                        elevation: 3,
                      ),
                      icon: Icon(Icons.g_mobiledata, color: Colors.red, size: 24),
                      label: Text(
                        "Continue with Google",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87, // Dark text for contrast
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54, // Semi-transparent background
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white,backgroundColor: Colors.grey,strokeWidth:5.0,),
              ),
            ),
        ],
      ),
    );
  }

  void _navigateWithAnimation(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
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
}
