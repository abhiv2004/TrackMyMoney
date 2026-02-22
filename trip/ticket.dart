import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'dart:async'; // For countdown timer
import 'package:flutter/widgets.dart'; // For the zoom animation


class TicketPage extends StatefulWidget {
  @override
  _TicketPageState createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> with TickerProviderStateMixin {
  // Variables for DateTime and countdown timer
  DateTime _bookingTime = DateTime.now();
  late String _formattedDate;
  late String _formattedStartTime = "06:46 AM";
  late String _formattedEndTime = "11:59 PM";
  late String _formattedTime;
  late String todayDate;
  late Duration _timeRemaining;
  Color myColor = Color.fromRGBO(202, 224, 252, 1.0);


  late AnimationController _zoomController;
  late Animation<double> _zoomAnimation;
  @override
  void initState() {
    super.initState();

    _bookingTime = DateTime.now();
    _formattedDate = DateFormat('dd MMM, yy').format(_bookingTime);
    todayDate = DateFormat("ddMMyy").format(_bookingTime);
    _formattedTime = DateFormat('hh:mm a').format(_bookingTime);

    // Parse start & end time for today
    DateTime now = DateTime.now();
    DateTime startTime = DateFormat("hh:mm a").parse(_formattedStartTime);
    DateTime endTime = DateFormat("hh:mm a").parse(_formattedEndTime);

    // Attach today's date to parsed times
    startTime = DateTime(now.year, now.month, now.day, startTime.hour, startTime.minute);
    endTime = DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);

    // If endTime is before startTime, assume it is next day (e.g. crossing midnight)
    if (endTime.isBefore(startTime)) {
      endTime = endTime.add(Duration(days: 1));
    }

    // Remaining time = end - now
    _timeRemaining = endTime.difference(now);

    // 🔹 Timer for countdown
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timeRemaining.inSeconds > 0) {
        setState(() {
          _timeRemaining = _timeRemaining - Duration(seconds: 1);
        });
      } else {
        timer.cancel(); // stop timer when time is up
      }
    });

    // 🔹 Animation for zooming logo
    _zoomController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _zoomAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(_zoomController);
  }

  @override
  void dispose() {
    _zoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Container(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.close, color: Colors.black),
                  Text(
                    'All passes',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline, // 👈 underline added
                    ),
                  ),

                ],
              ),
            ),
            SizedBox(height: 30,),
            Padding(
              padding: EdgeInsets.fromLTRB(10, 100, 10, 10),
              child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    //crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rajkot Rajpath Ltd Section
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          color: Colors.red,
                        ),
                        child: Center(
                          child: Text(
                            'Rajkot Rajpath Ltd',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(

                          children: [
                            // 🔹 Left Column → ID + Name
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ID',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'ABHISHEKKUMAR',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(width: 50,),

                            // 🔹 Right Column → Fare + Amount
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fare',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '₹25',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),



                      Stack(
                        clipBehavior: Clip.none, // important to allow overflow
                        children: [
                          // Dashed line
                          Container(
                            width: double.infinity,
                            child: Center(
                              child: Text(
                                '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          // Small circles positioned half outside the container
                          Positioned(
                            left: -18, // half width goes outside
                            top: -6,   // adjust vertically
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Color(0xFFCAE0FC), // same as background
                                shape: BoxShape.circle,
                              ),
                            ),
                          ), Positioned(
                            right: -18, // half width goes outside
                            top: -6,   // adjust vertically
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Color(0xFFCAE0FC), // same as background
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),


                      SizedBox(height: 16),

                      // Booking Time and Validity Time
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20 ,0,20,0),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Booking Time',
                                  style: TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                                Text(
                                  '$_formattedDate | $_formattedStartTime',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                              
                            ),

                            SizedBox(width: 50,),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Validity Time',
                                  style: TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                                Text(
                                  '$_formattedDate | $_formattedEndTime',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),

                      Center(
                        child: Text(
                          "${todayDate}0646CYTSOS",
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Pass Type
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.red,
                        ),
                        child: Center(
                          child: Text(
                            'One Day Pass',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Logo with zoom effect
                      Center(
                        child: AnimatedBuilder(
                          animation: _zoomController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _zoomAnimation.value,
                              child: Image.asset(
                                'assets/images/ticket.png', // Add the correct path for the logo
                                width: 150,
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          color: Colors.grey.shade100,
                        ),
                        child: Center(
                          child: Text(
                            'Expires in ${_timeRemaining.inHours}:${_timeRemaining.inMinutes.remainder(60)}:${_timeRemaining.inSeconds.remainder(60)}',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
            ),
          ],
        ),
      ),
    );
  }
}


class DottedLinePainter extends CustomPainter {
  final double dashWidth;
  final double dashSpace;
  final Color color;

  DottedLinePainter({this.dashWidth = 5, this.dashSpace = 3, this.color = Colors.grey});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    double startX = 0;
    final y = size.height / 2;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

