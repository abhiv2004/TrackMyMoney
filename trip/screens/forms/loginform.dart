
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripexpense/screens/recoveraccount.dart';
import 'package:tripexpense/utils/colors.dart';
import '../../api_helper/apihelper.dart';
import '../../utils/strings.dart';
import '../../widgets/customsweetalert.dart';
import '../../widgets/navigateWithAnimation.dart';
import '../homescreen.dart';
import '../passwordHelper/forgotpasswordscreen.dart';
import 'registrationform.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _apiService = ApiService();
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _rememberMe = false;
  bool _obscureText = true;
  bool _isLoading = false;


  void _login() async {
    setState(() => _isLoading = true);
    if (_formKey.currentState?.validate() ?? false) {
      String usernameOrEmail = _emailOrUsernameController.text;
      String password = _passwordController.text;

      try {
        final response = await _apiService.loginUser(usernameOrEmail, password);

        if (response['message'] == 'Login successful.') {
          var userData = response['users'][0];
          int userId = userData['userId'];
          String username = userData['userName'];
          String email = userData['email'];
          String mobileNo = userData['mobileNo'];
          String token = response["token"];

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setInt('userId', userId);
          await prefs.setString('username', username);
          await prefs.setString('email', email);
          await prefs.setString('mobileNo', mobileNo);
          await prefs.setString('token', token);
          await prefs.setBool('isLoggedIn', _rememberMe);

          showCustomSweetAlert(context, "Login Successful!", "success", () {
                navigateWithAnimation(context, HomeScreen());
          });
        } else {
          showCustomSweetAlert(context, "Login Failed!", "failure", () {});
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
          // Fullscreen Background Image
          Positioned.fill(
            child: Image.asset(
              AppStrings.background,
              fit: BoxFit.fill,
            ),
          ),
          // Semi-transparent Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          // Login Form inside a Transparent Card
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
                      'Welcome Back!',
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
                          children: [
                            // Username or Email TextField
                            TextFormField(
                              controller: _emailOrUsernameController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.7),
                                hintText: "UserName Or Email",
                                hintStyle: TextStyle(
                                  color: Colors.grey, // Customize label text color
                                  fontSize: 16, // Customize label text size
                                  fontWeight: FontWeight.w500, // Bold label text
                                ),
                                labelText: "Username or Email",
                                labelStyle: TextStyle(
                                  color: Colors.teal, // Customize label text color
                                  fontSize: 16, // Customize label text size
                                  fontWeight: FontWeight.w500, // Bold label text
                                ),
                                prefixIcon: Icon(Icons.person, color: Colors.teal),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.teal),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.teal), // Focused border color
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your username or email';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),

                            // Password TextField
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscureText,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.8),
                                hintText: "Password",
                                hintStyle: TextStyle(
                                  color: Colors.grey, // Customize label text color
                                  fontSize: 16, // Customize label text size
                                  fontWeight: FontWeight.w500, // Bold label text
                                ),
                                labelText: "Password",
                                labelStyle: TextStyle(
                                  color: Colors.teal, // Label text color
                                  fontSize: 16, // Label text size
                                  fontWeight: FontWeight.w500, // Label text boldness
                                ),
                                prefixIcon: Icon(Icons.lock, color: Colors.teal),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureText ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.teal,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureText = !_obscureText;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.teal),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.teal), // New focused color
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: 16),

                            // Remember Me & Forget Password Row
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  activeColor: Colors.teal,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value!;
                                    });
                                  },
                                ),
                                Text(
                                  "Remember Me",
                                  style: TextStyle(
                                    color: Colors.teal, // Customize label text color
                                    fontSize: 16, // Customize label text size
                                    fontWeight: FontWeight.w600, // Bold label text
                                  ),
                                ),
                                Spacer(),
                                TextButton(
                                  onPressed: () {
                                    navigateWithAnimation(context, ForgotPasswordScreen());
                                  },
                                  child: Text(
                                    "Forget Password?",
                                    style: TextStyle(
                                      color: Colors.teal, // Customize label text color
                                      fontSize: 16, // Customize label text size
                                      fontWeight: FontWeight.w600, // Bold label text
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 20),

                            // Login Button
                            ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.buttoncolor2,
                                padding: EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 80,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.buttontextcolor2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            SizedBox(height: 16),

                            // Create Account Link
                            TextButton(
                              onPressed: () {
                                navigateWithAnimation(context, RegistrationScreen());
                              },
                              child: Text(
                                "Don't have an account? Create Account",
                                style: TextStyle(color: Colors.teal),
                              ),
                            ),
                            SizedBox(height: 10),
                            TextButton(
                              onPressed: () {
                                navigateWithAnimation(context, RecoverAccountScreen());
                              },
                              child: Text(
                                "Recover Account",
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

}
