import 'package:flutter/material.dart';
import '../database/personaldatabase.dart';
import '../models/expense_model.dart';
import 'dashboard.dart';
import 'expense_form_dialog.dart';
import 'expensetile.dart';
import 'reportpage.dart';

class PersonalExpensePage extends StatefulWidget {
  const PersonalExpensePage({super.key});

  @override
  State<PersonalExpensePage> createState() => _PersonalExpensePageState();
}

class _PersonalExpensePageState extends State<PersonalExpensePage> {
  List<Expense> expenses = [];
  double totalExpense = 0;
  double monthExpense = 0;

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    final allExpenses = await MyPersonalExpenseDB.instance.getExpenses();
    final now = DateTime.now();

    List<Expense> currentYear = [];
    List<Expense> currentMonth = [];

    for (var e in allExpenses) {
      final date = DateTime.parse(e.date);
      if (date.year == now.year) {
        currentYear.add(e);
        if (date.month == now.month) currentMonth.add(e);
      }
    }

    setState(() {
      expenses = currentMonth;
      totalExpense =
          currentYear.fold(0, (sum, e) => sum + e.amount);
      monthExpense =
          currentMonth.fold(0, (sum, e) => sum + e.amount);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _buildAddButton(),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xff1f1c2c), Color(0xff928dab)],
              ),
            ),
          ),

          Positioned(
            top: -100,
            right: -80,
            child: Container(
              height: 240,
              width: 240,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _header(),
                Expanded(child: _content()),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            "Personal Expenses",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.file_copy, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HierarchicalReportPage(),
                ),
              )..then((_) {
                loadExpenses(); // ✅ Refresh when coming back
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _content() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DashboardCard(
                  title: "This Year",
                  amount: totalExpense,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DashboardCard(
                  title: "This Month",
                  amount: monthExpense,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Expanded(
            child: expenses.isEmpty
                ? const Center(child: Text("No expenses added"))
                : ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final e = expenses[index];
                return ExpenseTile(
                  expense: e,

                  onEdit: () {
                    showDialog(
                      context: context,
                      builder: (_) => ExpenseFormDialog(
                        expense: e,
                        onSaved: loadExpenses,
                      ),
                    );
                  },

                    onDeleteConfirm: () async {
                      final confirm = await _confirmDelete(context);

                      if (confirm) {
                        await MyPersonalExpenseDB.instance.deleteExpense(e.id!);
                        await loadExpenses();
                        return true;   // allow dismiss
                      }

                      return false;
                    },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return FloatingActionButton.extended(
      backgroundColor: Colors.green,
      icon: const Icon(Icons.add,color: Colors.white,),
      label: const Text("Add New",style: TextStyle(color: Colors.white),),
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => ExpenseFormDialog(
            onSaved: loadExpenses,
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever,
                  size: 36,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Delete Expense?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "This expense will be permanently removed.\nYou can't undo this action.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context, false); // ✅ Cancel
                      },
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      onPressed: () {
                        Navigator.pop(context, true); // ✅ Delete
                      },
                      child: const Text(
                        "Delete",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return confirm ?? false;
  }
}
