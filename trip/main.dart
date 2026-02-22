import 'package:flutter/material.dart';
import 'package:tripexpense/ticket.dart';
import 'screens/splashscreen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trip Expense Splitter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SafeArea(child: TicketPage()), // Wrap SplashScreen in SafeArea
    );
  }
}
