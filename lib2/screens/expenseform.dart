import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/groupdatabase.dart';
import '../models/participant_model.dart';
import '../models/expense_model.dart';

class ExpenseForm extends StatefulWidget {
  final int groupId;
  final int? expenseId;

  const ExpenseForm({Key? key, required this.groupId, this.expenseId}) : super(key: key);

  @override
  _ExpenseFormState createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  
  List<ParticipantModel> _participants = [];
  int? _paidByParticipantId;
  String _splitType = 'Equal'; // 'Equal', 'Custom Equal', 'Manual'
  
  Map<int, bool> _selectedParticipants = {}; // For Custom Equal
  Map<int, TextEditingController> _manualControllers = {}; // For Manual
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final participantsData = await GroupExpenseDB.instance.getParticipantsByGroupId(widget.groupId);
    _participants = participantsData.map((p) => ParticipantModel.fromMap(p)).toList();
    
    for (var p in _participants) {
      _selectedParticipants[p.participantId!] = true;
      _manualControllers[p.participantId!] = TextEditingController();
    }

    if (widget.expenseId != null) {
      // Load existing expense
      // ... (Implementation for edit mode if needed, focusing on structure for now)
    }

    if (_participants.isNotEmpty) {
      _paidByParticipantId = _participants.first.participantId;
    }

    setState(() => _isLoading = false);
  }

  void _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_paidByParticipantId == null) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    List<Map<String, dynamic>> splits = [];

    if (_splitType == 'Equal') {
      final perPerson = amount / _participants.length;
      for (var p in _participants) {
        splits.add({
          'participant_id': p.participantId,
          'amount': perPerson,
          'group_id': widget.groupId,
        });
      }
    } else if (_splitType == 'Custom Equal') {
      final selected = _selectedParticipants.entries.where((e) => e.value).map((e) => e.key).toList();
      if (selected.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select at least one participant")));
        return;
      }
      final perPerson = amount / selected.length;
      for (var pId in selected) {
        splits.add({
          'participant_id': pId,
          'amount': perPerson,
          'group_id': widget.groupId,
        });
      }
    } else if (_splitType == 'Manual') {
      double totalManual = 0;
      for (var ctrl in _manualControllers.values) {
        totalManual += double.tryParse(ctrl.text) ?? 0;
      }
      if ((totalManual - amount).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Total manual amounts ($totalManual) must equal total expense ($amount)")));
        return;
      }
      for (var entry in _manualControllers.entries) {
        final val = double.tryParse(entry.value.text) ?? 0;
        if (val > 0) {
          splits.add({
            'participant_id': entry.key,
            'amount': val,
            'group_id': widget.groupId,
          });
        }
      }
    }

    final expenseMap = {
      'group_id': widget.groupId,
      'expense_name': _nameController.text.trim(),
      'amount': amount,
      'paid_by': _paidByParticipantId,
      'split_type': _splitType,
      'expense_date': _dateController.text,
    };

    setState(() => _isLoading = true);
    await GroupExpenseDB.instance.insertExpenseWithSplits(expense: expenseMap, splits: splits);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Expense"), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Expense Name", border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: "Amount", border: OutlineInputBorder(), prefixText: "₹"),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _paidByParticipantId,
                    decoration: const InputDecoration(labelText: "Paid By", border: OutlineInputBorder()),
                    items: _participants.map((p) => DropdownMenuItem(value: p.participantId, child: Text(p.name))).toList(),
                    onChanged: (val) => setState(() => _paidByParticipantId = val),
                  ),
                  const SizedBox(height: 20),
                  const Text("Split Type", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
                  Row(
                    children: [
                      _splitChip("Equal"),
                      _splitChip("Custom Equal"),
                      _splitChip("Manual"),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text("Split Details", style: TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),
                  ..._buildSplitDetails(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveExpense,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                      child: const Text("SAVE EXPENSE", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _splitChip(String type) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(type),
        selected: _splitType == type,
        onSelected: (val) => setState(() => _splitType = type),
        selectedColor: Colors.teal.shade200,
      ),
    );
  }

  List<Widget> _buildSplitDetails() {
    if (_splitType == 'Equal') {
      return _participants.map((p) => ListTile(title: Text(p.name), trailing: const Icon(Icons.check, color: Colors.green))).toList();
    } else if (_splitType == 'Custom Equal') {
      return _participants.map((p) => CheckboxListTile(
        title: Text(p.name),
        value: _selectedParticipants[p.participantId],
        onChanged: (val) => setState(() => _selectedParticipants[p.participantId!] = val!),
      )).toList();
    } else {
      return _participants.map((p) => ListTile(
        title: Text(p.name),
        trailing: SizedBox(
          width: 100,
          child: TextField(
            controller: _manualControllers[p.participantId],
            decoration: const InputDecoration(hintText: "0.00", prefixText: "₹"),
            keyboardType: TextInputType.number,
          ),
        ),
      )).toList();
    }
  }
}
