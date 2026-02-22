import 'package:billtracker/dualexpense/screens/participant_form.dart';
import 'package:billtracker/dualexpense/screens/transaction.dart';
import 'package:flutter/material.dart';
import '../database/database.dart';

class Accountspage extends StatefulWidget {
  const Accountspage({super.key});

  @override
  State<Accountspage> createState() => _AccountspageState();
}

class _AccountspageState extends State<Accountspage> {
  List participants = [];
  double totalGiven = 0;
  double totalReceived = 0;


  Map<int, double> participantBalances = {};
  Map<int, double> participantGiven = {};
  Map<int, double> participantReceived = {};

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    await fetchUsers();
    await calculateTotals();
  }

  Future<void> fetchUsers() async {
    participants = await DualExpenseDB.instance.getParticipants();
    participantBalances.clear();
    participantGiven.clear();
    participantReceived.clear();

    for (var p in participants) {
      var transactions = await DualExpenseDB.instance.getUserTransactions(
          p["id"]);

      double given = 0;
      double received = 0;

      for (var t in transactions) {
        if (t["type"] == 1) given += t["amount"];
        if (t["type"] == -1) received += t["amount"];
      }

      participantGiven[p["id"]] = given;
      participantReceived[p["id"]] = received;
      participantBalances[p["id"]] = received - given;
    }

    setState(() {});
  }

  Future<void> calculateTotals() async {
    totalGiven = 0;
    totalReceived = 0;

    for (var p in participants) {
      var transactions = await DualExpenseDB.instance.getUserTransactions(
          p["id"]);
      for (var t in transactions) {
        if (t["type"] == 1) totalGiven += t["amount"];
        if (t["type"] == -1) totalReceived += t["amount"];
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery
        .of(context)
        .size;
    final double cardPadding = size.width * 0.03;
    final double cardRadius = size.width * 0.05;
    final double fontsize = size.width * 0.05;

    return Scaffold(

      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xff1f1c2c), Color(0xff928dab)],
              ),
            ),
          ),
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              height: 240,
              width: 240,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDashboard(size),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Participants",
                            style: TextStyle(
                                fontSize: fontsize,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1),
                          ),
                        ),
                        Expanded(child: _buildParticipantList(
                            cardPadding, cardRadius)),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ],),

      floatingActionButton: _buildAddButton(),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            "Dual Expenses",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

        ],
      ),
    );
  }


  Widget _buildDashboard(Size size) {
    return Row(
      children: [
        Expanded(child: _modernCard("Given", totalGiven, Colors.red)),
        const SizedBox(width: 10),
        Expanded(child: _modernCard("Received", totalReceived, Colors.green)),
      ],
    );
  }

  Widget _modernCard(String title, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.7), color],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            "₹ ${value.toStringAsFixed(2)}",
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantList(double padding, double radius) {
    final size = MediaQuery
        .of(context)
        .size;
    final double fontsize = size.width * 0.05;

    return ListView.separated(
      itemCount: participants.length,
      itemBuilder: (ctx, i) {
        final p = participants[i];
        double balance = participantBalances[p["id"]] ?? 0;
        double given = participantGiven[p["id"]] ?? 0;
        double received = participantReceived[p["id"]] ?? 0;

        return Dismissible(
          key: Key(p["id"].toString()),
          background:
          _buildDismissibleBg(Colors.blue, Icons.edit, Alignment.centerLeft),
          secondaryBackground: _buildDismissibleBg(
              Colors.red, Icons.delete, Alignment.centerRight),

          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              await showDialog(
                context: context,
                builder: (_) => ParticipantForm(participant: p),
              );

              loadData();
              return false;
            } else if (direction == DismissDirection.endToStart) {
              return await _confirmDelete(p);
            }
            return false;
          },

          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ParticipantDetails(
                    id: p["id"],
                    name: p["name"],
                  ),
                ),
              );

              // Refresh after coming back
              loadData();
            },

            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(radius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              padding: EdgeInsets.all(padding),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.indigo,
                    child: Text(
                      p["name"][0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),

                  SizedBox(width: padding),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p["name"],
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),

                        Row(
                          children: [
                            Text(
                              "Given: ₹${given.toStringAsFixed(0)}",
                              style: const TextStyle(color: Colors.red),
                            ),

                            const SizedBox(width: 8),

                            Container(
                              height: 14,
                              width: 1,
                              color: Colors.grey,
                            ),

                            const SizedBox(width: 8),

                            Text(
                              "Receive: ₹${received.toStringAsFixed(0)}",
                              style: const TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "₹${balance.abs().toStringAsFixed(0)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: balance > 0 ? Colors.red : Colors.green,
                        ),
                      ),
                      Text(
                        balance > 0 ? "You owe" : "You get",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },

      separatorBuilder: (_, __) => const SizedBox(height: 3),
    );
  }

  Widget _buildDismissibleBg(Color color, IconData icon, Alignment align) {
    return Container(
      color: color,
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(icon, color: Colors.white),
    );
  }

  Widget _buildAddButton() {
    return FloatingActionButton.extended(
      onPressed: () async {
        final result = await showDialog(
          context: context,
          builder: (_) => const ParticipantForm(),
        );

        if (result == true) loadData();
      },
      backgroundColor: Colors.green,
      label: const Text("Add New",
          style:
          TextStyle(
              fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
      icon: const Icon(Icons.add, color: Colors.white),
    );
  }

  Future<bool> _confirmDelete(Map p) async {
    bool confirm = false;
    await showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: const Text("Delete Participant"),
            content: Text("Are you sure you want to delete ${p["name"]}?"),
            actions: [
              TextButton(
                onPressed: () {
                  confirm = true;
                  Navigator.pop(context);
                },
                child: const Text("Yes"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("No"),
              ),
            ],
          ),
    );

    if (confirm) {
      await DualExpenseDB.instance.deleteParticipant(p["id"]);
      loadData();
    }
    return confirm;
  }
}
  /// ----------------------------
  /// ADD / UPDATE PARTICIPANT POPUP
  /// ----------------------------}
