import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tripexpense/models/expensesplitmodel.dart';

import '../../api_helper/apihelper.dart';
import '../../widgets/customsweetalert.dart';


class AddExpenseForm extends StatefulWidget {
  final int tripId;
  final List<Map<String, dynamic>> participants;

  const AddExpenseForm({super.key, required this.tripId, required this.participants});

  @override
  _AddExpenseFormState createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends State<AddExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;


  // Form field controllers
  final TextEditingController _expenseNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // Other state variables
  int? _selectedPaidBy;
  String _selectedSplitType = 'Equal';
  Map<int, bool> _customEqualSelection = {};
  Map<int, TextEditingController> _manualAmounts = {};

  @override
  void initState() {
    super.initState();
    setState(() => _isLoading = true);
    // Initialize customEqualSelection and manualAmounts for all participants
    for (var participant in widget.participants) {
      _customEqualSelection[participant['participantId']] = false;
      _manualAmounts[participant['participantId']] = TextEditingController();
    }
    setState(() => _isLoading = false);
  }

  void _submitForm() async {
    setState(() => _isLoading = true);
    if (_formKey.currentState!.validate()) {
      // Collect form data
      String expenseName = _expenseNameController.text;

      double amount = double.tryParse(_amountController.text) ?? 0.0;
      if (expenseName.toLowerCase() == 'settlement') {
        setState(() => _isLoading = false); // Stop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Expense name cannot be "Settlement".')),
        );
        return; // Stop further execution and keep form open
      }
      if (_selectedSplitType == 'Manual') {
        // Sum the amounts entered for each participant
        for (var participant in widget.participants) {
          double manualAmount = double.tryParse(
            _manualAmounts[participant['participantId']]?.text ?? '0.0',
          ) ?? 0.0;
          amount += manualAmount; // Add each participant's manual amount to total
        }}
      int paidBy = _selectedPaidBy ?? 0;
      String splitType = _selectedSplitType;
      String? description = _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null;
      DateTime expenseDate = _selectedDate;

      // Insert expense and get expenseId
      int? expenseId = await ApiService().insertExpense(expenseName, amount, paidBy, splitType, widget.tripId, description, expenseDate,);

      if (expenseId != null) {
        // Insert expense splits based on the selected split type
        switch (splitType) {
          case 'Equal':
          // Split equally between all participants
            double equalAmount = amount / widget.participants.length;
            for (var participant in widget.participants) {
              bool success = await ApiService().insertExpenseSplit(expenseId,participant['participantId'],equalAmount,widget.tripId,);
              if (!success) {
                print('Failed to insert split for ${participant['participantName']}');
              }
            }
            break;

          case 'Custom (Equal)':
          // Split only between selected participants
            List selectedParticipants = widget.participants
                .where((participant) => _customEqualSelection[participant['participantId']] == true)
                .map((participant) => participant['participantId'])
                .toList();

            if (selectedParticipants.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select at least one participant for the custom split.')),
              );
              return;
            }

            double customAmount = amount / selectedParticipants.length;

            for (var participant in selectedParticipants) {
              bool success = await ApiService().insertExpenseSplit(expenseId,participant,customAmount,widget.tripId,);

              if (!success) {
                print('Failed to insert split for participant $participant');
              }
            }
            break;

          case 'Manual':
          // Calculate the total manual amount entered
            double totalManualAmount = 0.0;
            Map<int, double> manualAmounts = {};
            for (var participant in widget.participants) {
              double manualAmount = double.tryParse(
                _manualAmounts[participant['participantId']]?.text ?? '0.0',
              ) ?? 0.0;
              totalManualAmount += manualAmount;
              manualAmounts[participant['participantId']] = manualAmount;
            }

            // Check if the manual amounts add up to the total amount
            if (totalManualAmount != amount) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Manual amounts do not match the total amount.')),
              );
              return;
            }

