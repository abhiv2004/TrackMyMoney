import 'package:tripexpense/models/expensesmodel.dart';
import 'package:tripexpense/models/expensesplitmodel.dart';
import 'package:tripexpense/models/participantmodel.dart';
import 'package:tripexpense/models/tripmodel.dart';

class TripDetailsData{
  final TripModel trip;
  final List<Participant> participants;
  final List<ExpenseWithSplit> expenses;
  final List<ExpenseSplit> expenseSplits;

  TripDetailsData({
    required this.trip,
    required this.participants,
    required this.expenses,
    required this.expenseSplits,
  });

  factory TripDetailsData.fromJson(Map<String, dynamic> json) {
    return TripDetailsData(
      trip: TripModel.fromJson(json['trip']),
      participants: List<Participant>.from(
          json['participants'].map((x) => Participant.fromJson(x))),
      expenses: List<ExpenseWithSplit>.from(
          json['expenses'].map((x) => ExpenseWithSplit.fromJson(x))),
      expenseSplits: List<ExpenseSplit>.from(
          json['expenseSplits'].map((x) => ExpenseSplit.fromJson(x))),
    );
  }


}