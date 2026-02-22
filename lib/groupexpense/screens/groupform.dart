// lib/screens/add_edit_group_form.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../model/participant_model.dart';
import '../service/group_service.dart';


class AddEditGroupForm extends StatefulWidget {
  final Map<String, dynamic>? groupDetails; // optional: {"group":..., "participants":[...]}
  const AddEditGroupForm({Key? key, this.groupDetails}) : super(key: key);

  @override
  State<AddEditGroupForm> createState() => _AddEditGroupFormState();
}

class _AddEditGroupFormState extends State<AddEditGroupForm> {
  final _groupService = GroupService();

  final TextEditingController _groupNameController = TextEditingController();
  List<ParticipantModel> _members = [];
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.groupDetails != null) {
      _groupNameController.text = widget.groupDetails!['group']['group_name'] as String;
      final parts = widget.groupDetails!['participants'] as List<dynamic>;
      _members = parts.map((p) => ParticipantModel.fromMap(p)).toList();
    }
  }

  Future<void> _pickImageForMember(int index) async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _members[index].imagePath = file.path);
    }
  }

  void _addMemberDialog() {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final key = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Member'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: _inputDecoration("Name", Icons.person),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: mobileCtrl,
                decoration: _inputDecoration("Mobile", Icons.phone),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (!key.currentState!.validate()) return;
              setState(() {
                _members.add(ParticipantModel(
                  groupId: 0,
                  participantName: nameCtrl.text.trim(),
                  mobile: mobileCtrl.text.trim(),
                ));
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
  }

  void _editMemberDialog(int index) {
    final nameCtrl = TextEditingController(text: _members[index].participantName);
    final mobileCtrl = TextEditingController(text: _members[index].mobile);
    final key = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Member'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: nameCtrl, decoration: _inputDecoration("Name", Icons.person), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
              TextFormField(controller: mobileCtrl, decoration: _inputDecoration("Mobile", Icons.phone), keyboardType: TextInputType.phone, validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (!key.currentState!.validate()) return;
              setState(() {
                _members[index].participantName = nameCtrl.text.trim();
                _members[index].mobile = mobileCtrl.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  Future<void> _saveGroup() async {
    final name = _groupNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group name required')));
      return;
    }
    if (_members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one member')));
      return;
    }

    setState(() => _isLoading = true);

    if (widget.groupDetails == null) {
      // create
      final createdId = await _groupService.createGroupWithParticipants(
        groupName: name,
        participants: _members.map((m) => ParticipantModel(groupId: 0, participantName: m.participantName, mobile: m.mobile, imagePath: m.imagePath)).toList(),
      );
      // you can use createdId if needed
    } else {
      // update
      final groupId = widget.groupDetails!['group']['group_id'] as int;
      await _groupService.updateGroupWithParticipants(
        groupId: groupId,
        newGroupName: name,
        participants: _members.map((m) => ParticipantModel(groupId: groupId, participantName: m.participantName, mobile: m.mobile, imagePath: m.imagePath)).toList(),
      );
    }

    setState(() => _isLoading = false);
    Navigator.pop(context, true); // return success
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupDetails == null ? 'Add Group' : 'Edit Group'),
        backgroundColor: Colors.teal,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveGroup,
        child: const Icon(Icons.save),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _groupNameController,
                  decoration: _inputDecoration("Name", Icons.person),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Members', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: _addMemberDialog, icon: const Icon(Icons.add_circle, color: Colors.teal)),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _members.length,
                    itemBuilder: (_, i) => Card(
                      child: ListTile(
                        leading: GestureDetector(
                          onTap: () => _pickImageForMember(i),
                          child: CircleAvatar(
                            backgroundImage: _members[i].imagePath != null ? FileImage(File(_members[i].imagePath!)) : null,
                            child: _members[i].imagePath == null ? const Icon(Icons.person) : null,
                          ),
                        ),
                        title: Text(_members[i].participantName),
                        subtitle: Text(_members[i].mobile),
                        onTap: () => _editMemberDialog(i),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setState(() => _members.removeAt(i)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(color: Colors.black45, child: const Center(child: CircularProgressIndicator())),
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
