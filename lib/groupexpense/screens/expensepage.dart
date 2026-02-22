import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExpensesPage extends StatefulWidget {

  const ExpensesPage({Key? key}) : super(key: key);

  @override
  _ExpensesPageState createState() => _ExpensesPageState();
}
class _ExpensesPageState extends State<ExpensesPage> {

  @override
  void initState() {
    super.initState();
    // Proper initialization
  }

  @override
  Widget build(BuildContext context) {
    return Text("expense");
  }


}



