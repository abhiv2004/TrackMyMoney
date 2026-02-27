import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database/groupdatabase.dart';
import '../models/participant_model.dart';

class GroupForm extends StatefulWidget {
  final int? groupId;
  const GroupForm({Key? key, this.groupId}) : super(key: key);

  @override
  _GroupFormState createState() => _GroupFormState();
}

class _GroupFormState extends State<GroupForm> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  List<ParticipantModel> _participants = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.groupId != null) {
      _loadGroupData();
    }
  }

  Future<void> _loadGroupData() async {
    setState(() => _isLoading = true);
    final data = await GroupExpenseDB.instance.getGroupWithParticipants(widget.groupId!);
    setState(() {
      _groupNameController.text = data['group']['group_name'];
      _participants = (data['participants'] as List).map((p) => ParticipantModel.fromMap(p)).toList();
      _isLoading = false;
    });
  }

  void _addParticipantPopup() {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    String? imagePath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add Participant"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      setDialogState(() => imagePath = picked.path);
                    }
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.teal.shade100,
                    backgroundImage: imagePath != null ? FileImage(File(imagePath!)) : null,
                    child: imagePath == null ? const Icon(Icons.add_a_photo, color: Colors.teal) : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Participant Name", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mobileController,
                  decoration: const InputDecoration(labelText: "Mobile Number", border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _participants.add(ParticipantModel(
                      name: nameController.text,
                      mobile: mobileController.text,
                      imagePath: imagePath,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add at least one participant")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (widget.groupId == null) {
        // Create new
        await GroupExpenseDB.instance.addGroupWithParticipants(
          groupName: _groupNameController.text.trim(),
          dateIso: DateTime.now().toIso8601String(),
          participants: _participants.map((p) => p.toMap()).toList(),
        );
      } else {
        // Update existing
        await GroupExpenseDB.instance.updateGroupWithParticipants(
          groupId: widget.groupId!,
          groupName: _groupNameController.text.trim(),
          participants: _participants.map((p) => p.toMap()).toList(),
        );
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupId == null ? "Add Group" : "Update Group", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _groupNameController,
                    decoration: const InputDecoration(
                      labelText: "Group Name",
                      prefixIcon: Icon(Icons.group, color: Colors.teal),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Participants", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                      IconButton(
                        onPressed: _addParticipantPopup,
                        icon: const Icon(Icons.add_circle, color: Colors.teal, size: 30),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.teal),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _participants.length,
                      itemBuilder: (context, index) {
                        final p = _participants[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: p.imagePath != null ? FileImage(File(p.imagePath!)) : null,
                              child: p.imagePath == null ? const Icon(Icons.person) : null,
                            ),
                            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(p.mobile ?? ""),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => setState(() => _participants.removeAt(index)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("SAVE GROUP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