            // Insert manual splits for each participant
            for (var participant in widget.participants) {
              double manualAmount = manualAmounts[participant['participantId']] ?? 0.0;
              if (manualAmount > 0) {
                bool success = await ApiService().insertExpenseSplit(expenseId,participant['participantId'],manualAmount,widget.tripId,);
                if (!success) {
                  print('Failed to insert split for ${participant['participantName']}');
                }
              }
            }
            break;
        }

        showCustomSweetAlert(context, "Your expense saved successfully!", "success", () {
          Navigator.pop(context, true);
        });

      } else {
        // Show error message if expense insertion failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save the expense')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    // Dispose controllers
    _expenseNameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    for (var controller in _manualAmounts.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Widget _buildSplitTypeSpecificFields() {
    switch (_selectedSplitType) {
      case 'Equal':
        return TextFormField(
          controller: _amountController,
          decoration:  _inputDecoration('Total Amount', Icons.monetization_on),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the amount';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        );
      case 'Custom (Equal)':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _amountController,
              decoration:  _inputDecoration('Total Amount', Icons.monetization_on),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the total amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Select Participants:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.teal, width: 1),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                children: widget.participants.map((participant) {
                  return CheckboxListTile(
                    title: Text(
                      participant['participantName'],
                      style: TextStyle(fontSize: 16,color: Colors.teal),
                    ),
                    value: _customEqualSelection[participant['participantId']],
                    activeColor: Colors.teal, // Custom checkbox color
                    checkColor: Colors.white,
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _customEqualSelection[participant['participantId']] = value!;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        );

      case 'Manual':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widget.participants.map((participant) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: _manualAmounts[participant['participantId']],
                decoration: _inputDecoration('${participant['participantName']}\'s Amount', Icons.person),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_selectedSplitType == 'Manual' &&
                      (value == null || value.isEmpty)) {
                    return 'Please enter an amount for ${participant['participantName']}';
                  }
                  if (value != null && double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            );
          }).toList(),
        );
      default:
        return Container();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Add Expense',style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),),
            backgroundColor: Colors.teal,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Expense Name
                    TextFormField(
                      controller: _expenseNameController,
                      decoration: _inputDecoration('Expense Name', Icons.receipt),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the expense name';
                        }
                        return null;
                      },
                    ),

                    // Split Type
                    const SizedBox(height: 16),
                    const Text('Split Type', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                    Column(
                      children: ['Equal', 'Custom (Equal)', 'Manual'].map((type) {
                        return RadioListTile<String>(
                          title: Text(type, style: const TextStyle(color: Colors.teal)),
                          value: type,
                          groupValue: _selectedSplitType,
                          onChanged: (value) => setState(() => _selectedSplitType = value!),
                          activeColor: Colors.teal,
                        );
                      }).toList(),
                    ),

                    // Split Type-specific Fields
                    _buildSplitTypeSpecificFields(),
                    const SizedBox(height: 16),

                    // Paid By
                    DropdownButtonFormField<int>(
                      decoration: _inputDecoration('Paid By', Icons.account_balance_wallet),
                      icon: Icon(Icons.keyboard_arrow_down, color: Colors.teal),
                      style: TextStyle(
                        color: Colors.teal.shade800, // Ensures selected text is teal
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      value: _selectedPaidBy,
                      items: widget.participants
                          .map((participant) => DropdownMenuItem<int>(
                        value: participant['participantId'],
                        child: Row(
                          children: [
                            Icon(Icons.person, color: Colors.teal.shade700),
                            SizedBox(width: 8),
                            Text(
                              participant['participantName'],
                              style: TextStyle(fontSize: 16, color: Colors.teal.shade800, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ))
                          .toList(),
                      selectedItemBuilder: (BuildContext context) {
                        return widget.participants.map<Widget>((participant) {
                          return Text(
                            participant['participantName'],
                            style: TextStyle(fontSize: 16, color: Colors.teal.shade800, fontWeight: FontWeight.w500),
                          );
                        }).toList();
                      },
                      onChanged: (value) {
                        setState(() {
                          _selectedPaidBy = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select who paid';
                        }
                        return null;
                      },
                    ),

                    // Expense Date
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Date: ${DateFormat('dd-MM-yyyy').format(_selectedDate)}', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () => _selectDate(context),
                          child: const Text('Select Date', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: _inputDecoration('Description', Icons.description),
                      maxLines: 3,
                    ),

                    // Submit Button
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _submitForm,
                        child: const Text('Save Expense', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black54, // Semi-transparent background
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white,backgroundColor: Colors.grey,strokeWidth:5.0,),
            ),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.7),
      hintText: label,
      hintStyle: const TextStyle(
        color: Colors.grey, // Customize label text color
        fontSize: 16, // Customize label text size
        fontWeight: FontWeight.w500, // Bold label text
      ),
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.teal, // Customize label text color
        fontSize: 16, // Customize label text size
        fontWeight: FontWeight.w500, // Bold label text
      ),
      prefixIcon: Icon(icon, color: Colors.teal),
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.teal),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.teal), // Focused border color
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}


class EditExpenseForm extends StatefulWidget {
  final int tripId;
  final int expenseId;
  final String expenseName;
  final double amount;
  final int paidBy;
  final String splitType;
  final String? description;
  final DateTime expenseDate;
  final List<Map<String, dynamic>> participants;
  final List<ExpenseSplit> splits; // ParticipantId to Split Amount mapping

  const EditExpenseForm({
    Key? key,
    required this.tripId,
    required this.expenseId,
    required this.expenseName,
    required this.amount,
    required this.paidBy,
    required this.splitType,
    this.description,
    required this.expenseDate,
    required this.participants,
    required this.splits,
  }) : super(key: key);

  @override
  _EditExpenseFormState createState() => _EditExpenseFormState();
}

class _EditExpenseFormState extends State<EditExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form field controllers
  late TextEditingController _expenseNameController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;

  // State variables
  late int _selectedPaidBy;
  late String _selectedSplitType;
  late Map<int, bool> _customEqualSelection;
  late Map<int, TextEditingController> _manualAmounts;
  @override
  void initState() {
    super.initState();
    setState(() => _isLoading = true);
    // Initialize controllers with existing data
    _expenseNameController = TextEditingController(text: widget.expenseName);
    _amountController = TextEditingController(text: widget.amount.toString());
    _descriptionController = TextEditingController(text: widget.description ?? '');
    _selectedDate = widget.expenseDate;
    _selectedPaidBy = widget.paidBy;
    _selectedSplitType = widget.splitType;

    // Map splits to participant IDs for easy access
    final splitMap = {for (var split in widget.splits) split.participantId: split.amount};

    // Initialize selection maps and manual amount controllers
    _customEqualSelection = {
      for (var participant in widget.participants)
        participant['participantId']: splitMap.containsKey(participant['participantId']),
    };

    _manualAmounts = {
      for (var participant in widget.participants)
        participant['participantId']: TextEditingController(
          text: splitMap[participant['participantId']]?.toString() ?? '0.0',
        ),
    };

    setState(() => _isLoading = false);
  }
  void _submitForm() async {
    setState(() => _isLoading = true);
    try{
      if (_formKey.currentState!.validate()) {
        // Collect form data
        String expenseName = _expenseNameController.text;
        double amount = double.tryParse(_amountController.text) ?? 0.0;
        if (expenseName.toLowerCase() == 'settlement') {
          setState(() => _isLoading = false); // Stop loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Expense name cannot be "Settlement".')),
          );
          return; // Stop further execution and keep form open
        }
        int paidBy = _selectedPaidBy;
        String splitType = _selectedSplitType;
        String? description =
        _descriptionController.text.isNotEmpty ? _descriptionController.text : null;
        DateTime expenseDate = _selectedDate;

        // Validate manual split amounts if the split type is 'Manual'
        if (splitType == 'Manual') {
          double totalManualAmount = 0.0;
          for (var participant in widget.participants) {
            double manualAmount = double.tryParse(
              _manualAmounts[participant['participantId']]?.text ?? '0.0',
            ) ?? 0.0;

            // Ensure amount is non-negative
            if (manualAmount < 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Amount for ${participant['participantName']} cannot be negative.')),
              );
              return;
            }

            totalManualAmount += manualAmount;
          }

          amount = totalManualAmount;

        }

        // Update the expense
        bool expenseUpdated = await ApiService().updateExpense(widget.expenseId,expenseName, amount, paidBy, splitType, widget.tripId, description, expenseDate,);

        if (!expenseUpdated) {
          showCustomSweetAlert(context, "Failed to update the expense.", "failure", () {});
          return;
        }

        // Update expense splits
        switch (splitType) {
          case 'Equal':
          // Split equally between all participants
            double equalAmount = amount / widget.participants.length;
            for (var participant in widget.participants) {
              // Find the corresponding splitId for the participant
              var split = widget.splits.firstWhere(
                    (s) => s.participantId == participant['participantId'],
              );


              bool success = await ApiService().updateExpenseSplit(split.splitId,widget.expenseId,participant['participantId'],equalAmount,widget.tripId);

              if (!success) {
                print('Failed to update split for ${participant['participantName']}');
              }
            }
            break;


          case 'Custom (Equal)':
          // Get the selected participants for the custom split
            List<dynamic> selectedParticipants = widget.participants
                .where((participant) => _customEqualSelection[participant['participantId']] == true)
                .map((participant) => participant['participantId'])
                .toList();

            if (selectedParticipants.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select at least one participant for the custom split.')),
              );
              return;
            }

            // Calculate the custom amount for each selected participant
            double customAmount = amount / selectedParticipants.length;

            for (var participantId in selectedParticipants) {
              // Check if a split already exists for the participant
              var split = widget.splits.firstWhere(
                    (s) => s.participantId == participantId,
                orElse: () => ExpenseSplit(
                  splitId: 0, // Default for new splits
                  participantId: participantId,
                  amount: 0.0,
                  expenseId: widget.expenseId,
                  tripId: widget.tripId,
                ),
              );

              if (split.splitId == 0) {
                // Call insertExpenseSplit for new splits
                bool success = await ApiService().insertExpenseSplit(widget.expenseId,participantId,customAmount,widget.tripId,);

                if (!success) {
                  print('Failed to insert split for participant $participantId');
                }
              } else {
                // Update existing splits
                bool success = await ApiService().updateExpenseSplit(split.splitId,widget.expenseId,participantId,customAmount,widget.tripId);

                if (!success) {
                  print('Failed to update split for participant $participantId');
                }
              }
            }

            // Handle participants who were previously part of the split but are no longer selected
            for (var split in widget.splits) {
              if (!selectedParticipants.contains(split.participantId)) {
                bool success = await ApiService().deleteExpenseSplit(split.splitId);
                if (!success) {
                  print('Failed to remove split for participant ${split.participantId}');
                }
              }
            }
            break;




          case 'Manual':

            for (var participant in widget.participants) {
              double manualAmount = double.tryParse(
                _manualAmounts[participant['participantId']]?.text ?? '0.0',
              ) ?? 0.0;

              if (manualAmount < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Amount for ${participant['participantName']} cannot be negative.')),
                );
                continue;
              }

              var split = widget.splits.firstWhere(
                    (s) => s.participantId == participant['participantId'],
                orElse: () => ExpenseSplit(
                  splitId: 0,
                  participantId: participant['participantId'],
                  amount: 0.0,
                  expenseId: widget.expenseId,
                  tripId: widget.tripId,
                ),
              );

              bool success = await ApiService().updateExpenseSplit(split.splitId,widget.expenseId,participant['participantId'],manualAmount,widget.tripId);
              if (!success) {
                print('Failed to update split for ${participant['participantName']}');
              }
            }
            break;
        }

        showCustomSweetAlert(context, "Expense updated successfully!", "success", () {
          Navigator.pop(context);
        });
      }
    }catch(e){
      print("Error updating expense: $e");
    }finally{
      setState(() => _isLoading = false);
    }

  }

  @override
  void dispose() {
    _expenseNameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    for (var controller in _manualAmounts.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }


  Widget _buildSplitTypeSpecificFields() {
    switch (_selectedSplitType) {
      case 'Equal':
        return TextFormField(
          controller: _amountController,
          decoration:  _inputDecoration('Total Amount', Icons.monetization_on),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the amount';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        );
      case 'Custom (Equal)':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _amountController,
              decoration:  _inputDecoration('Total Amount', Icons.monetization_on),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the total amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
                'Select Participants:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.teal, width: 1),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                children: widget.participants.map((participant) {
                  return CheckboxListTile(
                    title: Text(
                      participant['participantName'],
                      style: TextStyle(fontSize: 16,color: Colors.teal),
                    ),
                    value: _customEqualSelection[participant['participantId']],
                    activeColor: Colors.teal, // Custom checkbox color
                    checkColor: Colors.white,
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _customEqualSelection[participant['participantId']] = value!;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        );

      case 'Manual':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widget.participants.map((participant) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: _manualAmounts[participant['participantId']],
                decoration: _inputDecoration('${participant['participantName']}\'s Amount', Icons.person),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_selectedSplitType == 'Manual' &&
                      (value == null || value.isEmpty)) {
                    return 'Please enter an amount for ${participant['participantName']}';
                  }
                  if (value != null && double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            );
          }).toList(),
        );
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: const Text('Edit Expense',style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),),
              backgroundColor: Colors.teal,
              centerTitle: true,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Expense Name
                      TextFormField(
                        controller: _expenseNameController,
                        decoration: _inputDecoration('Expense Name', Icons.receipt),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the expense name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Split Type Dropdown
                      TextFormField(
                        readOnly: true, // Disable editing
                        initialValue: _selectedSplitType,
                        decoration: _inputDecoration('Split Type', Icons.vertical_split),
                      ),
                      const SizedBox(height: 16),

                      // Split Type Specific Fields
                      _buildSplitTypeSpecificFields(),
                      const SizedBox(height: 16),

                      // Paid By Dropdown
                      DropdownButtonFormField<int>(
                        decoration: _inputDecoration('Paid By', Icons.account_balance_wallet),
                        icon: Icon(Icons.keyboard_arrow_down, color: Colors.teal),
                        style: TextStyle(
                          color: Colors.teal.shade800, // Ensures selected text is teal
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        value: _selectedPaidBy,
                        items: widget.participants
                            .map((participant) => DropdownMenuItem<int>(
                          value: participant['participantId'],
                          child: Row(
                            children: [
                              Icon(Icons.person, color: Colors.teal.shade700),
                              SizedBox(width: 8),
                              Text(
                                participant['participantName'],
                                style: TextStyle(fontSize: 16, color: Colors.teal.shade800, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ))
                            .toList(),
                        selectedItemBuilder: (BuildContext context) {
                          return widget.participants.map<Widget>((participant) {
                            return Text(
                              participant['participantName'],
                              style: TextStyle(fontSize: 16, color: Colors.teal.shade800, fontWeight: FontWeight.w500),
                            );
                          }).toList();
                        },
                        onChanged: (value) {
                          setState(() {
                            _selectedPaidBy = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select who paid';
                          }
                          return null;
                        },
                      ),

                      // Expense Date
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Date: ${DateFormat('dd-MM-yyyy').format(_selectedDate)}', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () => _selectDate(context),
                            child: const Text('Select Date', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: _inputDecoration('Description', Icons.description),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      // Update Expense Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _submitForm,
                          child: const Text('Update Expense', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54, // Semi-transparent background
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white,backgroundColor: Colors.grey,strokeWidth:5.0,),
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.7),
      hintText: label,
      hintStyle: const TextStyle(
        color: Colors.grey, // Customize label text color
        fontSize: 16, // Customize label text size
        fontWeight: FontWeight.w500, // Bold label text
      ),
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.teal, // Customize label text color
        fontSize: 16, // Customize label text size
        fontWeight: FontWeight.w500, // Bold label text
      ),
      prefixIcon: Icon(icon, color: Colors.teal),
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.teal),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.teal), // Focused border color
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

}
