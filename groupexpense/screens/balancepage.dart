import 'package:flutter/material.dart';
import '../database/group_expense_db.dart';
import '../models/group_expense_model.dart';
import '../models/group_split_model.dart';
import '../models/group_participant_model.dart';

class GroupBalancePage extends StatefulWidget {
  final int groupId;

  const GroupBalancePage({required this.groupId, Key? key})
      : super(key: key);

  @override
  State<GroupBalancePage> createState() => _GroupBalancePageState();
}

class _GroupBalancePageState extends State<GroupBalancePage> {
  bool _isLoading = true;
  Map<int, double> _balanceMap = {};
  Map<int, String> _participantsMap = {};

  @override
  void initState() {
    super.initState();
    _calculateBalance();
  }

  Future<void> _calculateBalance() async {
    final expenses = await GroupExpenseDB.instance
        .fetchExpensesByGroupId(widget.groupId);

    final participants = await GroupExpenseDB.instance
        .fetchParticipantsByGroupId(widget.groupId);

    Map<int, double> balance = {};

    for (var p in participants) {
      balance[p.participantId!] = 0.0;
      _participantsMap[p.participantId!] = p.name;
    }

    for (var expense in expenses) {
      final splits = await GroupExpenseDB.instance
          .fetchExpenseSplitsByExpenseId(expense.expenseId!);

      // Add full amount to payer
      balance[expense.paidBy] =
          (balance[expense.paidBy] ?? 0) + expense.amount;

      // Subtract split amount from each participant
      for (var split in splits) {
        balance[split.participantId] =
            (balance[split.participantId] ?? 0) - split.amount;
      }
    }

    setState(() {
      _balanceMap = balance;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_balanceMap.isEmpty) {
      return const Center(child: Text("No Balance Data"));
    }

    return ListView(
      children: _balanceMap.entries.map((entry) {
        final name = _participantsMap[entry.key] ?? "Unknown";
        final amount = entry.value;

        return ListTile(
          title: Text(name),
          trailing: Text(
            amount >= 0
                ? "Gets ₹ ${amount.toStringAsFixed(2)}"
                : "Owes ₹ ${amount.abs().toStringAsFixed(2)}",
            style: TextStyle(
              color: amount >= 0
                  ? Colors.green
                  : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }
}