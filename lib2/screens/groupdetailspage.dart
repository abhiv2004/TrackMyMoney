import 'package:flutter/material.dart';
import 'expensescreen.dart';
import 'balancescreen.dart';

class GroupDetailsPage extends StatefulWidget {
  final int groupId;
  final String groupName;

  const GroupDetailsPage({Key? key, required this.groupId, required this.groupName}) : super(key: key);

  @override
  _GroupDetailsPageState createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.teal.shade200,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: "EXPENSE"),
            Tab(icon: Icon(Icons.account_balance_wallet), text: "BALANCE"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ExpenseScreen(groupId: widget.groupId),
          BalanceScreen(groupId: widget.groupId),
        ],
      ),
    );
  }
}
