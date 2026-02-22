import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tripexpense/models/expensesmodel.dart';
import 'package:tripexpense/models/expensesplitmodel.dart';
import 'package:tripexpense/models/participantmodel.dart';
import 'package:tripexpense/screens/forms/expenseform.dart';
import '../api_helper/apihelper.dart';
import '../models/settlementmodel.dart';
import '../utils/colors.dart';
import 'package:intl/intl.dart';
import '../utils/strings.dart';
import '../widgets/customsweetalert.dart';





class ExpensesPage extends StatefulWidget {
  final int tripId;


  const ExpensesPage({Key? key, required this.tripId}) : super(key: key);

  @override
  _ExpensesPageState createState() => _ExpensesPageState();
}
class _ExpensesPageState extends State<ExpensesPage> {
  late Future<List<Expense>> _expensesFuture;
  Map<int, String> _participantsMap = {};
  Map<int, List<ExpenseSplit>> splitsMap = {};
  double _totalAmount = 0.0;


  @override
  void initState() {
    super.initState();
    _expensesFuture = loadExpenses(); // Proper initialization
  }

  Future<List<Expense>> loadExpenses() async {
    try {
      final expenses = await ApiService().fetchExpensesByTripId(widget.tripId);
      final participants = await ApiService().fetchParticipantsDropDownByTripId(widget.tripId);

      final Map<int, List<ExpenseSplit>> fetchedSplits = {};
      for (final expense in expenses) {
        final splits = await ApiService().fetchExpensesSplitByExpenseId(expense.expenseId);
        fetchedSplits[expense.expenseId] = splits;
      }
      _totalAmount = 0.0;

      for (var expense in expenses) {
        if(expense.expenseName != "Settlement"){
          _totalAmount += expense.amount;
        }
      }

      setState(() {
        _participantsMap = {
          for (var item in participants) item['participantId'] as int: item['participantName'] as String
        };

        _totalAmount = _totalAmount;
        splitsMap = fetchedSplits;
      });

      return expenses;
    } catch (error) {
      setState(() {
        _expensesFuture = Future.error('Failed to load expenses');
      });
      rethrow;
    }
  }

