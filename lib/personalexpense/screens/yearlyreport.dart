import 'package:billtracker/personalexpense/screens/expensetile.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/personaldatabase.dart';
import 'expense_form_dialog.dart';

class YearlyExpenseListPage extends StatefulWidget {
  final int year;
  const YearlyExpenseListPage({super.key, required this.year});

  @override
  State<YearlyExpenseListPage> createState() =>
      _YearlyExpenseListPageState();
}

class _YearlyExpenseListPageState
    extends State<YearlyExpenseListPage> {
  Map<int, List<Map<String, dynamic>>> expensesByMonth = {};
  bool isLoading = true;
  int? expandedMonth;

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    final allExpenses =
    await MyPersonalExpenseDB.instance.getExpenses();

    Map<int, List<Map<String, dynamic>>> grouped = {};

    for (var expense in allExpenses) {
      final date = DateTime.parse(expense['date']);
      if (date.year != widget.year) continue;

      grouped.putIfAbsent(date.month, () => []);
      grouped[date.month]!.add(expense);
    }

    setState(() {
      expensesByMonth = grouped;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${widget.year} Expenses",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    child: isLoading
                        ? const Center(
                        child: CircularProgressIndicator())
                        : ListView.builder(
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final month = index + 1;
                        final monthExpenses =
                            expensesByMonth[month] ?? [];

                        final monthlyTotal =
                        monthExpenses.fold<double>(
                          0,
                              (sum, e) =>
                          sum + (e['amount'] as double),
                        );

                        final isExpanded =
                            expandedMonth == month;

                        return Card(
                          margin:
                          const EdgeInsets.symmetric(
                              vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    expandedMonth =
                                    isExpanded
                                        ? null
                                        : month;
                                  });
                                },
                                child: Padding(
                                  padding:
                                  const EdgeInsets
                                      .symmetric(
                                      horizontal: 16,
                                      vertical: 14),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat.MMMM()
                                            .format(
                                            DateTime(
                                                widget
                                                    .year,
                                                month)),
                                        style:
                                        const TextStyle(
                                          fontSize: 18,
                                          fontWeight:
                                          FontWeight
                                              .bold,
                                        ),
                                      ),
                                      Text(
                                        "₹${monthlyTotal.toStringAsFixed(2)}",
                                        style:
                                        const TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                          FontWeight
                                              .w600,
                                          color: Color(
                                              0xff16a34a),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              if (isExpanded)
                                Column(
                                  children:
                                  monthExpenses
                                      .isEmpty
                                      ? const [
                                    Padding(
                                      padding:
                                      EdgeInsets
                                          .all(
                                          12),
                                      child: Text(
                                        "No expenses",
                                        style:
                                        TextStyle(
                                            color:
                                            Colors.grey),
                                      ),
                                    )
                                  ]
                                      : monthExpenses
                                      .map(
                                        (expense) =>
                                        ExpenseTile(
                                          expense:expense,

                                          // ✅ EDIT FIXED
                                          onEdit: () {
                                            showDialog(
                                              context:
                                              context,
                                              builder:
                                                  (_) =>
                                                  ExpenseFormDialog(
                                                    expense:
                                                    expense,
                                                    onSaved:
                                                    loadExpenses,
                                                  ),
                                            );
                                          },
                                          onDeleteConfirm: () async{
                                              final confirm = await _confirmDelete(context);

                                              if (confirm) {
                                              await MyPersonalExpenseDB.instance.deleteExpense(expense['id']);
                                              await loadExpenses();
                                              return true;   // allow dismiss
                                              }

                                              return false;
                                          },
                                        ),
                                  )
                                      .toList(),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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