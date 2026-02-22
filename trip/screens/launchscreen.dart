import 'package:flutter/material.dart';
import 'package:tripexpense/screens/forms/loginform.dart';
import 'package:tripexpense/screens/forms/registrationform.dart';
import 'package:tripexpense/utils/colors.dart';
import 'package:tripexpense/utils/strings.dart';
import '../widgets/navigateWithAnimation.dart';

class LaunchFirstScreen extends StatelessWidget {
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

          // Dark Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),

          // Bottom Buttons
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildButton(
                  text: "Login",
                  color: AppColors.buttoncolor2,
                  onPressed: () => navigateWithAnimation(context, LoginScreen()),
                ),
                SizedBox(height: 10),
                _buildButton(
                  text: "Register",
                  color: Colors.green,
                  onPressed: () => navigateWithAnimation(context, RegistrationScreen()),
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    // Navigate to Guest Mode or Help Screen (To be implemented)
                  },
                  child: Text(
                    "Continue as Guest",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Help or About Us Screen (To be implemented)
                  },
                  child: Text(
                    "Need Help?",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({required String text, required Color color, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 80),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 16, color: AppColors.buttontextcolor2, fontWeight: FontWeight.bold),
      ),
    );
  }

}
