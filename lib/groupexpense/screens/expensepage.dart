import 'package:flutter/material.dart';
import '../database/group_expense_db.dart';
import '../models/group_expense_model.dart';
import '../models/group_participant_model.dart';

class GroupExpensesPage extends StatefulWidget {
  final int groupId;

  const GroupExpensesPage({required this.groupId, Key? key})
      : super(key: key);

  @override
  State<GroupExpensesPage> createState() => _GroupExpensesPageState();
}

class _GroupExpensesPageState extends State<GroupExpensesPage> {
  List<GroupExpenseModel> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final data = await GroupExpenseDB.instance
        .fetchExpensesByGroupId(widget.groupId);

    setState(() {
      _expenses = data;
      _isLoading = false;
    });
  }

  Future<void> _deleteExpense(int expenseId) async {
    await GroupExpenseDB.instance
        .deleteExpenseWithSplit(expenseId);

    _loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_expenses.isEmpty) {
      return const Center(child: Text("No Expenses Found"));
    }

    return ListView.builder(
      itemCount: _expenses.length,
      itemBuilder: (context, index) {
        final expense = _expenses[index];

        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(expense.expenseName),
            subtitle: Text("Paid by: ${expense.paidBy}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "₹ ${expense.amount.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteExpense(expense.expenseId!),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}