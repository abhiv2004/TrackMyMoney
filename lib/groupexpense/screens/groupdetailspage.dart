import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'alert.dart';
import 'balancepage.dart';
import 'expensepage.dart';

class GroupDetailsPage extends StatefulWidget {
  final int group_id;
  final String? group_name;

  GroupDetailsPage({required this.group_id, this.group_name});

  @override
  _GroupDetailsPageState createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  int _selectedIndex = 0;
  double totalAmount = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadamount();
  }

  Future<void> _loadamount() async {

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.group_name != null
            ? Text(
          widget.group_name!,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )
            : const Text("Group Details"),
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
    ExpensesPage(),
    BalancePage(),
  ];
}

