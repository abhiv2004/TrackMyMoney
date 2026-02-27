import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/groupdatabase.dart';
import 'expenseform.dart';

class ExpenseScreen extends StatefulWidget {
  final int groupId;
  const ExpenseScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  _ExpenseScreenState createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshExpenses();
  }

  Future<void> _refreshExpenses() async {
    setState(() => _isLoading = true);
    final data = await GroupExpenseDB.instance.getExpensesByGroupId(widget.groupId);
    setState(() {
      _expenses = data;
      _isLoading = false;
    });
  }

  void _deleteExpense(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Expense"),
        content: const Text("Are you sure you want to delete this expense?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await GroupExpenseDB.instance.deleteExpense(id);
      _refreshExpenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expenses.isEmpty
              ? const Center(child: Text("No expenses yet. Add one!"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _expenses.length,
                  itemBuilder: (context, index) {
                    final exp = _expenses[index];
                    return Dismissible(
                      key: Key(exp['expense_id'].toString()),
                      background: Container(
                        color: Colors.blue,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: const Icon(Icons.edit, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ExpenseForm(groupId: widget.groupId, expenseId: exp['expense_id'])),
                          );
                          _refreshExpenses();
                          return false;
                        } else {
                          _deleteExpense(exp['expense_id']);
                          return false;
                        }
                      },
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(exp['expense_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(DateFormat('dd MMM yyyy').format(DateTime.parse(exp['expense_date']))),
                          trailing: Text("₹${exp['amount'].toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => ExpenseForm(groupId: widget.groupId)));
          _refreshExpenses();
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add_shopping_cart, color: Colors.white),
      ),
    );
  }
}
