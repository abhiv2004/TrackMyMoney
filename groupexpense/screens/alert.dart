import 'package:flutter/material.dart';

void showCustomSweetAlert(BuildContext context, String message, String type, VoidCallback onDismiss) {
  Color bgColor;
  IconData iconData;

  switch (type) {
    case 'success':
      bgColor = Colors.green;
      iconData = Icons.check_circle;
      break;
    case 'failure':
      bgColor = Colors.red;
      iconData = Icons.error;
      break;
    case 'warning':
      bgColor = Colors.blue;
      iconData = Icons.info;
      break;
    default:
      bgColor = Colors.grey;
      iconData = Icons.warning;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      Future.delayed(const Duration(seconds: 1), () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // Close alert
          onDismiss(); // Call the function after alert dismissal
        }
      });

      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconData, color: bgColor, size: 60),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void showCustomAlert(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          "Information",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info, color: Colors.blue, size: 50),
            SizedBox(height: 10),
            Text(
              "Hello User,\n You can not update this trip\n because your expense is started.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("OK", style: TextStyle(color: Colors.blue)),
          ),
        ],
      );
    },
  );
}