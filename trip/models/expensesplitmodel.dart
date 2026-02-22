
class ExpenseSplit {
  int splitId;
  int expenseId;
  int participantId;
  double amount;
  int tripId;

  ExpenseSplit({
    required this.splitId,
    required this.expenseId,
    required this.participantId,
    required this.amount,
    required this.tripId,
  });

  // Factory constructor to create an instance from JSON
  factory ExpenseSplit.fromJson(Map<String, dynamic> json) {
    return ExpenseSplit(
      splitId: json['splitId'] as int,
      expenseId: json['expenseId'] as int,
      participantId: json['participantId'] as int,
      amount: json['amount'] is int
          ? (json['amount'] as int).toDouble()
          : json['amount'] as double,
      tripId: json['tripId'] as int,
    );
  }

  // Method to convert an instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'splitId': splitId,
      'expenseId': expenseId,
      'participantId': participantId,
      'amount': amount,
      'tripId': tripId,
    };
  }
}
