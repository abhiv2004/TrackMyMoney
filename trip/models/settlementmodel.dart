class Settlement {
  final int payerId;
  final int receiverId;
  final double amount;

  Settlement({
    required this.payerId,
    required this.receiverId,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'payerId': payerId,
      'receiverId': receiverId,
      'amount': amount,
    };
  }

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      payerId: json['payerId'],
      receiverId: json['receiverId'],
      amount: json['amount'],
    );
  }
}
