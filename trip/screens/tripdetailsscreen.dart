import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tripexpense/screens/pages.dart';
import 'package:tripexpense/widgets/navigateWithAnimation.dart';
import '../api_helper/apihelper.dart';
import '../models/tripdetailsdatamodel.dart';
import '../utils/colors.dart';
import '../widgets/customsweetalert.dart';
import 'forms/tripformscreen.dart';

class TripDetailsPage extends StatefulWidget {
  final int tripId;
  final String? tripName;

  TripDetailsPage({required this.tripId, this.tripName});

  @override
  _TripDetailsPageState createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  int _selectedIndex = 0;
  double totalAmount = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadamount();
  }

  Future<void> _loadamount() async {
    final expenses = await ApiService().fetchExpensesByTripId(widget.tripId);
    setState(() {
      totalAmount = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.tripName != null
            ? Text(
          widget.tripName!,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )
            : const Text("Trip Details"),
        centerTitle: true,
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context,true);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              if (totalAmount > 0.0) {
                showCustomAlert(context);
              } else {
                setState(() => _isLoading = true);
                TripDetailsData? tripsdetail =
                await ApiService().fetchTripDetailsData(widget.tripId);
                slideFromTop(context, AddEditTripForm(tripDetails: tripsdetail));
                setState(() => _isLoading = false);
              }
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.money),
            label: 'Expense',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.balance),
            label: 'Balance',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      bottomSheet: BottomSheet(onClosing: () {

      }, builder: (context) {
        return Text("hello");
      },),
    );
  }

  List<Widget> get _pages => [
    ExpensesPage(tripId: widget.tripId),
    BalancePage(tripId: widget.tripId),
  ];
}

