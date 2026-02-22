import 'package:flutter/material.dart';

class AppStrings {
  // General
  static const String appName = 'Expense Splitter';
  static const String background = 'assets/images/1.jpg';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';

  static const String save = 'Save';

  // Trip Page
  static const String tripsTitle = 'Trips';
  static const String addtrip = 'Add Trip';
  static const String deleteTripConfirmation =
      'Are you sure you want to delete this trip?';
  static const String deleteTrip = 'Delete Trip';

  static const String noTripsAvailable = 'No trips available.';
  static const String addTripPrompt = 'Please tap the button to add a trip.';

  // Trip Form
  static const String tripNameLabel = 'Trip Name';
  static const String participantsLabel = 'Participants';
  static const String addParticipant = 'Add Participant';

  // Trip Details
  static const String addExpense = 'Add Expense';
  static const String tripDetailsTitle = 'Trip Details';
  static const String totalExpenses = 'Total Expenses: ';
  static const String expenseNameLabel = 'Expense Name';
  static const String amountLabel = 'Amount';
  static const String paidByLabel = 'Paid By';
  static const String splitTypeLabel = 'Split Type';
  static const String descriptionLabel = 'Description';

  // Error Messages
  static const String invalidTripName = 'Trip name cannot be empty.';
  static const String invalidAmount = 'Please enter a valid amount.';

  // Confirmation
  static const String successMessage = 'Operation completed successfully.';
}
