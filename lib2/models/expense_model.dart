class ExpenseModel {
  int? expenseId;
  int groupId;
  String expenseName;
  double amount;
  int paidByParticipantId;
  String splitType; // 'Equal', 'Custom Equal', 'Manual'
  String date;
  String? description;

  ExpenseModel({
    this.expenseId,
    required this.groupId,
    required this.expenseName,
    required this.amount,
    required this.paidByParticipantId,
    required this.splitType,
    required this.date,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'expense_id': expenseId,
      'group_id': groupId,
      'expense_name': expenseName,
      'amount': amount,
      'paid_by': paidByParticipantId,
      'split_type': splitType,
      'expense_date': date,
      'description': description,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      expenseId: map['expense_id'],
      groupId: map['group_id'],
      expenseName: map['expense_name'],
      amount: map['amount'],
      paidByParticipantId: map['paid_by'],
      splitType: map['split_type'],
      date: map['expense_date'],
      description: map['description'],
    );
  }
}

class ExpenseSplitModel {
  int? splitId;
  int expenseId;
  int participantId;
  double amount;
  int groupId;

  ExpenseSplitModel({
    this.splitId,
    required this.expenseId,
    required this.participantId,
    required this.amount,
    required this.groupId,
  });

  Map<String, dynamic> toMap() {
    return {
      'split_id': splitId,
      'expense_id': expenseId,
      'participant_id': participantId,
      'amount': amount,
      'group_id': groupId,
    };
  }

  factory ExpenseSplitModel.fromMap(Map<String, dynamic> map) {
    return ExpenseSplitModel(
      splitId: map['split_id'],
      expenseId: map['expense_id'],
      participantId: map['participant_id'],
      amount: map['amount'],
      groupId: map['group_id'],
    );
  }
}
