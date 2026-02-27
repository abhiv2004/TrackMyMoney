import 'package:flutter/material.dart';
import '../database/groupdatabase.dart';
import '../models/participant_model.dart';
import 'expenseform.dart';

class BalanceScreen extends StatefulWidget {
  final int groupId;
  const BalanceScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  _BalanceScreenState createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  List<ParticipantModel> _participants = [];
  Map<int, double> _paidByPart = {};
  Map<int, double> _owedByPart = {};
  List<Map<String, dynamic>> _settlements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    setState(() => _isLoading = true);
    final db = GroupExpenseDB.instance;
    
    // 1. Fetch data
    final participantsData = await db.getParticipantsByGroupId(widget.groupId);
    final expenses = await db.getExpensesByGroupId(widget.groupId);
    final splits = await db.getAllSplitsForGroup(widget.groupId);

    _participants = participantsData.map((p) => ParticipantModel.fromMap(p)).toList();
    
    _paidByPart.clear();
    _owedByPart.clear();

    for (var p in _participants) {
      _paidByPart[p.participantId!] = 0;
      _owedByPart[p.participantId!] = 0;
    }

    // 2. Calculate totals
    for (var exp in expenses) {
      int payerId = exp['paid_by'];
      double amount = exp['amount'];
      _paidByPart[payerId] = (_paidByPart[payerId] ?? 0) + amount;
    }

    for (var split in splits) {
      int pId = split['participant_id'];
      double amount = split['amount'];
      _owedByPart[pId] = (_owedByPart[pId] ?? 0) + amount;
    }

    // 3. Compute Settlements
    _computeSettlements();

    setState(() => _isLoading = false);
  }

  void _computeSettlements() {
    _settlements.clear();
    List<Map<String, dynamic>> netBalances = [];

    for (var p in _participants) {
      double net = (_paidByPart[p.participantId!] ?? 0) - (_owedByPart[p.participantId!] ?? 0);
      if (net.abs() > 0.01) {
        netBalances.add({'id': p.participantId, 'name': p.name, 'net': net});
      }
    }

    // Sort by net balance
    netBalances.sort((a, b) => a['net'].compareTo(b['net']));

    int i = 0;
    int j = netBalances.length - 1;

    while (i < j) {
      double payAmount = -netBalances[i]['net'];
      double receiveAmount = netBalances[j]['net'];
      double settledAmount = payAmount < receiveAmount ? payAmount : receiveAmount;

      _settlements.add({
        'fromId': netBalances[i]['id'],
        'fromName': netBalances[i]['name'],
        'toId': netBalances[j]['id'],
        'toName': netBalances[j]['name'],
        'amount': settledAmount,
      });

      netBalances[i]['net'] += settledAmount;
      netBalances[j]['net'] -= settledAmount;

      if (netBalances[i]['net'].abs() < 0.01) i++;
      if (netBalances[j]['net'].abs() < 0.01) j--;
    }
  }

  void _settleAsExpense(Map<String, dynamic> settlement) async {
    final expenseMap = {
      'group_id': widget.groupId,
      'expense_name': "Settlement: ${settlement['fromName']} to ${settlement['toName']}",
      'amount': settlement['amount'],
      'paid_by': settlement['fromId'],
      'split_type': 'Manual',
      'expense_date': DateTime.now().toIso8601String(),
    };

    final splits = [{
      'participant_id': settlement['toId'],
      'amount': settlement['amount'],
      'group_id': widget.groupId,
    }];

    await GroupExpenseDB.instance.insertExpenseWithSplits(expense: expenseMap, splits: splits);
    _loadBalance();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Settlement recorded as expense")));
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Participant Balances", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                const SizedBox(height: 12),
                ..._participants.map((p) {
                  double paid = _paidByPart[p.participantId!] ?? 0;
                  double owed = _owedByPart[p.participantId!] ?? 0;
                  double net = paid - owed;
                  return Card(
                    child: ListTile(
                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Paid: ₹${paid.toStringAsFixed(2)} | Owed: ₹${owed.toStringAsFixed(2)}"),
                      trailing: Text(
                        "${net >= 0 ? '+' : ''}₹${net.toStringAsFixed(2)}",
                        style: TextStyle(fontWeight: FontWeight.bold, color: net >= 0 ? Colors.green : Colors.red),
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 24),
                const Text("Settlement Suggestions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                const Divider(),
                if (_settlements.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text("All accounts settled!", style: TextStyle(fontStyle: FontStyle.italic))),
                  )
                else
                  ..._settlements.map((s) => Card(
                    color: Colors.teal.shade50,
                    child: ListTile(
                      title: Text("${s['fromName']} pays ${s['toName']}"),
                      trailing: Text("₹${s['amount'].toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      onTap: () => _settleAsExpense(s),
                    ),
                  )).toList(),
              ],
            ),
          );
  }
}