  Future<void> _showDeleteConfirmation(int expenseId) async {
    final bool shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Expense"),
          content: const Text("Are you sure you want to delete this expense?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ) ??
        false;

    if (shouldDelete) {
      bool success = await ApiService().deleteExpense(expenseId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense deleted successfully.')),
        );
          setState(() async {
            _expensesFuture = loadExpenses();
          });


      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete the expense.')),
        );
      }
    }
  }

  Future<void> _editExpense(Expense expense) async {
    final participants = await ApiService().fetchParticipantsDropDownByTripId(widget.tripId);
    List<ExpenseSplit> splits = await ApiService().fetchExpensesSplitByExpenseId(expense.expenseId);

     await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditExpenseForm(
          tripId: widget.tripId,
          expenseId: expense.expenseId,
          expenseName: expense.expenseName,
          amount: expense.amount,
          paidBy: expense.paidBy,
          splitType: expense.splitType,
          description: expense.description,
          expenseDate: expense.expenseDate,
          participants: participants,
          splits: splits,
        ),
      ),
    );

      setState(() {
        _expensesFuture = loadExpenses();
      });


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 3,
            margin: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.teal, // Background color
                borderRadius: BorderRadius.circular(12.0), // Rounded corners
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3), // Shadow color
                    blurRadius: 6, // Blur radius
                    spreadRadius: 2, // Spread radius
                    offset: Offset(2, 4), // Shadow position
                  ),
                ],
              ),
              child: ListTile(
                textColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0), // Ensures ListTile follows the same rounded shape
                ),
                title: const Text(
                  'Total Expense',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  '₹${_totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
              ),
            )

          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: const Text(
              ' Expenses List',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold,color: Colors.teal),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<List<Expense>>(
              future: _expensesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No expenses found.",
                    style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold, color: Colors.teal),));
                } else {
                  final expenses = snapshot.data!;

                  return ListView.builder(
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];

                      return Dismissible(
                        key: Key(expense.expenseId.toString()),
                        direction: DismissDirection.startToEnd, // Swipe left to right
                        background: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.centerLeft,
                          color: Colors.teal,
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.white),
                              SizedBox(width: 10),
                              Text("Edit Expense", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        onDismissed: (direction) {
                          if(expense.expenseName.toLowerCase() != 'settlement'){
                            _editExpense(expense);
                            setState(() {
                              expenses.removeAt(index);
                              _expensesFuture = loadExpenses();
                            });
                          }else{
                            showCustomSweetAlert(context, "settlement can not edit.", "warning", () {});
                            setState(() {
                              expenses.removeAt(index);
                              _expensesFuture = loadExpenses();
                            });
                          }
                        },
                        child: Card(
                          color: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(color: Colors.teal, width: 1),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: ListTile(
                            title: Text(
                              expense.expenseName,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal),
                            ),
                            subtitle: Text(
                              'Paid By: ${_participantsMap[expense.paidBy] ?? 'Unknown'}\n${DateFormat('dd MMM yyyy').format(expense.expenseDate)}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '₹${expense.amount.toStringAsFixed(2)}',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal),
                                ),
                              ],
                            ),
                            onTap: () => _showExpenseDetails(expense),
                            onLongPress: () => _showDeleteConfirmation(expense.expenseId),
                          ),
                        ),
                      );
                    },
                  );

                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(50),
        color: Colors.teal,
        child: SizedBox(
          width: 150,
          height: 48,
          child: FloatingActionButton(
            onPressed: () async {
              final participants =
              await ApiService().fetchParticipantsDropDownByTripId(widget.tripId);

              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddExpenseForm(
                    tripId: widget.tripId,
                    participants: participants,
                  ),
                ),
              );

              if (result == true) {
                _expensesFuture = loadExpenses();
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, color: AppColors.white),
                const SizedBox(width: 8),
                Text(
                  AppStrings.addExpense,
                  style: const TextStyle(color: AppColors.white),
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
    );
  }


  void _showExpenseDetails(Expense expense) async {
    if (!splitsMap.containsKey(expense.expenseId)) {
      try {
        final splits = await ApiService().fetchExpensesSplitByExpenseId(expense.expenseId);
        setState(() {
          splitsMap[expense.expenseId] = splits;
        });
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load split details: $error')),
        );
        return;
      }
    }

    final splitData = splitsMap[expense.expenseId] ?? [];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Text(
            expense.expenseName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow("Amount", "₹${expense.amount.toStringAsFixed(2)}"),
                _buildDetailRow("Paid By", _participantsMap[expense.paidBy] ?? 'Unknown'),
                _buildDetailRow("Split Type", expense.splitType),
                _buildDetailRow("Expense Date", DateFormat('yyyy-MM-dd').format(expense.expenseDate)),
                _buildDetailRow("Description", expense.description ?? 'N/A'),

                const SizedBox(height: 12),
                Text(
                  "Split Details",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                const SizedBox(height: 8),

                if (splitData.isEmpty)
                  Text(
                    "No split data available.",
                    style: TextStyle(color: Colors.grey[600]),
                  )
                else
                  Column(
                    children: splitData.map((split) {
                      final participantName = _participantsMap[split.participantId] ?? 'Unknown';
                      final share = split.amount;
                      return Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.teal[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              participantName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              "₹${share.toStringAsFixed(2)}",
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$label:",
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.teal, fontSize: 14),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.3, // Limit width
            child: Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

}


class BalancePage extends StatefulWidget {
  final int tripId;

  BalancePage({
    required this.tripId
  });

  @override
  State<BalancePage> createState() => _BalancePageState();
}

class _BalancePageState extends State<BalancePage> {
  List<Participant> _participants = [];
  Map<int, String> _participantsMap = {};
  Map<int, List<ExpenseSplit>> _expenseSplits = {};
  double _totalExpense = 0.0;

  Map<int, double> _participantPaid = {};
  List<Settlement> _settlementTransactions = [];
  List<Expense> expenses = [];

  @override
  void initState() {
    super.initState();
    _loadData();

  }

  Future<void> _loadData() async {
    try {
      final participants = await ApiService().fetchParticipantsByTripId(widget.tripId);
      final participantMap = {
        for (var item in await ApiService().fetchParticipantsDropDownByTripId(widget.tripId))
          item['participantId'] as int: item['participantName'] as String
      };
      final expenses = await ApiService().fetchExpensesByTripId(widget.tripId);
      final splitsMap = <int, List<ExpenseSplit>>{};
      final paidMap = <int, double>{};
      double total = 0.0;

      for (var expense in expenses) {
        if(expense.expenseName != "Settlement"){
          total += expense.amount;
          paidMap[expense.paidBy] = (paidMap[expense.paidBy] ?? 0.0) + (expense.amount);
          splitsMap[expense.expenseId] = await ApiService().fetchExpensesSplitByExpenseId(expense.expenseId);
        }else{
          paidMap[expense.paidBy] = (paidMap[expense.paidBy] ?? 0.0) + (expense.amount);
          splitsMap[expense.expenseId] = await ApiService().fetchExpensesSplitByExpenseId(expense.expenseId);
        }
      }

      setState(() {
        _participants = participants;
        _participantsMap = participantMap;
        _expenseSplits = splitsMap;
        _totalExpense = total;
        _participantPaid = paidMap;
        _calculateSettlements();
      });
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  double _calculateParticipantOwed(int participantId) {
    double totalOwed = 0.0;
    for (var splits in _expenseSplits.values) {
      for (var split in splits) {
        if (split.participantId == participantId) {
          totalOwed += split.amount;
        }
      }
    }
    return totalOwed;
  }


  double _calculateParticipantBalance(int participantId) {
    double paid = _participantPaid[participantId] ?? 0.0;
    double owed = _calculateParticipantOwed(participantId);
    return paid - owed;
  }

  void _calculateSettlements() {
    Map<int, double> balances = {};

    for (var participant in _participants) {
      int? participantId = participant.participantId;
      double balance = _calculateParticipantBalance(participantId!);
      balances[participantId] = balance;
    }

    List<int> owes = balances.keys.where((id) => balances[id]! < 0).toList();
    List<int> owed = balances.keys.where((id) => balances[id]! > 0).toList();

    List<Settlement> settlementTransactions = [];

    while (owes.isNotEmpty && owed.isNotEmpty) {
      int oweId = owes.first;
      int owedId = owed.first;

      double oweAmount = -balances[oweId]!;
      double owedAmount = balances[owedId] ?? 0.0;

      double settleAmount = oweAmount < owedAmount ? oweAmount : owedAmount;

      settlementTransactions.add(Settlement(
        payerId: oweId,
        receiverId: owedId,
        amount: settleAmount,
      ));

      balances[oweId] = (balances[oweId] ?? 0.0) + settleAmount;
      balances[owedId] = (balances[owedId] ?? 0.0) - settleAmount;

      if (balances[oweId] == 0) owes.remove(oweId);
      if (balances[owedId] == 0) owed.remove(owedId);
    }

    setState(() {
      _settlementTransactions = settlementTransactions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
            elevation: 3,
            margin: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.teal, // Background color
                borderRadius: BorderRadius.circular(12.0), // Rounded corners
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3), // Shadow color
                    blurRadius: 6, // Blur radius
                    spreadRadius: 2, // Spread radius
                    offset: Offset(2, 4), // Shadow position
                  ),
                ],
              ),
              child: ListTile(
                textColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0), // Ensures ListTile follows the same rounded shape
                ),
                title: const Text(
                  'Total Expense',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  '₹${_totalExpense.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
              ),
            )

        ),
        SizedBox(height: 20),
        // Participants
        Card(
          elevation: 4,
          margin: const EdgeInsets.all(8.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: ExpansionTile(
            title: Text(
              'Participants',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            leading: Icon(Icons.people, color: Colors.teal),
            children: [
              Container(
                height: 250.0,
                child: ListView.separated(
                  itemCount: _participants.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    var participant = _participants[index];
                    int? participantId = participant.participantId;
                    String participantName = participant.participantName;
                    double paid = _participantPaid[participantId] ?? 0.0;
                    double owed = _calculateParticipantOwed(participantId!);
                    double balance = _calculateParticipantBalance(participantId);

                    return ListTile(
                      leading: ClipOval(
                        child: (participant.participantImage == null || participant.participantImage == "")
                            ? Icon(Icons.person, size: 50, color: Colors.teal)
                            : displayImage(participant.participantImage),
                      ),
                      title: Text(participantName, style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Paid: ₹${paid.toStringAsFixed(2)}'),
                          Text('Owes: ₹${owed.toStringAsFixed(2)}'),
                        ],
                      ),
                      trailing: Text(
                        balance >= 0
                            ? 'Owed: ₹${balance.toStringAsFixed(2)}'
                            : 'Owes: ₹${(-balance).toStringAsFixed(2)}',
                        style: TextStyle(
                          color: balance >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 20),
        // Settlement Transactions ExpansionTile
        Card(
          elevation: 4,
          margin: const EdgeInsets.all(8.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: ExpansionTile(
            title: Text(
              'Settlements',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            leading: Icon(Icons.money, color: Colors.teal),
            children: [
              if (_settlementTransactions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'All expenses are already settled.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              else
                Container(
                  height: 250.0,
                  child: ListView.separated(
                    itemCount: _settlementTransactions.length,
                    separatorBuilder: (context, index) => Divider(),
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                      '${_participantsMap[_settlementTransactions[index].payerId]} should pay '
                      '${_participantsMap[_settlementTransactions[index].receiverId]} '
                          '₹${_settlementTransactions[index].amount.toStringAsFixed(2)}',
                      ), onTap: () {
                          _showSettlementDialog(context, _settlementTransactions[index]);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget displayImage(String? base64Image) {
    if (base64Image == null || base64Image.isEmpty) {
      return SizedBox(
        width: 50, // Set the desired width
        height: 50, // Set the desired height (same as width for a square)
        child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Icon(Icons.image,size: 50,)
        ),
      );
    }
    try {
      Uint8List imageBytes = base64Decode(base64Image);
      return SizedBox(
        width: 60, // Set the desired width
        height: 60, // Set the desired height (same as width for a square)
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.memory(
            imageBytes,
            fit: BoxFit.cover, // Ensures the image fits within the bounds
          ),
        ),
      );
    } catch (e) {
      return const Icon(Icons.error, size: 50);
    }
  }
  void _showSettlementDialog(BuildContext context, Settlement transaction) {
    TextEditingController amountController =
    TextEditingController(text: transaction.amount.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: EdgeInsets.zero,
          content: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 24), // Space for close button\
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.6, // Limit width
                      child: Text(
                        '${_participantsMap[transaction.payerId]} should pay '
                            '${_participantsMap[transaction.receiverId]} '
                            '₹${transaction.amount.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                    ),
                    // Text(
                    //   '${_participantsMap[transaction.payerId]} should pay '
                    //       '${_participantsMap[transaction.receiverId]} '
                    //       '₹${transaction.amount.toStringAsFixed(2)}',
                    //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    //   textAlign: TextAlign.center,
                    // ),
                    SizedBox(height: 16.0),
                    TextField(
                      controller: amountController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                        hintText: "Amount",
                        labelText: "Amount",
                        prefixIcon: Icon(Icons.currency_rupee, color: Colors.teal),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16.0),
                    ElevatedButton.icon(
                      onPressed: () {
                        double amount = double.tryParse(amountController.text) ?? 0;
                        if (amount > 0) {
                          _settleTransaction(transaction, amount);
                          Navigator.pop(context); // Close the dialog
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please enter a valid amount')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 3,
                      ),
                      icon: Icon(Icons.currency_exchange, color: Colors.white, size: 20),
                      label: Text(
                        "Settle",
                        style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /* void _showSettlementDialog(BuildContext context, Settlement transaction) {
    TextEditingController amountController = TextEditingController(text: transaction.amount.toStringAsFixed(2));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_participantsMap[transaction.payerId]} should pay '
                    '${_participantsMap[transaction.receiverId]} '
                    '₹${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.8),
                  hintText: "Amount",
                  hintStyle: TextStyle(
                    color: Colors.grey, // Customize label text color
                    fontSize: 16, // Customize label text size
                    fontWeight: FontWeight.w500, // Bold label text
                  ),
                  labelText: "Amount",
                  labelStyle: TextStyle(
                    color: Colors.teal, // Label text color
                    fontSize: 16, // Label text size
                    fontWeight: FontWeight.w500, // Label text boldness
                  ),
                  prefixIcon: Icon(Icons.currency_rupee, color: Colors.teal),

                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.teal),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.teal), // New focused color
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,

              ),
              SizedBox(height: 16.0),
              ElevatedButton.icon(
                onPressed: () {
                  double amount = double.tryParse(amountController.text) ?? 0;
                  if (transaction.amount > 0) {
                    // Handle the settlement logic here
                    _settleTransaction(transaction, amount);
                    Navigator.pop(context); // Close the bottom sheet
                  } else {
                    // Show an error if the amount is invalid
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter a valid amount')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, // White background for Google button
                  padding: EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(color: Colors.grey.shade100), // Border color
                  ),
                  elevation: 3,
                ),
                icon: Icon(Icons.currency_exchange, color: Colors.white, size: 20),
                label: Text(
                  "Settle",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white, // Dark text for contrast
                    fontWeight: FontWeight.w600,
                  ),
                ),

              ),

            ],
          ),
        );
      },
    );
  }
*/
  Future<void> _settleTransaction(Settlement transaction, double amount) async {
    if (amount <= 0 || amount > transaction.amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    int? expenseId = await ApiService().insertExpense("Settlement", amount, transaction.payerId, "settle", widget.tripId, "${_participantsMap[transaction.payerId]} to ${_participantsMap[transaction.receiverId]}", DateTime.now(),);

    if (expenseId != null) {
      bool success = await ApiService().insertExpenseSplit(expenseId,transaction.receiverId,amount,widget.tripId,);

      if (success) {
        _loadData(); // Refresh data after settlement
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Settlement recorded successfully!')),
        );
      }
    }


  }

}



