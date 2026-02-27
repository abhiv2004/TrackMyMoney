import 'package:flutter/material.dart';
import '../database/group_expense_db.dart';
import '../utils/colors.dart';
import 'group_form_screen.dart';
import 'group_expense_page.dart';
import 'group_balance_page.dart';

class GroupDetailsPage extends StatefulWidget {
  final int groupId;
  final String? groupName;

  const GroupDetailsPage({
    Key? key,
    required this.groupId,
    this.groupName,
  }) : super(key: key);

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  int _selectedIndex = 0;
  double totalAmount = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTotalAmount();
  }

  // ===============================
  // LOAD TOTAL EXPENSE AMOUNT
  // ===============================
  Future<void> _loadTotalAmount() async {
    final expenses = await GroupExpenseDB.instance
        .getExpensesByGroupId(widget.groupId);

    setState(() {
      totalAmount = expenses.fold(
        0.0,
        (sum, expense) => sum + expense['amount'],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.groupName != null
            ? Text(
                widget.groupName!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : const Text("Group Details"),
        centerTitle: true,
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              if (totalAmount > 0.0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        "Cannot edit group after expenses added"),
                  ),
                );
              } else {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        GroupFormScreen(groupId: widget.groupId),
                  ),
                );
                _loadTotalAmount();
              }
            },
          ),
        ],
      ),

      // ===============================
      // BODY
      // ===============================
      body: _pages[_selectedIndex],

      // ===============================
      // BOTTOM NAVIGATION
      // ===============================
      bottomNavigationBar: BottomNavigationBar(
        items: const [
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
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  // ===============================
  // PAGES
  // ===============================
  List<Widget> get _pages => [
        GroupExpensePage(groupId: widget.groupId),
        GroupBalancePage(groupId: widget.groupId),
      ];
}