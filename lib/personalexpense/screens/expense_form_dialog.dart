import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';

class ExpenseFormDialog extends StatefulWidget {
  final Expense? expense;
  final VoidCallback? onSaved;

  const ExpenseFormDialog({super.key, this.expense, this.onSaved});

  @override
  State<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<ExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameCtrl;
  late TextEditingController remarksCtrl;
  late TextEditingController amountCtrl;
  late TextEditingController dateCtrl;

  String selectedCategory = 'Other';

  final Map<String, IconData> categoryIcons = const {
    'Rent': Icons.home,
    'Food': Icons.restaurant,
    'Electricity': Icons.electric_bolt,
    'Travel': Icons.directions_car,
    'Shopping': Icons.shopping_bag,
    'Other': Icons.category,
  };

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.expense?.name ?? '');
    remarksCtrl =
        TextEditingController(text: widget.expense?.remarks ?? '');
    amountCtrl =
        TextEditingController(text: widget.expense?.amount.toString() ?? '');

    selectedCategory = widget.expense?.category ?? 'Other';

    dateCtrl = TextEditingController(
      text: widget.expense != null
          ? DateFormat('dd-MM-yyyy')
          .format(DateTime.parse(widget.expense!.date))
          : DateFormat('dd-MM-yyyy').format(DateTime.now()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  widget.expense == null ? "Add Expense" : "Update Expense",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                _input(nameCtrl, "Expense Name", Icons.text_fields,
                    validator: (v) =>
                    v!.isEmpty ? "Required" : null),

                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: _decoration("Category", Icons.category),
                  items: categoryIcons.entries
                      .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Row(
                      children: [
                        Icon(e.value, size: 18),
                        const SizedBox(width: 10),
                        Text(e.key),
                      ],
                    ),
                  ))
                      .toList(),
                  onChanged: (v) => setState(() => selectedCategory = v!),
                ),

                const SizedBox(height: 14),

                _input(amountCtrl, "Amount", Icons.currency_rupee,
                    keyboard: TextInputType.number,
                    validator: (v) =>
                    double.tryParse(v!) == null ? "Invalid" : null),

                const SizedBox(height: 14),

                _input(remarksCtrl, "Remarks", Icons.notes),

                const SizedBox(height: 14),

                TextFormField(
                  controller: dateCtrl,
                  readOnly: true,
                  decoration: _decoration("Date", Icons.calendar_month),
                  onTap: _pickDate,
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.expense == null
                          ? Colors.green
                          : Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _saveExpense,
                    child: Text(widget.expense == null
                        ? "Add Expense"
                        : "Update Expense",style: TextStyle(
                      color: Colors.white
                    ),),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      dateCtrl.text = DateFormat('dd-MM-yyyy').format(picked);
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final parts = dateCtrl.text.split('-');
    final dbDate = '${parts[2]}-${parts[1]}-${parts[0]}';

    final newExpense = Expense(
      id: widget.expense?.id,
      name: nameCtrl.text,
      amount: double.parse(amountCtrl.text),
      category: selectedCategory,
      remarks: remarksCtrl.text,
      date: dbDate,
    );

    if (widget.expense == null) {
      await MyPersonalExpenseDB.instance.addExpense(newExpense);
    } else {
      await MyPersonalExpenseDB.instance.updateExpense(newExpense);
    }

    widget.onSaved?.call();
    Navigator.pop(context);
  }

  Widget _input(TextEditingController c, String label, IconData icon,
      {TextInputType keyboard = TextInputType.text,
        String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      validator: validator,
      decoration: _decoration(label, icon),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xfff1f5f9),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none),
    );
  }


}
