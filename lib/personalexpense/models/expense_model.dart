class Expense {
  final int? id;
  final String name;
  final double amount;
  final String category;
  final String remarks;
  final String date;

  Expense({
    this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.remarks,
    required this.date,
  });

  // Convert an Expense into a Map. The keys must correspond to the names of the 
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'category': category,
      'remarks': remarks,
      'date': date,
    };
  }

  // Extract an Expense object from a Map.
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      name: map['name'],
      amount: map['amount'],
      category: map['category'],
      remarks: map['remarks'],
      date: map['date'],
    );
  }

  Expense copyWith({
    int? id,
    String? name,
    double? amount,
    String? category,
    String? remarks,
    String? date,
  }) {
    return Expense(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      remarks: remarks ?? this.remarks,
      date: date ?? this.date,
    );
  }
}
