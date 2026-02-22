import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
class ExpenseTile extends StatelessWidget {
  final Map<String, dynamic> expense;
  final VoidCallback onEdit;
  final Future<bool> Function() onDeleteConfirm;

  const ExpenseTile({
    super.key,
    required this.expense,
    required this.onEdit,
    required this.onDeleteConfirm,
  });

  static const categoryIcons = {
    'Rent': Icons.home,
    'Food': Icons.restaurant,
    'Electricity': Icons.electric_bolt,
    'Travel': Icons.directions_car,
    'Shopping': Icons.shopping_bag,
    'Other': Icons.category,
  };

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(expense['id'].toString()),
      background: _editBg(),
      secondaryBackground: _deleteBg(),

      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit();
          return false;
        }

        // ✅ WAIT for confirmation
        return await onDeleteConfirm();
      },

      child: Card(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        child: ListTile(
          leading: CircleAvatar(
            child: Icon(
                categoryIcons[expense['category']] ?? Icons.category),
          ),
          title: Text(
            expense['name'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            "${expense['category']} • "
                "${DateFormat('dd MMM yyyy').format(DateTime.parse(expense['date']))}",
          ),
          trailing: Text(
            "₹${expense['amount']}",
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.redAccent),
          ),
        ),
      ),
    );
  }

  Widget _editBg() => Container(
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.only(left: 20),
    color: Colors.blue,
    child: const Icon(Icons.edit, color: Colors.white),
  );

  Widget _deleteBg() => Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 20),
    color: Colors.red,
    child: const Icon(Icons.delete, color: Colors.white),
  );
}