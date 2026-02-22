import 'expensesplitmodel.dart';

class ExpenseWithSplit {
  int expenseId;
  String expenseName;
  double amount;
  int paidBy;
  String splitType;
  int tripId;
  String? description; // Nullable field
  DateTime expenseDate;
  List<ExpenseSplit> splits; // Updated to use List of ExpenseSplit

  ExpenseWithSplit({
    required this.expenseId,
    required this.expenseName,
    required this.amount,
    required this.paidBy,
    required this.splitType,
    required this.tripId,
    this.description,
    required this.expenseDate,
    required this.splits,
  });

  // Factory constructor to create an instance from JSON
  factory ExpenseWithSplit.fromJson(Map<String, dynamic> json) {
    return ExpenseWithSplit(
      expenseId: json['expenses']['expenseId'] as int,
      expenseName: json['expenses']['expenseName'] as String,
      amount: json['expenses']['amount'] is int
          ? (json['expenses']['amount'] as int).toDouble()
          : json['expenses']['amount'] as double,
      paidBy: json['expenses']['paidBy'] as int,
      splitType: json['expenses']['splitType'] as String,
      tripId: json['expenses']['tripId'] as int,
      description: json['expenses']['description'] as String?,
      expenseDate: DateTime.parse(json['expenses']['expenseDate']),
      splits: (json['expenseSplits'] as List)
          .map((splitJson) => ExpenseSplit.fromJson(splitJson))
          .toList(),
    );
  }

  // Method to convert an instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'expenses': {
        'expenseId': expenseId,
        'expenseName': expenseName,
        'amount': amount,
        'paidBy': paidBy,
        'splitType': splitType,
        'tripId': tripId,
        'description': description,
        'expenseDate': expenseDate.toIso8601String(),
      },
      'expenseSplits': splits.map((split) => split.toJson()).toList(),
    };
  }
}


class Expense {
  int expenseId;
  String expenseName;
  double amount;
  int paidBy;
  String splitType;
  int tripId;
  String? description; // Nullable field
  DateTime expenseDate;

  Expense({
    required this.expenseId,
    required this.expenseName,
    required this.amount,
    required this.paidBy,
    required this.splitType,
    required this.tripId,
    this.description,
    required this.expenseDate,
  });

  // Factory constructor to create an instance from JSON
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      expenseId: json['expenseId'] as int,
      expenseName: json['expenseName'] as String,
      amount: json['amount'] is int
          ? (json['amount'] as int).toDouble()
          : json['amount'] as double,
      paidBy: json['paidBy'] as int,
      splitType: json['splitType'] as String,
      tripId: json['tripId'] as int,
      description: json['description'] as String?,
      expenseDate: DateTime.parse(json['expenseDate']),
    );
  }

  // Method to convert an instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'expenseId': expenseId,
      'expenseName': expenseName,
      'amount': amount,
      'paidBy': paidBy,
      'splitType': splitType,
      'tripId': tripId,
      'description': description,
      'expenseDate': expenseDate.toIso8601String(),
    };
  }
}

