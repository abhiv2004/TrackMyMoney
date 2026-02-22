import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/tripdetailsdatamodel.dart';
import '../../api_helper/apihelper.dart';
import '../../utils/colors.dart';
import '../../widgets/customsweetalert.dart';
import '../homescreen.dart';

class Participant {
  int? participantId;
  int tripId;
  String participantName;
  File? participantImage;
  String mobileNo;
  String email;


  Participant({
    this.participantId,
    required this.tripId,
    required this.participantName,
    this.participantImage,
    required this.mobileNo,
    required this.email,

  });
}

class AddEditTripForm extends StatefulWidget {
  final TripDetailsData? tripDetails;
  const AddEditTripForm({Key? key, this.tripDetails}) : super(key: key);

  @override
  _AddEditTripFormState createState() => _AddEditTripFormState();
}

class _AddEditTripFormState extends State<AddEditTripForm> {
  final TextEditingController _tripNameController = TextEditingController();
  List<Participant> _participants = [];
  final ImagePicker _picker = ImagePicker();
  File? _tripImage;
  Uint8List? _tripImageBytes;
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    setState(() => _isLoading = true);
    if (widget.tripDetails != null) {
      _tripNameController.text = widget.tripDetails!.trip.tripName;

      if (widget.tripDetails!.trip.tripImage != null &&
          widget.tripDetails!.trip.tripImage!.isNotEmpty) {
        try {
          _tripImageBytes = base64Decode(widget.tripDetails!.trip.tripImage!);
        } catch (e) {
          print("Error decoding trip image: $e");
        }
      }

      // Ensure participants list is not null before mapping
      _participants = (widget.tripDetails?.participants ?? []).map((participant) {
        Uint8List? participantImageBytes;

        if (participant.participantImage != null &&
            participant.participantImage!.isNotEmpty) {
          try {
            participantImageBytes = base64Decode(participant.participantImage!);
          } catch (e) {
            print("Error decoding participant image: $e");
          }
        }

        return Participant(
          participantId: participant.participantId,
          tripId: participant.tripId,
          participantName: participant.participantName,
          email: participant.email,
          mobileNo: participant.mobileNo,
          participantImage: null,
        );
      }).toList();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage(int index, {bool isTripImage = false}) async {
    PermissionStatus cameraStatus = await Permission.camera.request();
    PermissionStatus storageStatus = await Permission.photos.request();

    if (cameraStatus.isGranted && storageStatus.isGranted) {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Pick from Gallery'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    try {
                      final XFile? pickedFile =
                      await _picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setState(() {
                          if (isTripImage) {
                            _tripImage = File(pickedFile.path);
                          } else {
                            _participants[index].participantImage = File(pickedFile.path);
                          }
                        });
                      }
                    } catch (e) {
                      print("Error picking image from gallery: $e");
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take a Photo'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    try {
                      final XFile? pickedFile =
                      await _picker.pickImage(source: ImageSource.camera);
                      if (pickedFile != null) {
                        setState(() {
                          if (isTripImage) {
                            _tripImage = File(pickedFile.path);
                          } else {
                            _participants[index].participantImage = File(pickedFile.path);
                          }
                        });
                      }
                    } catch (e) {
                      print("Error taking photo: $e");
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    } else {
      if (cameraStatus.isDenied || storageStatus.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permissions denied. Please grant camera and storage permissions.")),
        );
      } else if (cameraStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
        openAppSettings();
      }
    }
  }

  void _saveTrip() async {


    if (_tripNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Trip Name cannot be empty."),
        ),
      );
      return;
    }

    if (_participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("At least one participant is required to save the trip.")),
      );
      return;
    }
    setState(() => _isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt('userId') ?? 0;
    String tripName = _tripNameController.text;
    File? tripImage = _tripImage;

    // **Insert new trip**
    int? tripId = await ApiService().insertTrip(tripName, tripImage, userId);

    if (tripId != null) {
      bool allParticipantsInserted = true;

      for (var participant in _participants) {
        bool isParticipantInserted = await ApiService().insertParticipant(
          tripId,
          participant.participantName,
          participant.email,
          participant.mobileNo,
          participant.participantImage,
        );

        if (!isParticipantInserted) {
          allParticipantsInserted = false;
          print("Failed to add participant ${participant.participantName}.");
          break;
        }
      }

      if (allParticipantsInserted) {
        showCustomSweetAlert(context, "Trip and participants added successfully!", "success", () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
        });

      } else {
        bool isTripDeleted = await ApiService().deleteTrip(tripId);
        if (isTripDeleted) {
          showCustomSweetAlert(context, "Failed to add all participants.\nTrip has been deleted.", "failure", () {});

        } else {
          showCustomSweetAlert(context, "Failed to add all participants.\nTrip deletion failed. Please check logs.", "failure", () {});
        }
      }
    } else {
      showCustomSweetAlert(context, "Failed to add trip.\nPlease try again.", "failure", () {});
    }

    setState(() => _isLoading = false);

  }
  void _saveupdateTrip() async {

    setState(() => _isLoading = true);
    if (_participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("At least one participant is required to save the trip.")),
      );
      return;
    }

    String tripName = _tripNameController.text;

    // If no new image is selected, use the existing base64 image
    String? tripImageBase64;
    if (_tripImage != null) {
      tripImageBase64 = base64Encode(_tripImage!.readAsBytesSync());
    } else if (_tripImageBytes != null) {
      tripImageBase64 = base64Encode(_tripImageBytes!);
    }

    // **Update trip**
    bool isTripUpdated = await ApiService().updateTrip(
      widget.tripDetails!.trip.tripId!,
      tripName,
      tripImageBase64, // Pass base64 string instead of File
      widget.tripDetails!.trip.userId,
    );

    if (isTripUpdated) {
      bool allParticipantsProcessed = true;

      for (var participant in _participants) {
        String? participantImageBase64;

        // Convert image to base64 if new image selected
        if (participant.participantImage != null) {
          participantImageBase64 = base64Encode(participant.participantImage!.readAsBytesSync());
        } else if (widget.tripDetails!.participants.any((p) => p.participantId == participant.participantId)) {
          // Keep the existing base64 image if no new image was selected
          participantImageBase64 = widget.tripDetails!.participants
              .firstWhere((p) => p.participantId == participant.participantId)
              .participantImage;
        }

        if (participant.participantId != null) {
          // **Update existing participant**
          bool isParticipantUpdated = await ApiService().updateParticipant(
            participant.participantId!,
            widget.tripDetails!.trip.tripId!,
            participant.participantName,
            participant.email,
            participant.mobileNo,
            participantImageBase64,
          );

          if (!isParticipantUpdated) {
            allParticipantsProcessed = false;
            print("Failed to update participant ${participant.participantName}.");
            break;
          }
        } else {
          // **Insert new participant**
          bool isParticipantInserted = await ApiService().insertParticipant(
            widget.tripDetails!.trip.tripId!,
            participant.participantName,
            participant.email,
            participant.mobileNo,
            participant.participantImage,
          );

          if (!isParticipantInserted) {
            allParticipantsProcessed = false;
            print("Failed to add participant ${participant.participantName}.");
            break;
          }
        }
      }

      if (allParticipantsProcessed) {
        showCustomSweetAlert(context, "Trip and participants updated successfully.", "success", () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update all participants. Please try again.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update trip. Please try again.")),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(
              'Plan Trip',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.teal,
            elevation: 5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _refreshPage,
              ),
            ],
          ),

          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                GestureDetector(
                    onTap: () => _pickImage(0, isTripImage: true),
                    child:CircleAvatar(
                        radius: 40,
                        backgroundImage: _tripImage != null ? FileImage(_tripImage!) : _tripImageBytes != null ? MemoryImage(_tripImageBytes!) : null,
                        child: ( _tripImage == null && _tripImageBytes == null)
                            ? const Icon(Icons.add_a_photo, size: 40,color: Colors.teal,)
                            : null
                    )

                ),

                const SizedBox(height: 20),
                TextField(
                  controller: _tripNameController,
                  decoration: _inputDecoration("Trip Name", Icons.airplane_ticket),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Participants',
                      style: TextStyle(
                        color: Colors.teal.shade800,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(onPressed: _addParticipant, icon: Icon(Icons.add_circle_rounded,color: Colors.teal,))
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: _participants.length, // Use _participants instead of widget.tripDetails!.participants
                    itemBuilder: (context, index) {
                      Uint8List? participantImageBytes;

                      // Check if the index exists in widget.tripDetails!.participants before accessing
                      if (widget.tripDetails != null &&
                          widget.tripDetails!.participants.isNotEmpty &&
                          index < widget.tripDetails!.participants.length &&
                          widget.tripDetails!.participants[index].participantImage != null &&
                          widget.tripDetails!.participants[index].participantImage!.isNotEmpty) {
                        try {
                          participantImageBytes = base64Decode(widget.tripDetails!.participants[index].participantImage!);
                        } catch (e) {
                          print("Error decoding participant image: $e");
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(color: Colors.teal, width: 1),
                          ),
                          elevation: 3,
                          child: ListTile(
                            leading: GestureDetector(
                              onTap: () => _pickImage(index),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundImage: _participants[index].participantImage != null
                                    ? FileImage(_participants[index].participantImage!)
                                    : (participantImageBytes != null ? MemoryImage(participantImageBytes) : null),
                                child: (_participants[index].participantImage == null && participantImageBytes == null)
                                    ? Icon(Icons.add_a_photo, size: 30, color: Colors.teal)
                                    : null,
                              ),
                            ),
                            title: GestureDetector(
                              onTap: () => _editParticipant(index),
                              child: Text(
                                _participants[index].participantName,
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                              ),
                            ),
                            subtitle: GestureDetector(
                              onTap: () => _editParticipant(index),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Email: ${_participants[index].email}", style: TextStyle(color: Colors.black87)),
                                  Text("Mobile: ${_participants[index].mobileNo}", style: TextStyle(color: Colors.black87)),
                                ],
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => setState(() {
                                _participants.removeAt(index);
                              }),
                            ),
                          ),
                        ),

                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: widget.tripDetails == null ? _saveTrip : _saveupdateTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 80),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Save Trip",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              ],
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

  void _addParticipant() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController mobileController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Participant'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: nameController,
                    decoration: _inputDecoration("Name", Icons.person),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name cannot be empty';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emailController,
                    decoration: _inputDecoration("Email", Icons.email),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email cannot be empty';
                      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: mobileController,
                    decoration: _inputDecoration("Mobile", Icons.phone),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Mobile number cannot be empty';
                      } else if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                        return 'Enter a valid 10-digit mobile number';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    _participants.add(
                      Participant(
                        tripId: 0,
                        participantId: null,
                        participantName: nameController.text,
                        email: emailController.text,
                        mobileNo: mobileController.text,
                        participantImage: null,
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _editParticipant(int index) {
    final TextEditingController nameController =
    TextEditingController(text: _participants[index].participantName);
    final TextEditingController emailController =
    TextEditingController(text: _participants[index].email);
    final TextEditingController mobileController =
    TextEditingController(text: _participants[index].mobileNo);
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Participant'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: nameController,
                    decoration: _inputDecoration("Name", Icons.person),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name cannot be empty';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emailController,
                    decoration: _inputDecoration("Email", Icons.email),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email cannot be empty';
                      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: mobileController,
                    decoration: _inputDecoration("Mobile", Icons.phone),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Mobile number cannot be empty';
                      } else if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                        return 'Enter a valid 10-digit mobile number';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    _participants[index] = Participant(
                      participantId: _participants[index].participantId,
                      tripId: _participants[index].tripId,
                      participantName: nameController.text,
                      email: emailController.text,
                      mobileNo: mobileController.text,
                      participantImage: _participants[index].participantImage,
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  /// Common Input Decoration
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

  void _refreshPage() {
    setState(() {
      _tripNameController.clear();
      _participants = [];
      _tripImage = null;
    });
  }
}

