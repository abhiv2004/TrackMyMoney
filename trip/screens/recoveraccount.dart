import 'package:flutter/material.dart';
import 'package:tripexpense/screens/forms/loginform.dart';
import 'package:tripexpense/screens/passwordHelper/otp_screen.dart';
import 'package:tripexpense/utils/colors.dart';
import '../../api_helper/apihelper.dart';
import '../../utils/strings.dart';
import '../../widgets/customsweetalert.dart';
import '../../widgets/navigateWithAnimation.dart';

class RecoverAccountScreen extends StatefulWidget {
  @override
  _RecoverAccountScreenScreenState createState() => _RecoverAccountScreenScreenState();
}

class _RecoverAccountScreenScreenState extends State<RecoverAccountScreen> {
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
        for(var user in users){
          if(user["isActive"] == false){
            _accounts.add(user);
          }
        }
        setState(() => {});
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
    int userId = user['userId'];
    String userName = user['userName'];

    try {
      navigateWithAnimation(context, PasswordRecoveryScreen(userId: userId,username : userName));


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
                        'Recover Account',
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


class PasswordRecoveryScreen extends StatefulWidget {
  final int userId;
  final String username;

  PasswordRecoveryScreen({required this.userId,required this.username});

  @override
  _PasswordRecoveryScreenState createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureText = true;
  bool _isLoading = false;

  void _recoverAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    bool success = await ApiService().recoverAccount(widget.userId, widget.username, _passwordController.text);

    if (success) {
      showCustomSweetAlert(context, "Account recovered successfully!", "success", () {
        navigateWithAnimation(context, LoginScreen());
      });
    } else {
      showCustomSweetAlert(context, "Invalid username or password!", "error", () {});
    }

    setState(() => _isLoading = false);
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
                        'Password of Account',
                        style: TextStyle(
                          color: Colors.teal.shade800,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
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

                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _recoverAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttoncolor2,
                          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 80),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: Text('Recover Account', style: TextStyle(fontSize: 16, color: AppColors.buttontextcolor2, fontWeight: FontWeight.bold)),
                      ),
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
    return Scaffold(
      appBar: AppBar(title: Text("Recover Account")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) =>
                value == null || value.length < 6 ? 'Enter at least 6 characters' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _recoverAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttoncolor2,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 80),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text('Recover Account', style: TextStyle(fontSize: 16, color: AppColors.buttontextcolor2, fontWeight: FontWeight.bold)),
              ),
              if (_isLoading) SizedBox(height: 20, child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}
