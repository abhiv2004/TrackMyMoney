import 'package:billtracker/homepage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to Portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bill Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SafeArea(child: const SplashScreen()),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _splashDuration = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    Future.delayed(_splashDuration, () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) =>  Homepage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Responsive sizes
    final double iconSize = size.width * 0.22; // 22% of screen width
    final double titleFontSize = size.width * 0.07; // 7% of screen width

    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icon.png',
              width: iconSize,
              height: iconSize,
            ),
            SizedBox(height: size.height * 0.02),
            Text(
              "Track My Money",
              style: TextStyle(
                fontSize: titleFontSize,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: size.height * 0.04),
          ],
        ),
      ),
    );
  }
}
