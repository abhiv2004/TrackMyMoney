import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../database/group_expense_db.dart';

class ParticipantModel {
  int? participantId;
  String name;
  String mobile;
  File? image;

  ParticipantModel({
    this.participantId,
    required this.name,
    required this.mobile,
    this.image,
  });
}

class GroupFormScreen extends StatefulWidget {
  final int? groupId;

  const GroupFormScreen({Key? key, this.groupId}) : super(key: key);

  @override
  State<GroupFormScreen> createState() => _GroupFormScreenState();
}

class _GroupFormScreenState extends State<GroupFormScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  List<ParticipantModel> _participants = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.groupId != null) {
      _loadGroupData();
    }
  }

  // ====================================
  // LOAD EXISTING GROUP
  // ====================================
  Future<void> _loadGroupData() async {
    setState(() => _isLoading = true);

    final data = await GroupExpenseDB.instance
        .getGroupWithParticipants(widget.groupId!);

    final group = data['group'];
    final participants = data['participants'];

    _groupNameController.text = group['group_name'];
    _selectedDate = group['date'];

    _participants = participants.map<ParticipantModel>((p) {
      return ParticipantModel(
        participantId: p['participant_id'],
        name: p['participant_name'],
        mobile: p['mobile'] ?? '',
      );
    }).toList();

    setState(() => _isLoading = false);
  }

  // ====================================
  // PICK IMAGE
  // ====================================
  Future<void> _pickImage(int index) async {
    PermissionStatus status = await Permission.photos.request();

    if (status.isGranted) {
      final XFile? picked =
          await _picker.pickImage(source: ImageSource.gallery);

      if (picked != null) {
        setState(() {
          _participants[index].image = File(picked.path);
        });
      }
    }
  }

  // ====================================
  // SAVE GROUP
  // ====================================
  Future<void> _saveGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Group name required")));
      return;
    }

    if (_participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Add at least one participant")));
      return;
    }

    setState(() => _isLoading = true);

    if (widget.groupId == null) {
      // ADD NEW
      await GroupExpenseDB.instance.addGroupWithParticipants(
        groupName: _groupNameController.text,
        dateIso: DateTime.now().toIso8601String(),
        participants: _participants.map((p) {
          return {
            'name': p.name,
            'mobile': p.mobile,
            'image': p.image?.path
          };
        }).toList(),
      );
    } else {
      // UPDATE
      await GroupExpenseDB.instance.updateGroupWithParticipants(
        groupId: widget.groupId!,
        groupName: _groupNameController.text,
        participants: _participants.map((p) {
          return {
            'participant_id': p.participantId,
            'name': p.name,
            'mobile': p.mobile,
            'image': p.image?.path
          };
        }).toList(),
      );
    }

    setState(() => _isLoading = false);
    Navigator.pop(context);
  }

  // ====================================
  // ADD PARTICIPANT DIALOG
  // ====================================
  void _addParticipant() {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Participant"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: _inputDecoration("Name", Icons.person),
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter name" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: mobileController,
                decoration: _inputDecoration("Mobile", Icons.phone),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.length != 10 ? "Enter valid mobile" : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    _participants.add(ParticipantModel(
                        name: nameController.text,
                        mobile: mobileController.text));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"))
        ],
      ),
    );
  }

  // ====================================
  // BUILD UI
  // ====================================
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(widget.groupId == null
                ? "Create Group"
                : "Update Group"),
            backgroundColor: Colors.teal,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _groupNameController,
                  decoration:
                      _inputDecoration("Group Name", Icons.group),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Participants",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    IconButton(
                        onPressed: _addParticipant,
                        icon: const Icon(Icons.add_circle,
                            color: Colors.teal))
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: _participants.length,
                    itemBuilder: (_, index) {
                      return Card(
                        child: ListTile(
                          leading: GestureDetector(
                            onTap: () => _pickImage(index),
                            child: CircleAvatar(
                              backgroundImage:
                                  _participants[index].image != null
                                      ? FileImage(
                                          _participants[index].image!)
                                      : null,
                              child:
                                  _participants[index].image == null
                                      ? const Icon(Icons.add_a_photo)
                                      : null,
                            ),
                          ),
                          title: Text(_participants[index].name),
                          subtitle:
                              Text(_participants[index].mobile),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _participants.removeAt(index);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: _saveGroup,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 80, vertical: 15)),
                  child: const Text("Save Group",
                      style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
                child: CircularProgressIndicator(
                    color: Colors.white)),
          )
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.teal),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: Colors.teal)),
    );
  }
}