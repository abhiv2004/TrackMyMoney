import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/groupdatabase.dart';
import 'groupform.dart';
import 'groupdetailspage.dart';

class GroupListPage extends StatefulWidget {
  const GroupListPage({Key? key}) : super(key: key);

  @override
  _GroupListPageState createState() => _GroupListPageState();
}

class _GroupListPageState extends State<GroupListPage> {
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshGroups();
  }

  Future<void> _refreshGroups() async {
    setState(() => _isLoading = true);
    final data = await GroupExpenseDB.instance.getAllGroups();
    setState(() {
      _groups = data;
      _isLoading = false;
    });
  }

  void _deleteGroup(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Group"),
        content: const Text("Are you sure you want to delete this group and all its expenses?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await GroupExpenseDB.instance.deleteGroup(id);
      _refreshGroups();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Group Expense", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade50, Colors.white],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "All Groups",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _groups.isEmpty
                      ? const Center(child: Text("No groups yet. Tap + to create one!"))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _groups.length,
                          itemBuilder: (context, index) {
                            final group = _groups[index];
                            return Dismissible(
                              key: Key(group['group_id'].toString()),
                              background: Container(
                                color: Colors.blue,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 20),
                                child: const Icon(Icons.edit, color: Colors.white),
                              ),
                              secondaryBackground: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.startToEnd) {
                                  // Edit
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => GroupForm(groupId: group['group_id'])),
                                  );
                                  _refreshGroups();
                                  return false;
                                } else {
                                  // Delete
                                  _deleteGroup(group['group_id']);
                                  return false;
                                }
                              },
                              child: Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.teal.shade100,
                                    child: const Icon(Icons.group, color: Colors.teal),
                                  ),
                                  title: Text(group['group_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  subtitle: Text(
                                    group['date'] != null 
                                      ? "Created: ${DateFormat('dd MMM yyyy').format(DateTime.parse(group['date']))}"
                                      : "",
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                  trailing: const Icon(Icons.chevron_right, color: Colors.teal),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => GroupDetailsPage(groupId: group['group_id'], groupName: group['group_name'])),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const GroupForm()));
          _refreshGroups();
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}
