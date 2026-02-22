import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';
import 'package:url_launcher/url_launcher.dart';

class ParticipantDetails extends StatefulWidget {
  final int id;
  final String name;

  const ParticipantDetails({required this.id, required this.name, super.key});

  @override
  State<ParticipantDetails> createState() => _ParticipantDetailsState();
}

class _ParticipantDetailsState extends State<ParticipantDetails> {
  List transactions = [];
  final TextEditingController amountC = TextEditingController();
  final TextEditingController remarksC = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    transactions =
    await DualExpenseDB.instance.getUserTransactions(widget.id);
    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });
  }

  // ================= BALANCE =================
  double getBalance() {
    double balance = 0;
    for (var t in transactions) {
      if (t["type"] == 1) {
        balance += t["amount"];
      } else {
        balance -= t["amount"];
      }
    }
    return balance;
  }

  // ================= SUMMARY CARD =================
  Widget _buildSummaryCard() {
    double balance = getBalance();
    bool isOwe = balance > 0;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOwe
              ? [Colors.red.shade400, Colors.red.shade600]
              : [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isOwe ? "You owe" : "You get",
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            "₹ ${balance.abs().toStringAsFixed(2)}",
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ================= ADD / EDIT =================
  void addTransaction(int type) {
    amountC.clear();
    remarksC.clear();
    _showTransactionDialog(type: type);
  }

  void editTransaction(Map t) {
    amountC.text = t["amount"].toString();
    remarksC.text = t["remarks"] ?? "";
    _showTransactionDialog(type: t["type"], transaction: t);
  }

  void _showTransactionDialog({required int type, Map? transaction}) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                transaction == null
                    ? (type == 1 ? "Given Money" : "Received Money")
                    : "Edit Transaction",
                style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: amountC,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: "Amount"),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: remarksC,
                decoration: const InputDecoration(labelText: "Remarks"),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (transaction != null)
                    TextButton(
                      onPressed: () async {
                        await DualExpenseDB.instance
                            .deleteTransaction(transaction["id"]);
                        Navigator.pop(context);
                        loadTransactions();
                      },
                      child:
                      const Text("Delete", style: TextStyle(color: Colors.red)),
                    ),

                  ElevatedButton(
                    onPressed: () async {
                      double? amount = double.tryParse(amountC.text);
                      if (amount == null) return;

                      if (transaction != null) {
                        await DualExpenseDB.instance.updateTransaction(
                          transaction["id"],
                          amount,
                          type,
                          remarks: remarksC.text,
                        );
                      } else {
                        await DualExpenseDB.instance.addTransaction(
                          widget.id,
                          amount,
                          type,
                          remarks: remarksC.text,
                        );
                      }

                      Navigator.pop(context);
                      loadTransactions();
                    },
                    child: const Text("Save"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // ================= WHATSAPP =================
  void sendMessageReminder() async {
    double balance = getBalance();
    if (balance <= 0) return;

    String message =
        "Hello ${widget.name}, pending amount ₹${balance.toStringAsFixed(2)}";

    final uri = Uri.parse(
        "https://wa.me/?text=${Uri.encodeComponent(message)}");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: sendMessageReminder,
          ),
        ],
      ),

      body: Column(
        children: [
          _buildSummaryCard(),

          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: transactions.length,
              itemBuilder: (ctx, i) {
                final t = transactions[i];
                bool isGiven = t["type"] == 1;

                DateTime dt = DateTime.parse(t["date"]);
                String date =
                DateFormat('dd MMM, hh:mm a').format(dt);

                return GestureDetector(
                  onTap: () => editTransaction(t),
                  child: Align(
                    alignment: isGiven
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(maxWidth: 280),
                      decoration: BoxDecoration(
                        color:
                        isGiven ? Colors.red[100] : Colors.green[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("₹ ${t["amount"]}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),

                          if (t["remarks"] != null &&
                              t["remarks"].toString().isNotEmpty)
                            Text(t["remarks"]),

                          const SizedBox(height: 4),

                          Text(date,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () => addTransaction(-1),
                child: const Text("Received"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () => addTransaction(1),
                child: const Text("Given"),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 


/*
import 'dart:io';

import 'package:flutter/material.dart';
import '../database/database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ParticipantDetails extends StatefulWidget {
  final int id;
  final String name;

  const ParticipantDetails({required this.id, required this.name, super.key});

  @override
  State<ParticipantDetails> createState() => _ParticipantDetailsState();
}

class _ParticipantDetailsState extends State<ParticipantDetails> {
  List transactions = [];
  final TextEditingController amountC = TextEditingController();
  final TextEditingController remarksC = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final TextStyle _amountTextStyle = const TextStyle(fontSize: 16, color: Colors.black);
  final TextStyle _remarkTextStyle = TextStyle(fontSize: 12, color: Colors.grey[900]);
  final TextStyle _dateTextStyle = TextStyle(fontSize: 12, color: Colors.grey[800]);

  final ButtonStyle _btnStyle = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    transactions = await DualExpenseDB.instance.getUserTransactions(widget.id);
    setState(() {});
    // Scroll to bottom after frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });
  }

  void addTransaction(int type) {
    amountC.clear();
    remarksC.clear();

    _showTransactionDialog(
      title: type == 1 ? "Given Money" : "Received Money",
      type: type,
    );
  }

  void editOrDeleteTransaction(Map<String, dynamic> t) {
    amountC.text = t["amount"].toString();
    remarksC.text = t["remarks"] ?? "";

    _showTransactionDialog(
      title: "Edit Transaction",
      type: t["type"],
      transaction: t,
    );
  }

  void _showTransactionDialog({
    required String title,
    required int type,
    Map<String, dynamic>? transaction,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                controller: amountC,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Amount",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: remarksC,
                minLines: 1,
                maxLines: 3,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: "Remarks (optional)",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  counterText: "",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (transaction != null)
                    TextButton(
                      onPressed: () async {
                        await DualExpenseDB.instance.deleteTransaction(transaction["id"]);
                        Navigator.pop(context);
                        amountC.clear();
                        remarksC.clear();
                        loadTransactions();

                      },
                      child: const Text("Delete", style: TextStyle(color: Colors.red, fontSize: 16)),
                    ),
                  if (transaction != null) const SizedBox(width: 10),
                  ElevatedButton(
                    style: _btnStyle.copyWith(
                      backgroundColor: MaterialStateProperty.all(transaction != null ? Colors.blue : Colors.green),
                    ),
                    onPressed: () async {
                      if (amountC.text.isEmpty) return;
                      double? amount = double.tryParse(amountC.text);
                      if (amount == null) return;

                      if (transaction != null) {
                        await DualExpenseDB.instance.updateTransaction(
                          transaction["id"],
                          amount,
                          type,
                          remarks: remarksC.text,
                        );
                      } else {
                        await DualExpenseDB.instance.addTransaction(
                          widget.id,
                          amount,
                          type,
                          remarks: remarksC.text,
                        );
                      }
                      Navigator.pop(context);
                      amountC.clear();
                      remarksC.clear();
                      loadTransactions();

                    },
                    child: const Text("Save", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel", style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Future<String?> _showMobileNumberDialog(String? existingNumber) async {
    TextEditingController mobileC = TextEditingController(text: existingNumber);
    String? result;
     await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enter Mobile Number",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: mobileC,
                keyboardType: TextInputType.phone,
                maxLength: 15,
                decoration: InputDecoration(
                  labelText: "Mobile Number",
                  hintText: "e.g. 919876543210",
                  counterText: "",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      String input = mobileC.text.trim();

                      // Auto-add +91 if only 10 digits are entered
                      if (RegExp(r'^\d{10}$').hasMatch(input)) {
                        input = '+91$input';
                      }

                      // Validate number format
                      if (RegExp(r'^\+91\d{10}$').hasMatch(input)) {
                        result = input;
                        Navigator.pop(ctx);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Enter a valid 10-digit number"),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      "Save",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result;
  }


  void sendMessageReminder() async {
    // Fetch participant info
    var participant = (await DualExpenseDB.instance.getParticipants())
        .firstWhere((p) => p["id"] == widget.id);

    String? mobile = participant["mobile"];

    // Ask for mobile number if not set
    if (mobile == null || mobile.isEmpty) {
      mobile = await _showMobileNumberDialog(mobile);
      if (mobile != null && mobile.isNotEmpty) {
        await DualExpenseDB.instance.updateParticipant(
          widget.id,
          participant["name"],
          mobile: mobile,
        );
      }
    }

    if (mobile == null || mobile.isEmpty) return; // Stop if no mobile

    // Calculate participant balance
    double balance = 0;
    var transactions = await DualExpenseDB.instance.getUserTransactions(widget.id);
    for (var t in transactions) {
      if (t["type"] == 1) {
        balance += t["amount"]; // Given
      } else {
        balance -= t["amount"]; // Received
      }
    }

    // Only proceed if balance is positive
    if (balance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No pending balance to remind.")),
      );
      return;
    }

    String appName = "MyAccountApp"; // Replace with your app name
    String message =
        "Hello ${widget.name},\n\nThis is a gentle reminder from $appName that an amount of ₹${balance.toStringAsFixed(2)} is pending. Kindly make the payment at your earliest convenience.\n\nThank you!";

    final encodedMessage = Uri.encodeComponent(message);

    // WhatsApp Web URL (most reliable)
    final whatsappUri = Uri.parse("https://wa.me/$mobile?text=$encodedMessage");

    // SMS URL fallback
    final smsUri = Uri.parse("sms:$mobile?body=$encodedMessage");

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      } else {
        print("Could not launch WhatsApp or SMS.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch WhatsApp or SMS")),
        );
      }
    } catch (e) {
      print("Error launching message: $e");
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            tooltip: "Send WhatsApp Reminder",
            onPressed:sendMessageReminder,
          ),
        ],
      ),

      body: ListView.builder(
        controller: scrollController,
        itemCount: transactions.length,
        itemBuilder: (ctx, i) {
          final t = transactions[i];
          bool isGiven = t["type"] == 1;

          DateTime dt = DateTime.parse(t["date"]);
          String formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dt);

          return GestureDetector(
            onTap: () => editOrDeleteTransaction(t),
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: isGiven ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                    decoration: BoxDecoration(
                      color: isGiven ? Colors.red[200] : Colors.green[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("₹ ${t["amount"]}", style: _amountTextStyle),
                        if (t["remarks"] != null && t["remarks"].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 250),
                              child: Text(t["remarks"], style: _remarkTextStyle, softWrap: true),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(formattedDate, style: _dateTextStyle),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 40),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  fixedSize: const Size.fromHeight(45),
                ),
                onPressed: () => addTransaction(-1),
                child: const Text("Received", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  fixedSize: const Size.fromHeight(45),
                ),
                onPressed: () => addTransaction(1),
                child: const Text("Given", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/
