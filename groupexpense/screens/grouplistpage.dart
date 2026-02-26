import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/group_expense_db.dart';
import 'group_form_screen.dart';

class GroupHomeScreen extends StatefulWidget {
  const GroupHomeScreen({Key? key}) : super(key: key);

  @override
  State<GroupHomeScreen> createState() => _GroupHomeScreenState();
}

class _GroupHomeScreenState extends State<GroupHomeScreen> {
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  // ===============================
  // LOAD ALL GROUPS
  // ===============================
  Future<void> _loadGroups() async {
    final data = await GroupExpenseDB.instance.getAllGroups();

    setState(() {
      _groups = data;
      _isLoading = false;
    });
  }

  // ===============================
  // DELETE GROUP CONFIRMATION
  // ===============================
  void _confirmDelete(int groupId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Group"),
        content: const Text("Are you sure you want to delete this group?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Delete"),
            onPressed: () async {
              Navigator.pop(context);
              await GroupExpenseDB.instance
                  .deleteGroupWithEverything(groupId);
              _loadGroups();
            },
          ),
        ],
      ),
    );
  }

  // ===============================
  // NAVIGATE TO FORM
  // ===============================
  Future<void> _openForm({int? groupId}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupFormScreen(groupId: groupId),
      ),
    );

    _loadGroups(); // Refresh after returning
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Group Expense",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? const Center(
                  child: Text(
                    "No Groups Found.\nClick + to add new group.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _groups.length,
                  itemBuilder: (context, index) {
                    final group = _groups[index];

                    return Dismissible(
                      key: ValueKey(group['group_id']),
                      background: _buildRightSwipeBackground(),
                      secondaryBackground:
                          _buildLeftSwipeBackground(),
                      confirmDismiss: (direction) async {
                        if (direction ==
                            DismissDirection.endToStart) {
                          // LEFT SWIPE → DELETE
                          _confirmDelete(group['group_id']);
                          return false;
                        } else {
                          // RIGHT SWIPE → EDIT
                          _openForm(groupId: group['group_id']);
                          return false;
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(
                            group['group_name'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            group['date'] != null
                                ? DateFormat('dd-MM-yyyy')
                                    .format(DateTime.parse(
                                        group['date']))
                                : "",
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
        onPressed: () => _openForm(),
      ),
    );
  }

  // ===============================
  // RIGHT SWIPE (EDIT)
  // ===============================
  Widget _buildRightSwipeBackground() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      color: Colors.blue,
      child: const Icon(Icons.edit, color: Colors.white),
    );
  }

  // ===============================
  // LEFT SWIPE (DELETE)
  // ===============================
  Widget _buildLeftSwipeBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      color: Colors.red,
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }
}