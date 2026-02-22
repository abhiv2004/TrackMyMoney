// lib/screens/groups_page.dart
import 'package:flutter/material.dart';

import '../service/group_service.dart';
import 'groupform.dart';


class GroupsPage extends StatefulWidget {
  const GroupsPage({Key? key}) : super(key: key);

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final _service = GroupService();
  List<Map<String, dynamic>> groups = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => loading = true);
    groups = await _service.getAllGroups();
    setState(() => loading = false);
  }

  Future<void> _openAdd() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditGroupForm()),
    );
    if (res == true) _loadGroups();
  }

  Future<void> _openEdit(int groupId) async {
    final details = await _service.getGroupWithParticipants(groupId);
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditGroupForm(groupDetails: details)),
    );
    if (res == true) _loadGroups();
  }

  Future<void> _confirmDelete(int groupId, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text("Delete '$name'? This removes participants too."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await _service.deleteGroup(groupId);
      _loadGroups();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups Expense'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : groups.isEmpty
          ? const Center(child: Text('No groups yet'))
          : ListView.builder(
        itemCount: groups.length,
        itemBuilder: (_, i) {
          final g = groups[i];
          return Dismissible(
            key: Key(g['group_id'].toString()),
            background: Container(color: Colors.blue, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 16), child: const Icon(Icons.edit, color: Colors.white)),
            secondaryBackground: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.white)),
            confirmDismiss: (dir) async {
              if (dir == DismissDirection.startToEnd) {
                _openEdit(g['group_id'] as int);
                return false;
              } else {
                await _confirmDelete(g['group_id'] as int, g['group_name'] as String);
                return false;
              }
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.group)),
                title: Text(g['group_name'] as String),
                subtitle: Text('Created: ${DateTime.parse(g['date'] as String).toLocal().toString().split(' ')[0]}'),
                onTap: () => null,
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        child: const Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
    );
  }
}
